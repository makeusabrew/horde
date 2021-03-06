child_process = require "child_process"
fs            = require "fs"
path          = require "path"
async         = require "async"
program       = require "commander"

Runner = require "./runners"
Buffer = require "./buffer"

XUnitReporter = require "./reporters/xunit"

# store an array of child processes
# @TODO de-globalise
procs = []

createSuites = (files, callback) ->
  return callback [] if files.length is 0

  sum = (f.testCount for f in files).reduce (a, b) -> a + b

  # ideally we'd split the number of tests precisely across our number of procs...
  target = Math.round sum / program.procs

  # ...so we want to find out the most efficient way of
  # chunking the files
  #
  # @NOTE this implementation is *awful* and entirely brute force. My lack of
  # scientific / mathematical background means I'm struggling to know what to
  # google algorithm wise, but these sound pretty close:
  # http://en.wikipedia.org/wiki/Partition_problem#The_k-partition_problem
  # https://www.google.co.uk/search?q=k+partition+problem&oq=k+partition+problem

  console.log "Fetching optimum distribution for ~#{sum} tests in #{files.length} files across #{program.procs} containers..."

  # first pass, we chunk by number of tests, highest -> lowest
  files.sort (a, b) -> return b.testCount - a.testCount
  doChunk files, target, callback

doChunk = (
  files
  target
  done
  # optional base params
  startTime     = Date.now()
  timeAllowed   = 2000
  bestDeviation = 9e6
  final         = []
) ->

  # create all the required empty chunks
  chunks = []
  for i in [0...program.procs]
    chunks.push
      files: []
      testCount: 0
      index: i+1
      results: []

  # iterate through our files dumping them evenly in our available chunks
  for file, i in files
    mod = i % program.procs
    chunks[mod].files.push file.path
    chunks[mod].testCount += file.testCount


  # work out how far away each chunk is from its target and then sum those
  # deviations
  totalDeviation = 0
  totalDeviation += Math.abs chunk.testCount - target for chunk in chunks

  # current best...
  if totalDeviation < bestDeviation
    bestDeviation = totalDeviation
    final = chunks

  # bail early if we've got no deviation (perfect) or we've taken too long
  if bestDeviation is 0 or (Date.now() - startTime) >= timeAllowed

    avgDeviation = Math.round bestDeviation / program.procs
    console.log "Best average deviation of #{avgDeviation} (total: #{bestDeviation})\n"

    return done final

  # right, try again - just order the files randomly
  files.sort -> if Math.random() >= 0.5 then -1 else 1
  return setTimeout ->
    doChunk files, target, done, startTime, timeAllowed, bestDeviation, final
  , 0

totalStats =
  start: null
  end: null
  suites: 0
  tests: 0
  passes: 0
  failures: 0
  duration: 0
  pending: 0
  secs: 0

testResults = {}

runSuites = (suites, done) ->

  # make sure we get the most accurate start time
  totalStats.start = new Date()

  async.forEach suites, runSuite, done

runSuite = (suite, done) ->

  baseArgs = "run" +
    " -v #{program.source}:/var/www" +   # mount source directory into container's /var/www
    " -v #{program.config}:/horde/conf" + # mount configuration directory
    #
    # @TODO either the boot script knows *everything* it needs to do OR nothing, not half and half
    # like this. at the moment it runs mocha but takes args externally - that's totally messed up
    #
    " #{program.image} /horde/boot --reporter json-stream"
  extraArgs    = (file for file in suite.files)
  combinedArgs = [].concat baseArgs.split(" "), extraArgs

  console.log "Spawning docker container [#{suite.index}] with approx. #{suite.testCount} tests in #{suite.files.length} files"
  cmd = child_process.spawn "docker", combinedArgs

  cmd.stdout.on "data", (d) ->
    lines = d.toString("utf8").split "\n"

    for line in lines
      status = renderLine line, suite
      if status is "end"
        cmd.stdin.end()
        done()

  cmd.stderr.on "data", (d) -> process.stderr.write d

  cmd.on "exit", (code) ->
    # ideally we'd hook into this and use it to summarise each test suite
    # but for some reason child_process + docker run + child_process is
    # somewhere along the line causing this to *never* be fired

  procs.push cmd

  if procs.length is program.procs
    # this needs to be fairly generic, but there's no reason they can't somehow
    # broadcast what they're about to start; or the runner can contain this line...
    console.log "\nPlease wait while your containers start their services..."

recentlyFinished = []
doLineSummary = (length) ->
  pc = Math.round((length / totalTests) * 100)

  pc = "~#{pc}" if pc < 100

  append = " (#{pc}%)"

  if recentlyFinished.length
    append += " (containers: #{recentlyFinished.join(", ")})"
    recentlyFinished = []

  buffer.append append

buffer = new Buffer stream: process.stdout, lineLength: 50
buffer.on "endline", doLineSummary

totalTests    = 0
startedSuites = 0
failures      = []

renderLine = (line, suite) ->
  return if line is ''

  try
    [status, details] = JSON.parse line
  catch e
    #console.log "Could not parse JSON: "+e.toString()
    #console.log line
    return

  test = {status, details}

  switch status
    when "message"
      process.stdout.write details
    when "pass"
      buffer.write "."
    when "fail"
      failures.push test
      buffer.write "F"
    when "start"
      startedSuites += 1
      totalTests += details.total

      if startedSuites is 1
        process.stdout.write "\n"

      process.stdout.write "Starting mocha test suite [#{suite.index}] with #{details.total} tests (#{totalTests})\n"

      if startedSuites is program.procs
        process.stdout.write "\n"
        buffer.flush()

    when "end"
      totalStats.suites   += details.suites
      totalStats.tests    += details.tests
      totalStats.passes   += details.passes
      totalStats.failures += details.failures
      totalStats.duration += details.duration
      totalStats.pending  += details.pending

      symbol = if details.failures is 0 then "✓" else "✗"
      buffer.write symbol

      recentlyFinished.push suite.index
    else
      console.log test

  suite.results.push test

  return status

doSummary = (suites) ->
  buffer.moveToEnd()
  doLineSummary totalTests
  process.stdout.write "\n\n#{Array(buffer.lineLength+1).join("-")}\n\n"

  totalStats.end = new Date()
  duration = totalStats.end - totalStats.start

  saving = 100 - Math.round( (duration / totalStats.duration) * 100)
  friendlySaving = "quicker"
  if saving < 0
    saving = -saving
    friendlySaving = "slower"

  secs = Math.round duration / 1000

  totalStats.secs = secs

  serialSecs = Math.round totalStats.duration / 1000

  console.log "#{program.procs} test suites run in a total of #{secs} seconds, #{saving}% #{friendlySaving} than in serial (#{serialSecs})\n"

  if failures.length
    console.log "Dumping #{failures.length} failures:"
    console.log failures

  if program.output
    flatResults = []
    flatResults = flatResults.concat suite.results for suite in suites

    console.log "Writing test results to #{program.output}"
    return writeResults flatResults, program.output, doExit

  doExit()

doExit = ->
  returnCode = if failures.length is 0 then 0 else 1
  console.log "Exiting with overall status #{returnCode}"
  Horde.stop returnCode

writeResults = (results, file, cb) ->

  reporter = new XUnitReporter

  str = reporter.formatResults results, totalStats

  fs.writeFile file, str, (err) ->
    throw err if err
    cb()

Horde =
  start: (params) ->
    program
      .option("-p, --procs <n>", "Number of containers to spawn [4]", parseInt, 4)
      .option("-o, --output [file]", "XML file to write JUnit results to")
      .option("-s, --source [dir]", "Source directory to mount [process.cwd()]")
      .option("-c, --config [dir]", "Configuration directory to mount [--source/horde]")
      .option("-i, --image [image]", "Docker image to use [makeusabrew/horde]", "makeusabrew/horde")
      .parse params

    if not program.source
      program.source = process.cwd()
      console.log "No source option supplied, using current working directory..."

    if not program.config
      configPath = path.join(program.source, "horde/conf/")

      console.log "No config option supplied, checking to see if #{configPath} exists..."

      if not fs.existsSync configPath
        console.error "Please supply a valid --config directory"
        process.exit 1

      program.config = configPath

      console.log "Using #{configPath} as config directory"

    if not fs.existsSync path.join(configPath, "apache.conf")
      console.error "Apache configuration file apache.conf not found"
      process.exit 1

    console.log "Found apache configuration file"

    # @TODO detect & support other runners
    runnerName = "mocha/coffeescript"

    console.log "Using #{runnerName} runner"

    console.log ""

    runner = Runner.factory runnerName, directory: program.source

    runner.fetchTestFiles (files) ->
      # first of all work out roughly how many tests are in each file
      runner.getTestCount files, (testFiles) ->
        # then try and split them into the best-fitting suites
        createSuites testFiles, (suites) ->
          # now run all the test suites...
          runSuites suites, ->
            # once we're all done, sum up
            doSummary suites

  stop: (code = 0) ->
    proc.kill() for proc in procs
    process.exit code

module.exports = Horde

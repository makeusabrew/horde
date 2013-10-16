child_process = require "child_process"
async         = require "async"
fs            = require "fs"

Buffer = require "./buffer"

# store an array of child processes
procs = []

# @TODO validation around user input
# might as well use commander or similar
maxProcs   = +process.argv[5]
outputFile = process.argv[4]
hostDir    = process.argv[2]
image      = process.argv[3]

suites = []

chunkTests = (files, callback) ->

  sum = (f.testCount for f in files).reduce (a, b) -> a + b

  # ideally we'd split the number of tests precisely across our number of procs...
  target = Math.round sum / maxProcs

  # ...so we want to find out the most efficient way of
  # chunking the files
  #
  # @NOTE this implementation is *awful* and entirely brute force. My lack of
  # scientific / mathematical background means I'm struggling to know what to
  # google algorithm wise, but these sound pretty close:
  # http://en.wikipedia.org/wiki/Partition_problem#The_k-partition_problem
  # https://www.google.co.uk/search?q=k+partition+problem&oq=k+partition+problem

  console.log "Attempting to fetch optimum suite distribution, please wait..."

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
  for i in [0...maxProcs]
    chunks.push
      files: []
      testCount: 0
      index: i+1
      results: []

  # iterate through our files dumping them evenly in our available chunks
  for file, i in files
    mod = i % maxProcs
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

    avgDeviation = Math.round bestDeviation / maxProcs
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

runSuites = (done) ->

  # make sure we get the most accurate start time
  totalStats.start = new Date()

  async.forEach suites, runSuite, done

runSuite = (suite, done) ->

  baseArgs     = "run -v #{hostDir}:/var/www #{image} /horde/boot.coffee --reporter json-stream".split(" ")
  extraArgs    = (file for file in suite.files)
  combinedArgs = baseArgs.concat extraArgs

  console.log "Spawning docker container [#{suite.index}] with approx. #{suite.testCount} tests in #{suite.files.length} files"
  cmd = child_process.spawn "docker", combinedArgs

  cmd.stdout.on "data", (d) ->
    #process.stdout.write d

    lines = d.toString("utf8").split "\n"
    for line in lines
      zombie = line.split "[zombie] "
      continue if zombie.length isnt 2

      json = zombie[1]

      status = renderLine json, suite
      done() if status is "end"

  cmd.stderr.on "data", (d) -> process.stderr.write d

  cmd.on "exit", (code) ->
    # ideally we'd hook into this and use it to summarise each test suite
    # but for some reason child_process + docker run + child_process is
    # somewhere along the line causing this to *never* be fired
    console.log "EXIT", code

  procs.push cmd

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

      if startedSuites is maxProcs
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

doSummary = ->
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

  console.log "#{maxProcs} test suites run in a total of #{secs} seconds, #{saving}% #{friendlySaving} than in serial (#{serialSecs})\n"

  if failures.length
    console.log "Dumping #{failures.length} failures:"
    console.log failures

  if outputFile
    flatResults = []
    flatResults = flatResults.concat suite.results for suite in suites

    console.log "Writing test results to #{outputFile}"
    writeResults flatResults, outputFile, doExit

doExit = ->
  returnCode = if failures.length is 0 then 0 else 1
  console.log "Exiting with overall status #{returnCode}"
  process.exit returnCode

writeResults = (results, file, cb) ->
  buffer = []
  buffer.push '<testsuite name="Mocha Tests" tests="'+totalStats.tests+'" failures="'+totalStats.failures+'" errors="0" skip="'+totalStats.pending+'" timestamp="'+totalStats.start.toString()+'" time="'+totalStats.secs+'">'

  for test in results
    details = test.details

    if details.fullTitle
      idx = details.fullTitle.indexOf(details.title)
      if idx isnt -1
        fullTitle = details.fullTitle.substr(0, idx-1)
      else
        fullTitle = details.fullTitle
    else
      fullTitle = ""

    if details.title
      title = details.title
    else
      title = ""

    title = title.replace /"/g, ""
    title = title.replace /&/g, "&amp;"

    fullTitle = fullTitle.replace /"/g, ""
    fullTitle = fullTitle.replace /&/g, "&amp;"

    switch test.status
      when "pass"
        buffer.push '<testcase classname="'+fullTitle+'" name="'+title+'" time="'+(details.duration / 1000)+'"/>'
      when "fail"
        buffer.push '<testcase classname="'+fullTitle+'" name="'+title+'" time="'+(details.duration / 1000)+'">'
        buffer.push '<failure classname="'+fullTitle+'" name="'+title+'" time="'+(details.duration / 1000)+'">Test Failed</failure>'
        buffer.push '</testcase>'

  buffer.push '</testsuite>'

  fs.writeFile file, buffer.join("\n"), (err) ->
    throw err if err
    cb()

getTestCount = (files, done) ->
  testFiles = []
  async.forEach files, (item, callback) ->
    fs.readFile "#{hostDir}/#{item}", (err, data) ->
      throw err if err

      # we take the number of it "...", -> expectations as a rough indicator
      # of the number of tests in this file, but it's NOT exact at all
      # particularly as the matched 'it' could be inside a comment block
      matches = data.toString().match /it ".+", ->/g

      testFiles.push
        path: item
        testCount: matches.length

      callback()
  , (err) ->
    throw err if err
    done testFiles

Horde =
  start: ->
    child_process.exec "ls -lah #{hostDir}/test/*.coffee", (err, stdout, stderr) ->
      lines = stdout.split "\n"
      files = []

      for line in lines
        # @TODO JS support
        matches = line.match /(test\/.+\.coffee$)/
        files.push matches[1] if matches

      # first of all work out roughly how many tests are in each file
      getTestCount files, (testFiles) ->
        # then try and split them into the best-fitting suites
        chunkTests testFiles, (chunks) ->
          # @TODO suites is global at the mo, ideally it wouldn't be...
          suites = chunks
          runSuites ->
            # once we're all done, sum up
            doSummary()

  stop: ->
    proc.kill() for proc in procs

module.exports = Horde

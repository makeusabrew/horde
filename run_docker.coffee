child_process = require "child_process"
async = require "async"
fs = require "fs"

procs = []
maxProcs = +process.argv[5]
outputFile = process.argv[4]
hostDir = process.argv[2]
image = process.argv[3]

lineLength = 50

child_process.exec "ls -lah #{hostDir}/test/*.coffee", (err, stdout, stderr) ->
  lines = stdout.split "\n"
  files = []

  for line in lines
    matches = line.match /(test\/.+\.coffee$)/
    files.push matches[1] if matches

  async.forEach files, getTestCount, (err) ->
    chunks = chunkTests testFiles
    runSuite chunks

chunkTests = (files) ->
  files.sort (a, b) -> return b.testCount - a.testCount
  #
  # files is now sorted from least tests to most tests
  # we need to chunk it properly now
  chunkSize = Math.ceil(files.length / maxProcs)

  chunks = []
  for i in [0...maxProcs]
    chunks.push
      files: []
      title: "batch_#{i+1}"
      cmd: null

  for file, i in files
    mod = i % maxProcs
    chunks[mod].files.push file.file

  return chunks

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

runSuite = (chunks) ->

  totalStats.start = new Date()

  baseArgs = "run -v #{hostDir}:/var/www #{image} coffee /run.coffee --reporter json-stream".split(" ")

  for chunk in chunks
    extraArgs = (file for file in chunk.files)
    combinedArgs = [].concat baseArgs, extraArgs

    #console.log "spawning docker " + combinedArgs.join(" ")
    cmd = child_process.spawn "docker", combinedArgs

    # we want to buffer our test outcomes into coherent chunks
    testResults[chunk.title] = []

    cmd.stdout.on "data", (d) ->
      #process.stdout.write d

      lines = d.toString("utf8").split "\n"
      for line in lines
        zombie = line.split "[zombie] "
        continue if zombie.length isnt 2

        json = zombie[1]

        renderLine json, testResults[chunk.title]

    cmd.stderr.on "data", (d) -> process.stderr.write d

    cmd.on "exit", (code) ->
      console.log "EXIT", code

    cmd.on "error", ->
      console.log "ERROR"

    chunk.cmd = cmd

    procs.push cmd

process.on "SIGINT", ->
  console.log "SIGINT"
  proc.kill() for proc in procs
  process.exit 0

testChars = 0
writeChar = (char) ->
  process.stdout.write char
  if testChars % lineLength is lineLength-1
    pc = Math.round((testChars / totalTests) * 100)
    process.stdout.write " (~#{pc}%) \n"

  testChars +=1

totalTests = 0

failures = []
renderLine = (line, results) ->
    return if line is ''

    try
      test = JSON.parse line
    catch e
      #console.log "Could not parse JSON: "+e.toString()
      #console.log line
      return

    title = test[1].fullTitle

    switch test[0]
      when "pass"
        writeChar "."
      when "fail"
        failures.push test
        writeChar "F"
      when "start"
        totalTests += test[1].total
        process.stdout.write "Starting mocha test suite with #{test[1].total} tests (#{totalTests})\n"
      when "end"
        totalStats.suites   += test[1].suites
        totalStats.tests    += test[1].tests
        totalStats.passes   += test[1].passes
        totalStats.failures += test[1].failures
        totalStats.duration += test[1].duration
        totalStats.pending  += test[1].pending

        symbol = if test[1].failures is 0 then "✓" else "✗"
        writeChar symbol

        finishSuite()
      else
        console.log test

    results.push test

testFiles = []
getTestCount = (item, callback) ->
  fs.readFile "#{hostDir}/#{item}", (err, data) ->
    throw err if err

    matches = data.toString().match /it ".+", ->/g

    testFiles.push {file: item, testCount: matches.length}
    callback()

doneSuites = 0
finishSuite = ->
  doneSuites += 1

  doSummary() if doneSuites is maxProcs

doSummary = ->
  process.stdout.write "\n\n---\n\n"

  totalStats.end = new Date()
  duration = totalStats.end - totalStats.start

  saving = 100 - Math.round( (duration / totalStats.duration) * 100)

  secs = Math.round duration / 1000

  totalStats.secs = secs

  serialSecs = Math.round totalStats.duration / 1000

  console.log "#{maxProcs} test suites run in a total of #{secs} seconds, #{saving}% quicker than in serial (#{serialSecs})"

  if failures.length
    console.log failures.length+" failures:"
    console.log failures

  if outputFile
    flatResults = []
    for key,data of testResults
      flatResults = flatResults.concat data

    console.log "writing test results to #{outputFile}"
    writeResults flatResults, outputFile, doExit

doExit = ->
  returnCode = 0
  console.log "Exiting with overall status #{returnCode}"
  process.exit returnCode

writeResults = (results, file, cb) ->
  buffer = []
  buffer.push '<testsuite name="Mocha Tests" tests="'+totalStats.tests+'" failures="'+totalStats.failures+'" errors="0" skip="'+totalStats.pending+'" timestamp="'+totalStats.start.toString()+'" time="'+totalStats.secs+'">'

  for test in results
    type = test[0]
    data = test[1]

    if data.fullTitle
      idx = data.fullTitle.indexOf(data.title)
      if idx isnt -1
        fullTitle = data.fullTitle.substr(0, idx-1)
      else
        fullTitle = data.fullTitle
    else
      fullTitle = ""

    if data.title
      title = data.title
    else
      title = ""

    title = title.replace /"/g, ""
    title = title.replace /&/g, "&amp;"

    fullTitle = fullTitle.replace /"/g, ""
    fullTitle = fullTitle.replace /&/g, "&amp;"

    switch type
      when "pass"
        buffer.push '<testcase classname="'+fullTitle+'" name="'+title+'" time="'+(data.duration / 1000)+'"/>'
      when "fail"
        buffer.push '<testcase classname="'+fullTitle+'" name="'+title+'" time="'+(data.duration / 1000)+'">'
        buffer.push '<failure classname="'+fullTitle+'" name="'+title+'" time="'+(data.duration / 1000)+'">Test Failed</failure>'
        buffer.push '</testcase>'

  buffer.push '</testsuite>'

  fs.writeFile file, buffer.join("\n"), (err) ->
    throw err if err
    cb()

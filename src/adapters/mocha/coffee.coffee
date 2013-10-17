child_process = require "child_process"
fs            = require "fs"
async         = require "async"

Adapter = require "../"

module.exports =
class MochaCoffeeAdapter extends Adapter

  fetchTestFiles: (done) ->
    child_process.exec "ls -lah #{@directory}/test/*.coffee", (err, stdout, stderr) ->
      lines = stdout.split "\n"
      files = []

      for line in lines
        matches = line.match /(test\/.+\.coffee$)/
        files.push matches[1] if matches

      done files

  getTestCount: (files, done) ->
    testFiles = []
    async.forEach files, (item, callback) =>
      fs.readFile "#{@directory}/#{item}", (err, data) ->
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

child_process = require "child_process"
fs            = require "fs"
async         = require "async"

Runner = require "../"

module.exports =
class MochaRunner extends Runner
  constructor: (options) ->
    super options

    @setProperties()

  setProperties: -> throw "setProperties must be implemented in descendent class"

  fetchTestFiles: (done) ->
    child_process.exec "ls -lah #{@directory}/test/*.#{@extension}", (err, stdout, stderr) =>
      lines = stdout.split "\n"
      files = []

      r = new RegExp "(test\/.+\.#{@extension})"

      for line in lines
        matches = r.exec line
        files.push matches[1] if matches

      done files

  getTestCount: (files, done) ->
    testFiles = []
    async.forEach files, (item, callback) =>
      fs.readFile "#{@directory}/#{item}", (err, data) =>
        throw err if err

        # we take the number of it "...", -> expectations as a rough indicator
        # of the number of tests in this file, but it's NOT exact at all
        # particularly as the matched 'it' could be inside a comment block
        matches = data.toString().match @testPattern

        if matches isnt null
          # we have to allow for empty / invalid files which we'll ignore
          testFiles.push
            path: item
            testCount: matches.length

        callback()
    , (err) ->
      throw err if err
      done testFiles

module.exports =
class Runner
  @factory: (name, options) ->
    runner = require "./#{name}"
    return new runner options

  constructor: (options) ->
    {@directory} = options

  fetchTestFiles: -> throw "fetchTestFiles must be implemented in descendent class"

  getTestCount: -> throw "getTestCount must be implemented in descendent class"

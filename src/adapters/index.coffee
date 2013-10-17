module.exports =
class Adapter
  @get: (adapterName, options) ->
    Adapter = require "./#{adapterName}"
    return new Adapter options

  constructor: (options) ->
    {@directory} = options

  fetchTestFiles: -> throw "fetchTestFiles must be implemented in descendent class"

  getTestCount: -> throw "getTestCount must be implemented in descendent class"

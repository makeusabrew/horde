module.exports =
class Adapter
  @get: (adapterName, options) ->
    adapter = require "./#{adapterName}"
    return new adapter options

  constructor: (options) ->
    {@directory} = options

  fetchTestFiles: -> throw "fetchTestFiles must be implemented in descendent class"

  getTestCount: -> throw "getTestCount must be implemented in descendent class"

MochaRunner = require "../mocha"

module.exports =
class MochaJSRunner extends MochaRunner

  setProperties: ->
    @extension = "js"
    @testPattern = /it\(".+", function\(\) \{/g

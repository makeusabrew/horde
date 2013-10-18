MochaAdapter = require "../mocha"

module.exports =
class MochaJSAdapter extends MochaAdapter

  setProperties: ->
    @extension = "js"
    @testPattern = /it\(".+", function\(\) \{/g

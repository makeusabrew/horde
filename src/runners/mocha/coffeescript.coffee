MochaRunner = require "../mocha"

module.exports =
class MochaCoffeeRunner extends MochaRunner

  setProperties: ->
    @extension = "coffee"
    @testPattern = /it ".+", ->/g

MochaAdapter = require "../mocha"

module.exports =
class MochaCoffeeAdapter extends MochaAdapter

  setProperties: ->
    @extension = "coffee"
    @testPattern = /it ".+", ->/g

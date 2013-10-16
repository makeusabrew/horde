EventEmitter = require("events").EventEmitter

module.exports =
class Buffer
  constructor: (options) ->
    {@stream, @lineLength} = options
    @buffered = true
    @buffer = ""
    @length = 0
    @currentPos = 0
    @emitter = new EventEmitter

  on: (event, listener) -> @emitter.on event, listener

  append: (str) ->
    @stream.write str + "\n"

  write: (str) ->
    return @buffer += str if @buffered

    @stream.write str

    @currentPos = @length % @lineLength

    if @currentPos is @lineLength-1
      @emitter.emit "endline", @length

    @length += str.length

  flush: ->
    @buffered = false
    @write @buffer
    @buffer = ""

  moveToEnd: ->
    @stream.write Array(@lineLength-@currentPos).join(" ")

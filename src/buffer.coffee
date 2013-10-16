EventEmitter = require("events").EventEmitter

module.exports =
class Buffer
  constructor: (options) ->
    {@stream, @lineLength} = options
    @buffered = true
    @buffer = ""
    @length = 0
    @emitter = new EventEmitter

  on: (event, listener) -> @emitter.on event, listener

  append: (str) ->
    @stream.write str + "\n"

  write: (str) ->
    return @buffer += str if @buffered

    @stream.write str

    if @length % @lineLength is @lineLength-1
      @emitter.emit "endline", @length

    @length += str.length

  flush: ->
    @buffered = false
    @write @buffer
    @buffer = ""

class window.Point
  constructor: (@x,@y,@z) ->

  coords: ->
    [@x, @y, @z]

  neg: ->
    new Point(-@x, -@y, @z)

  distance_to: (pt) ->
    Math.sqrt((pt.x-@x)*(pt.x-@x)+(pt.y-@y)*(pt.y-@y))

  toString: ->
    @x+":"+@y+":"+@z
class window.Color
  constructor: (@r,@g,@b,@a) ->

  data: ->
    [@r,@g,@b,@a]

  @red: ->
    new Color(1.0,0.0,0.0,1.0)

  @green: ->
    new Color(0.0,1.0,0.0,1.0)

  @blue: ->
    new Color(0.0,0.0,1.0,1.0)
class window.Camera
  constructor: ->
    @lastTime = 0

  coords: ->
    @offset.coords

  set_offset: (@offset) ->

  animate: ->
#    timeNow = new Date().getTime()
#    if (@lastTime != 0)
#      elapsed = timeNow - @lastTime
#      rads = elapsed * Math.PI / 180
#      val = (90.0 * rads) / 1000.0
#      @x = 2*Math.cos(val)
#      @y = 2*Math.sin(val)
#    else
#      @lastTime = timeNow

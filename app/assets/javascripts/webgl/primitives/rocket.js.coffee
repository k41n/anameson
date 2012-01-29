class window.Rocket extends Primitive
  constructor: (gl, points) ->
    super gl,points
    @vb.draw_style = gl.TRIANGLES

  set_speed: (@speed_x,@speed_y) ->

  set_target: (@target) ->

  set_offset: (@offset) ->

  animate: ->
    timeNow = new Date().getTime()
    if (@lastTime != 0)
      elapsed = timeNow - @lastTime
      @offset.x += (90.0 * @speed_x) / 1000.0
      @offset.y += (90.0 * @speed_y) / 1000.0
    @lastTime = timeNow
    $('#pos').html(@offset.x.toFixed(2)+':'+@offset.y.toFixed(2));

    if @target and @target.distance_to(@offset) < 0.01
      @set_speed(0,0)
      @set_target(undefined)

  direct_to: (new_offset) ->
    console.log(new_offset)
    angle = Math.atan2(new_offset.y - @offset.y ,new_offset.x - @offset.x)
    new_speed_x = 0.1 * Math.cos(angle)
    new_speed_y = 0.1 * Math.sin(angle)
    console.log(new_speed_x, new_speed_y)
    @set_speed(new_speed_x, new_speed_y)
    @set_target(new_offset)


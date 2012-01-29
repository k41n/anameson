class window.Square extends Primitive
  constructor: (gl, points) ->
    super gl,points
    @vb.draw_style = gl.TRIANGLE_STRIP

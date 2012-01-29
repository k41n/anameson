class window.Triangle extends Primitive
  constructor: (gl, points) ->
    super gl,points
    @vb.draw_style = gl.TRIANGLES
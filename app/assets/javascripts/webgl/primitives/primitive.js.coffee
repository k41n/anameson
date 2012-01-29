class window.Primitive
  set_offset: (@offset) ->

  draw: (gl_core) ->
    gl_core.draw_vb(@vb, @cb, @rotated, @offset)

  set_colors: (gl, colors) ->
    @cb = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, @cb);
    color_data = []
    for color in colors
      color_data = color_data.concat color.data()

    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(color_data), gl.STATIC_DRAW);
    @cb.itemSize = 4;
    @cb.numItems = colors.length;

  constructor: (gl,points) ->
    @vb = gl.createBuffer()
    gl.bindBuffer(gl.ARRAY_BUFFER,@vb)
    vertices = []
    for point in points
      vertices = vertices.concat point.coords()
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(vertices), gl.STATIC_DRAW)
    @vb.itemSize = 3
    @vb.numItems = points.length
    @rotated = 0
    @lastTime = 0

  animate: ->
#    timeNow = new Date().getTime()
#    if (@lastTime != 0)
#      elapsed = timeNow - @lastTime
#      @rotated += (90.0 * elapsed) / 1000.0
#    @lastTime = timeNow

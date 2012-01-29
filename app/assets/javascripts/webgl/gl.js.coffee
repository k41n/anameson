class window.Gl
  @create: (canvas) ->
    gl = new Gl(canvas)
    $('#'+canvas).bind('click',gl.mouse_click)
    $('#'+canvas).bind('mousemove',gl.mouse_move)
    return gl

  constructor: (canvas) ->
    @mvMatrix = mat4.create()
    @pMatrix = mat4.create()
    @mvMatrixStack = [];
    @gl = undefined
    @triangleVertexPositionBuffer = undefined
    @squareVertexPositionBuffer = undefined
    @shaderProgram = undefined
    @canvas = $('#'+canvas).get(0)
    @scene_objects = []
    @camera = new Camera
    @known_points = {}

  mouse_click: (e) ->
    offset = $('#main_view').offset()
    x = e.clientX - offset.left
    x -= $('#main_view').width()/2
    x = x/$('#main_view').width()*2
    y = e.clientY - offset.top
    y -= $('#main_view').height()/2
    y = - y/$('#main_view').height()*2
    clickpos = [x*3,y*3,0]
    clickpos2 = []
    invmv = mat4.create()
    mat4.inverse(gl.pMatrix,invmv)
    mat4.multiplyVec3(invmv,clickpos, clickpos2)
    clickpos3 = clickpos2
    $('#current_coords').html(clickpos3[0].toFixed(2) + " : "+clickpos3[1].toFixed(2));
    $('#speed').html(clickpos3[0].toFixed(2) + " : "+clickpos3[1].toFixed(2));
    gl.rocket.set_speed(clickpos3[0] / 10.0, clickpos3[1] / 10.0)

  mouse_move: (e) ->
    offset = $('#main_view').offset()
    x = e.clientX - offset.left
    x -= $('#main_view').width()/2
    x = x/$('#main_view').width()*2
    y = e.clientY - offset.top
    y -= $('#main_view').height()/2
    y = - y/$('#main_view').height()*2
    clickpos = [x*3,y*3,0]
    clickpos2 = []
    invmv = mat4.create()
    mat4.inverse(gl.pMatrix,invmv)
    mat4.multiplyVec3(invmv,clickpos, clickpos2)
    clickpos3 = clickpos2
    $('#under_mouse').html(clickpos3[0].toFixed(2) + " : "+clickpos3[1].toFixed(2));

  mvPushMatrix: ->
    copy = mat4.create()
    mat4.set(@mvMatrix, copy);
    @mvMatrixStack.push(copy);

  mvPopMatrix: ->
    if @mvMatrixStack.length == 0
      throw "Invalid popMatrix!"
    @mvMatrix = @mvMatrixStack.pop();

  degToRad: (degrees) ->
    degrees * Math.PI / 180

  webgl_start: ->
    @initGL(@canvas)
    @initShaders()
    @create_scene_objects()
    @gl.clearColor(0.0,0.0,0.0,1.0)
    @gl.enable(@gl.DEPTH_TEST)
    @tick()

  tick: ->
    requestAnimFrame(window.gl.tick)
    window.gl.drawScene()
    window.gl.animate()

  add_scene_object: (scene_object) ->
    @scene_objects.push(scene_object)

  create_scene_objects: ->
    for i in [1..300]
      offset_x = Math.random()*20.0-10.0
      offset_y = Math.random()*20.0-10.0
      console.log(offset_x,offset_y)
      square = new Square(@gl, [
        new Point(0.1,-0.1,-0.1),
        new Point(-0.1,-0.1,-0.1),
        new Point(0.1,0.1,-0.1),
        new Point(-0.1,0.1,-0.1)
      ])
      square.set_offset(new Point(offset_x,offset_y,-3.0))
      square.set_colors(@gl,[Color.green(),Color.green(),Color.green(), Color.green()])
      @add_scene_object(square)

    @rocket = new Rocket(@gl, [
      new Point(0.1,0.1,0.0),
      new Point(0.1,-0.1,0.0),
      new Point(-0.1,0.0,0.0)
    ])
    @rocket.set_speed(0.0,0.0)
    @rocket.set_offset(new Point(0.0,0.0,-3.0))
    @rocket.set_colors(@gl,[Color.red(),Color.green(),Color.blue()])
    @add_scene_object(@rocket)

  drawScene: ->
    @gl.viewport(0, 0, @gl.viewportWidth, @gl.viewportHeight)
    @gl.clear(@gl.COLOR_BUFFER_BIT | @gl.DEPTH_BUFFER_BIT)

    mat4.perspective(45, @gl.viewportWidth / @gl.viewportHeight, 0.1, 100.0, @pMatrix)
    mat4.identity(@mvMatrix)

    for scene_object in @scene_objects
      if (@rocket.offset.distance_to(scene_object.offset) < 4)
        scene_object.draw(this)

  set_offset: (offset) ->
    mat4.translate(@mvMatrix, offset.coords())

  apply_camera: (camera) ->
    mat4.translate(@mvMatrix, camera.offset.coords())

  animate: ->
    @camera.animate()
#    for scene_object in @scene_objects
#      scene_object.animate()
    @rocket.animate()

    for scene_object in @scene_objects
      if scene_object.offset.distance_to(@rocket.offset) < 0.2 and not (scene_object is @rocket) and typeof(@known_points[scene_object.offset.toString()]) == 'undefined'
        scene_object.set_colors(@gl,[Color.red(),Color.red(),Color.red(),Color.red()])
        $('#known_points').append("<a class='known_point' href='javascript:void(0)'>"+scene_object.offset.x.toFixed(2)+':'+scene_object.offset.y.toFixed(2)+'</a><br/>');
        object_offset = scene_object.offset
        $('#known_points > a:last-of-type').bind('click',->
          console.log('directing to ' + object_offset.toString())
          gl.rocket.direct_to(object_offset)
        )
        @known_points[scene_object.offset.toString()] = scene_object

  draw_vb: (vb, cb, rotated, offset) ->
    @mvPushMatrix();
    @camera.set_offset(@rocket.offset.neg())
    @apply_camera(@camera)
    @set_offset(offset);
#    mat4.rotate(@mvMatrix, @degToRad(rotated), [0, 1, 0]);
    @gl.bindBuffer(@gl.ARRAY_BUFFER, vb)
    @gl.vertexAttribPointer(@shaderProgram.vertexPositionAttribute, vb.itemSize, @gl.FLOAT, false, 0, 0)
    @gl.bindBuffer(@gl.ARRAY_BUFFER, cb);
    @gl.vertexAttribPointer(@shaderProgram.vertexColorAttribute, cb.itemSize, @gl.FLOAT, false, 0, 0);
    @setMatrixUniforms()
    @gl.drawArrays(vb.draw_style, 0, vb.numItems)
    @mvPopMatrix();

  initGL: (canvas) ->
    try
      @gl = WebGLDebugUtils.makeDebugContext(canvas.getContext("experimental-webgl"));
      @gl.viewportWidth = canvas.width
      @gl.viewportHeight = canvas.height
    alert("Could not initialise WebGL, sorry :-(") unless @gl

  setMatrixUniforms: ->
    @gl.uniformMatrix4fv @shaderProgram.pMatrixUniform, false, @pMatrix
    @gl.uniformMatrix4fv @shaderProgram.mvMatrixUniform, false, @mvMatrix

  initShaders: ->
    fragmentShader = @getShader(@gl, "shader-fs")
    vertexShader = @getShader(@gl, "shader-vs")
    @shaderProgram = @gl.createProgram()
    @gl.attachShader @shaderProgram, vertexShader
    @gl.attachShader @shaderProgram, fragmentShader
    @gl.linkProgram @shaderProgram
    alert "Could not initialise shaders"  unless @gl.getProgramParameter(@shaderProgram, @gl.LINK_STATUS)
    @gl.useProgram @shaderProgram
    @shaderProgram.vertexPositionAttribute = @gl.getAttribLocation(@shaderProgram, "aVertexPosition")
    @gl.enableVertexAttribArray @shaderProgram.vertexPositionAttribute
    @shaderProgram.vertexColorAttribute = @gl.getAttribLocation(@shaderProgram, "aVertexColor");
    @gl.enableVertexAttribArray(@shaderProgram.vertexColorAttribute);
    @shaderProgram.pMatrixUniform = @gl.getUniformLocation(@shaderProgram, "uPMatrix")
    @shaderProgram.mvMatrixUniform = @gl.getUniformLocation(@shaderProgram, "uMVMatrix")

  getShader: (gl, id) ->
    shaderScript = $('#'+id)
    source = shaderScript.text()
    shader = undefined
    if shaderScript.attr('type') is "x-shader/x-fragment"
      shader = gl.createShader(gl.FRAGMENT_SHADER)
    else if shaderScript.attr('type') is "x-shader/x-vertex"
      shader = gl.createShader(gl.VERTEX_SHADER)
    else
      return null
    gl.shaderSource shader, source
    gl.compileShader shader
    unless gl.getShaderParameter(shader, gl.COMPILE_STATUS)
      alert gl.getShaderInfoLog(shader)
      return null
    shader
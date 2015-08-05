window.THREE = require "three"
createGeometry = require 'three-bmfont-text'
assert = require "assert"

Shader = require "./shaders/sdf"

module.exports = class Main
  scaleText: 0.005
  speedMultiplier: 0.1
  #speedMultiplier: 0.09

  CAMERA_Z = -9

  parentObject: ->
      @scene.getObjectByName "parent"

  constructor: ->
    console.log "Starting Vis"

    @renderer = new THREE.WebGLRenderer()
    @renderer.setPixelRatio( window.devicePixelRatio )
    @renderer.setSize( window.innerWidth, window.innerHeight )
    @renderer.setClearColor( "rgb(255, 255, 255)" )

    document.body.appendChild( @renderer.domElement )

    @scene = new THREE.Scene()

    parentObject = new THREE.Object3D()
    parentObject.scale.multiplyScalar(@scaleText)
    parentObject.name = "parent"
    @scene.add parentObject

    fov = 70
    aspect = window.innerWidth / window.innerHeight
    [ near, far ] = [ 0.1, 1000 ]
    @camera = new THREE.PerspectiveCamera( fov, aspect, near, far )

    [_x, _y, _z] = [0, 0, CAMERA_Z]
    @camera.position.z = _z
    @camera.position.x = _x
    @camera.position.y = _y
    @camera.lookAt new THREE.Vector3(_x,_y,0)

    onWindowResize = =>
      @camera.aspect = window.innerWidth / window.innerHeight
      @camera.updateProjectionMatrix()
      @renderer.setSize( window.innerWidth, window.innerHeight )

    window.addEventListener( 'resize', onWindowResize, false )

    @loadVisClasses()

    do animate = =>
      requestAnimationFrame animate
      @renderer.render @scene, @camera

  loadVisClasses: ->
    @visClass =
      "ChainVis": require "./ChainVis"
      "LinesVis": require "./LinesVis"
      "ColocationVis": require "./ColocationVis"
      "HoweVis": require "./HoweVis"
      "IntroVis": require "./IntroVis"

  getVisType: (className) ->
    if ! @[className]?
      @[className] = new @visClass[className](@scene, @camera, @font, @texture)
    return @[className]

  startVis: (visClass, data) ->
    if ! @[visClass]?
      Class = require "./#{visClass}"
      @[visClass] = new Class @scene, @camera, @font, @texture
    @[visClass].start data

  setTexture: (@texture) ->
    maxAni = @renderer.getMaxAnisotropy()

    @texture.needsUpdate = true
    @texture.minFilter = THREE.LinearMipMapLinearFilter
    @texture.magFilter = THREE.LinearFilter
    @texture.generateMipmaps = true
    @texture.anisotropy = maxAni

  setFont: (@font) ->

  getTextGeometry: (text) =>
    createGeometry
      text: text
      font: @font

  getTextMesh: (geometry) ->
    material = new THREE.ShaderMaterial(Shader({
      map: @texture,
      smooth: 1/8,
      side: THREE.DoubleSide,
      transparent: true,
      opacity: 0,
      color: 'rgb(10, 10, 10)'
    }))
    mesh = new THREE.Mesh(geometry, material)
    mesh

  getMeshFromString: (string) =>
    string_geom = @getTextGeometry string
    string_mesh = @getTextMesh string_geom
    string_mesh.scale.multiplyScalar(-1)
    string_mesh

  getLineObject: (line) =>
    line_geometry = @getTextGeometry line
    line_layout = line_geometry.layout
    glyph_positions = line_layout.glyphs.map (g) -> g.position

    letterObjects = line.split("").map (letter, index) =>

      if ! glyph_positions[index]
        console.error "no glyph for #{letter}"

      letter_mesh = @getMeshFromString letter

      if glyph_positions[index]
        letter_mesh.position.x = - glyph_positions[index][0]
      else
        letter_mesh.position.x = 0

      letter_mesh._letter = letter
      letter_mesh

    # TODO: Pack up words?

    lineObject = new THREE.Object3D()
    lineObject.add.apply lineObject, letterObjects
    lineObject._line = line
    lineObject._layout = line_layout
    lineObject._letters = ->
      this.children.map (d) -> d._letter
    lineObject

  getSiblingsFromSubset: (parent, array) ->
    return parent.children.filter (child) ->
      return array.indexOf(child) < 0

  getObjectFromSubset: (parent, array) ->
    subset = parent.children
      .filter (child) ->
        array.indexOf(child) > -1
      .map (child) ->
        child.clone()

    clone = parent.clone()
    clone.children = subset
    return clone

  getBBoxFromSubset: (parent, array) ->
    subset = parent.children
      .filter (child) ->
        array.indexOf(child) > -1
      .map (child) ->
        child.clone()

    clone = parent.clone()
    clone.children = subset
    box = getBBox clone

    return box

  getBBox = (object) ->
    bbox = new THREE.BoundingBoxHelper( object )
    do bbox.update
    return bbox.box
  getBBox: getBBox

  ###########################################################################
  ###########################################################################
  # ACTIONS

  panCameraToPosition3: (target, duration, ignoreGlobal) =>
    z_offset = if ignoreGlobal? then 0 else CAMERA_Z
    dur = (duration || 1000) * @speedMultiplier
    new Promise (resolve) =>
      d3.transition()
        .duration dur
        .tween "moveCamera", =>
          current = @camera.position
          x = d3.interpolate(current.x, target.x)
          y = d3.interpolate(current.y, target.y)
          z = d3.interpolate current.z, target.z + z_offset
          (t) =>
            @camera.position.x = x(t)
            @camera.position.y = y(t)
            @camera.position.z = z(t)
        .each "end", resolve

  panCameraToObject: (object, duration) =>
    box = getBBox object
    @panCameraToBBox box, duration

  panCameraToBBox: (box, duration) =>
    @panCameraToPosition3 box.center(), duration

  adjustCamera: (chainObject) =>
    bbox = @getBBox chainObject
    x = bbox.center().x
    y = bbox.center().y
    z = bbox.center().z + @getZoomDistanceFromBox bbox, 1.3
    @panCameraToPosition3 new THREE.Vector3(x,y,z), 1000, true

  adjustCameraWidth: (chainObject) =>
    bbox = @getBBox chainObject
    x = bbox.center().x
    y = bbox.center().y
    z = bbox.center().z + @getZoomDistanceFromBoxWidth bbox, 1.3
    @panCameraToPosition3 new THREE.Vector3(x,y,z), 1000, true

  wait: (duration) =>
    return new Promise (resolve) =>
      func = () -> resolve()
      dur = duration * @speedMultiplier
      setTimeout(func, dur)

  zoomCameraToPosition: (target, duration) =>
    new Promise (resolve) =>
      d3.transition()
        .duration duration * @speedMultiplier
        .tween "zoomCamera", =>
          current = @camera.position
          z = d3.interpolate current.z, target.z
          (t) =>
            @camera.position.z = z(t)
        .each "end", resolve

  addFadeOpacityTransition: (to, duration, target) ->
    (selection) =>
      selection.transition()
        .duration duration * @speedMultiplier
        .delay (_, i) =>
          del = i * 10 * @speedMultiplier
          return del
        .tween "fadeOpacity", ->
          # if target? then debugger
          obj = target || this
          from = obj.material.uniforms.opacity.value
          i = d3.interpolate from, to
          (t) ->
            obj.material.uniforms.opacity.value = i(t)

  fadeToArray: (to, duration) ->
    (array) =>
      new Promise (resolve) =>
        selection = d3.selectAll array
        @addFadeOpacityTransition(to, duration)(selection)
          .each "end", resolve

  fadeAll: (objects, to, duration) ->
      promises = objects.map (child) =>
          return @fadeToArray(to, duration) child.children
      return Promise.all promises

  _radianScale = d3.scale.linear()
      .domain([0, 360])
      .range([0, Math.PI * 2])

  getZoomDistanceFromBoxWidth: (box, distance_scale) ->
    # See: stackoverflow.com/questions/2866350/move-camera-to-fit-3d-scene
    width = Math.abs(box.min.x - box.max.x)

    # Calculate horizontal field of view
    # See: github.com/mrdoob/three.js/issues/1239
    v_fov = _radianScale @camera.fov
    h_fov = Math.atan( Math.tan(v_fov/2) * @camera.aspect )

    return -(width / 2) / Math.tan(h_fov) * distance_scale

  getZoomDistanceFromBox: (box, distance_scale) ->

    # See: stackoverflow.com/questions/2866350/move-camera-to-fit-3d-scene
    width = Math.abs(box.min.x - box.max.x)
    height = Math.abs(box.min.y - box.max.y)

    # Calculate horizontal field of view
    # See: github.com/mrdoob/three.js/issues/1239
    v_fov = _radianScale @camera.fov
    h_fov = Math.atan( Math.tan(v_fov/2) * @camera.aspect )

    if width > height
      return -(width / 2) / Math.tan(h_fov) * distance_scale
    else
      return -(height / 2) / Math.tan(h_fov) * distance_scale

  getWordIndex = (line, word) ->
    expression = if word is "—" then word else "\\b#{word}\\b"
    regex = new RegExp expression, "i"
    assert line, "#{line}"
    line.search regex

  getWordIndex: getWordIndex

  mergeChildren: (existing, add_object) ->
    existing_word = existing._letters().join("")
    add_line = add_object._letters().join("")
    start = getWordIndex add_line, existing_word
    end = start + existing_word.length
    first = add_object.children.slice 0, start
    middle = existing.children.slice()
    last = add_object.children.slice end
    # existing.children = first.concat(middle, last)
    # return existing
    return first.concat(middle, last)

  alignObjectsByWord: (existing, other, word) ->
    other.position.copy existing.position
    offset = [existing, other]
      .map (each) ->
        idx = getWordIndex each._letters().join(""), word
        return each.children[idx].position.x
      .reduce (a, b) -> a - b
    other.position.x += offset

  getLetterObjectsForWord: (text_object, word, accessor) ->
    line = if accessor? then accessor text_object else text_object._line
    # debugger if typeof line isnt "string"
    begin = getWordIndex line, word
    end = begin + word.length
    # console.log begin, end
    text_object.children.slice begin, end

module.exports = Main

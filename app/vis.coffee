window.THREE = require("three")
createGeometry = require('three-bmfont-text')
Shader = require "./shaders/sdf"
xtend = require 'xtend'
createOrbitViewer = require('three-orbit-viewer')(THREE)
assert = require "assert"

module.exports = class Main
    SCALE_TEXT = 0.005

    SPEED_MULTIPLIER = 0.5

    CAMERA_PAN_DURATION = 2000 * SPEED_MULTIPLIER
    FADE_DURATION = 3000 * SPEED_MULTIPLIER
    CHAIN_FADE_DELAY = 5000 * SPEED_MULTIPLIER

    constructor: ->
        console.log "Starting Vis"

        @renderer = new THREE.WebGLRenderer()
        @renderer.setPixelRatio( window.devicePixelRatio )
        @renderer.setSize( window.innerWidth, window.innerHeight )
        @renderer.setClearColor( "rgb(255, 255, 255)" )

        document.body.appendChild( @renderer.domElement )

        @scene = new THREE.Scene()

        fov = 70
        aspect = window.innerWidth / window.innerHeight
        [ near, far ] = [ 0.1, 1000 ]
        @camera = new THREE.PerspectiveCamera( fov, aspect, near, far )

        [_x, _y, _z] = [0, 0, -9]
        @camera.position.z = _z
        @camera.position.x = _x
        @camera.position.y = _y
        @camera.lookAt new THREE.Vector3(_x,_y,0)

        do animate = =>
            requestAnimationFrame animate
            @renderer.render @scene, @camera

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
            letter_mesh = @getMeshFromString letter
            letter_mesh.position.x = - glyph_positions[index][0]
            letter_mesh

        # TODO: Pack up words...

        lineObject = new THREE.Object3D()
        lineObject.add.apply lineObject, letterObjects
        lineObject._line = line
        lineObject._layout = line_layout
        lineObject

    processChain = (chain) ->
        chain.map (obj, i, array) ->
            obj.connector_index = obj.line.indexOf obj.connector
            if i > 0
                prev = array[i-1]
                prev_con = prev.connector
                my_prev_idx = obj.line.indexOf prev_con
                prev_idx = prev.connector_index
                obj.prev_connector = prev_con
                obj.my_prev_connector_index = my_prev_idx
                obj.prev_connector_index = prev_idx
            obj

    positionLines = (line, index, array) =>
        return line if index is 0

        prev = array[index - 1]
        prev_connector_idx = prev._line.connector_index
        my_prev_connector_idx = line._line.my_prev_connector_index

        line.position.x = prev.position.x
        line.position.x += prev.children[prev_connector_idx].position.x
        line.position.x -= line.children[my_prev_connector_idx].position.x
        line

    addChain: (text) =>
        lineObjects = processChain(text)
            .map (line, index) =>
                lineObject = @getLineObject(line.line, index)
                height = lineObject._layout.height
                lineObject.position.y = - (index) * (height + 20)
                lineObject._line = line
                lineObject
            .map positionLines

        chainObject = new THREE.Object3D()
        chainObject.add.apply(chainObject, lineObjects)
        chainObject.scale.multiplyScalar(SCALE_TEXT)
        @scene.add(chainObject)

        _pan = @panCameraTo

        d3.selectAll(lineObjects).transition()
            .duration FADE_DURATION
            .delay (_,i) -> i * CHAIN_FADE_DELAY
            .ease "poly", 5
            .tween "fadeOpacity", ->
                i = d3.interpolate(0,0.5)
                (t) -> this.children.forEach (mesh) ->
                    mesh.material.uniforms.opacity.value = i(t)
            .each "end", ->
                _pan(this)

    getRadians = (a, b) ->
        dx = a.position.x - b.position.x
        dy = a.position.y - b.position.y
        Math.atan2(dy, dx)

    makeTree = (network) =>
        network = network.map (d) ->
            val: d.word
            children: d.colocations

        _makeTree = (child, parent, index, array) ->
            child.parent = parent

            # Find the index of this child in the parent's children array
            child_index = parent.children
                .map (d) -> d.val
                .indexOf child.val

            # Set the child's "amount" to match the parent's child object
            parents_child = parent.children[child_index]
            child.amt = parents_child.amt

            # Set the parent's reference to match the child object
            parent.children[child_index] = child

            return parent

        network.reduceRight(_makeTree)

    setNetworkPositions = (root, radius) =>
        root.position = new THREE.Vector3()

        radianScale = d3.scale.ordinal()
            .rangePoints [0, 2 * Math.PI]

        traverse = (node) ->
            return if ! node.children?
            offset = if node.parent? then getRadians(node.parent, node) else 0

            circle_nodes = if node.parent?
                [node.parent].concat(node.children)
            else node.children

            radianScale.domain d3.range(circle_nodes.length + 1)

            circle_nodes.forEach (circle_node, index) ->
                radians = radianScale(index) + offset
                pos = new THREE.Vector3(
                    radius * Math.cos(radians) + node.position.x,
                    radius * Math.sin(radians) + node.position.y
                )
                if circle_node.position?
                    # check = pos.y.toFixed(3) is circle_node.position.y.toFixed(3)
                    # assert(check)
                else
                    circle_node.position = pos

            if node.children?
                node.children.forEach traverse

        traverse(root)
        return root

    panCameraToPosition: (target, duration) =>
        new Promise (resolve) =>
            d3.transition()
                .duration duration
                .tween "moveCamera", =>
                    current = @camera.position
                    x = d3.interpolate(current.x, target.x)
                    y = d3.interpolate(current.y, target.y)
                    (t) =>
                        @camera.position.x = x(t)
                        @camera.position.y = y(t)
                .each "end", resolve

    panCameraToBBox: (object, duration) =>
        bbox = new THREE.BoundingBoxHelper( object, 0xff0000 )
        do bbox.update
        @panCameraToPosition bbox.box.center(), 1000

    zoomCameraToPosition: (target, duration) =>
        new Promise (resolve) =>
            d3.transition()
                .duration duration
                .tween "zoomCamera", =>
                    current = @camera.position
                    z = d3.interpolate current.z, target.z
                    (t) =>
                        @camera.position.z = z(t)
                .each "end", resolve

    panCameraTo: (object) =>
        new Promise (resolve) =>
            d3.transition().duration(CAMERA_PAN_DURATION)
                .tween "moveCamera", =>
                    current = @camera.position
                    target = object.position
                    # FIXME: This text scaling is ugly
                    x = d3.interpolate(current.x, target.x * SCALE_TEXT)
                    y = d3.interpolate(current.y, target.y * SCALE_TEXT)
                    (t) =>
                        @camera.position.x = x(t)
                        @camera.position.y = y(t)
                .each "end", resolve

    getFadePromise = (interpolator, duration) ->
        (text_object) ->
            new Promise (resolve) ->
                d3.select(text_object).transition()
                    .duration duration or FADE_DURATION
                    # .ease "poly", 5
                    .tween "fadeOpacity", ->
                        i = interpolator
                        (t) -> this.children.forEach (mesh) ->
                            mesh.material.uniforms.opacity.value = i(t)
                    .each "end", resolve

    addFadeOpacityTransition = (to, duration, target) ->
        (selection) ->
            selection.transition()
                .duration duration
                .delay (_, i) -> i * 10
                .tween "fadeOpacity", ->
                    # if target? then debugger
                    obj = target || this
                    from = obj.material.uniforms.opacity.value
                    i = d3.interpolate from, to
                    (t) ->
                        obj.material.uniforms.opacity.value = i(t)

    fadeToArray = (to, duration) ->
        (array) ->
            new Promise (resolve) ->
                selection = d3.selectAll array
                addFadeOpacityTransition(to, 1000)(selection)
                    .each "end", resolve

    getFadeLettersPromise = (to, duration) ->
        (text_object) ->
            new Promise (resolve) ->
                d3.selectAll(text_object.children)
                    .transition()
                    .duration duration
                    .tween "fadeOpacity", fadeOpacityTween(to)
                    .each "end", resolve


    fade = (from, to, duration) ->
        (text_object) ->
            i = d3.interpolate from, to
            getFadePromise(i, duration)(text_object)

    fadeTo = (to, duration) ->
        (text_object) ->
            current = if text_object.children[0]?
                text_object.children[0].material.uniforms.opacity.value
            else 0
            i = d3.interpolate current, to
            getFadePromise(i, duration) text_object

    fadeOut = (text_object) ->
        i = d3.interpolate(0.5, 0)
        getFadePromise(i)(text_object)

    fadeIn = (text_object) ->
        i = d3.interpolate(0, 0.5)
        getFadePromise(i)(text_object)

    setTextObject: (node) =>
        text_object = @getLineObject(node.val)
        text_object.children.forEach (mesh) ->
            mesh.material.uniforms.opacity.value = 0
        text_object.position.copy(node.position)
        node._text_object = text_object
        node

    addNetwork: (network) =>
        network_object = new THREE.Object3D()
        network_object.scale.multiplyScalar(SCALE_TEXT)
        @scene.add network_object

        radius = 500

        root = makeTree network
        root = setNetworkPositions root, radius

        traverse = (node) =>
            return if ! node.position?

            node = @setTextObject(node)
            text_object = node._text_object
            network_object.add text_object

            faded_in = fadeIn(text_object)

            if node.children
                faded_in.then =>
                    @panCameraTo(text_object)
                .then ->
                    if node.parent?
                        siblings = node.parent.children.filter (child) ->
                            return child._text_object isnt text_object
                        if node.parent.parent
                            siblings = siblings.concat(node.parent.parent)
                        promises = siblings.map (sibling) ->
                            fadeOut sibling._text_object
                        return Promise.all promises
                .then ->
                    node.children.forEach traverse

        traverse(root)

    linesToTree = (lines) ->
        lines = lines.map (line) ->
            line: line.line
            word: line.word
            children: line.lines.map (_) -> line: _

        reducer = (prev, current, index, array) ->
            prev_index = current.children
                .map (_) -> _.line
                .indexOf(prev.line)
            current.children[prev_index] = prev
            prev._parent = current
            current

        lines.reduceRight reducer

    _radianScale = d3.scale.linear()
        .domain([0, 360])
        .range([0, Math.PI * 2])

    zoomToBoundingBoxWidth: (box, duration) ->
        width = Math.abs(box.min.x - box.max.x)

        distance_scale = 1.2

        v_fov = _radianScale @camera.fov

        # See: github.com/mrdoob/three.js/issues/1239
        h_fov = Math.atan( Math.tan(v_fov/2) * @camera.aspect )

        # See: stackoverflow.com/questions/2866350/move-camera-to-fit-3d-scene
        distance = (width / 2) / Math.tan(h_fov) * distance_scale

        target = new THREE.Vector3(0, 0, - distance)

        @zoomCameraToPosition target, duration

    LINE_SPACING = 40

    getWordIndex = (line, word) ->
        expression = if word is "—" then word else "\\b#{word}\\b"
        regex = new RegExp expression, "i"
        line.search regex

    alignToNode = (parent) ->
        (child) ->
            parent_x = parent._text_object.position.x
            word = parent.word
            # regex = new RegExp("\\b#{word}\\b", "i")
            offset = [ parent, child ]
                .map (_) ->
                    # idx = _.line.search regex
                    idx = getWordIndex _.line, word
                    assert idx isnt -1, "#{_.line}, #{word}"
                    _._text_object.children[idx].position.x
                .reduce (a, b) -> a - b
            child._text_object.position.x = parent_x + offset

    addObjects: (lines_object) =>
        (root) =>
            traverse = (node) =>
                debugger if ! node.line?
                node._text_object = @getLineObject(node.line)
                # node._text_object.children.forEach (mesh) ->
                #     mesh.material.uniforms.opacity.value = 0
                lines_object.add node._text_object

                node.children.forEach traverse if node.children

            traverse(root)

    getWordObjects: (text_object, word) ->
        word_object = new THREE.Object3D()
        begin = getWordIndex text_object._line, word
        end = begin + word.length
        text_object.children.slice begin, end

    chainedFadeIn: (array, duration) ->
        reduction = (promise, curr, index, array) ->
            promise.then ->
                # debugger
                fadeToArray(1, 1000) curr._text_object.children
            # addFadeOpacityTransition(1, 1000, curr._text_object)(prev)
            # prev.transition()
            #     .call (t) ->
            #         d3.select curr._text_object
                # .duration duration
                # # .tween "fadeOpacity", fadeOpacityTween(1, curr._text_object)
                # .tween "fadeOpacity", ->
                #     obj = curr._text_object
                #     from = obj.material.uniforms.opacity.value
                #     i = d3.interpolate from, to
                #     (t) ->
                #         obj.material.uniforms.opacity.value = i(t)
        # transition = array.reduce reduction, d3.transition().duration(0)
        promise = array.reduce reduction, Promise.resolve()

    animateLines: (root) =>

        fadeToArray(1, 1000) root._text_object.children
        @panCameraToBBox root._text_object
            .then -> traverse root

        traverse = (node) =>
            return if ! node.children?

            next_child = node.children.filter((_) -> _.children?)[0]

            # Start promise chain
            Promise.resolve()
                .then =>
                    # Fade out siblings
                    if node._parent?
                        siblings = node._parent.children
                            .filter (child) -> child isnt node
                        parent = node._parent
                        promises = siblings.concat(parent).map (child) ->
                                fadeToArray(0, 1000) child._text_object.children
                        return Promise.all promises
                    return true
                .then =>
                    # Fade in children
                    if node.children?
                        promises = node.children.map (child) =>
                            # Get the array of letters for the target word only
                            children = @getWordObjects child._text_object, node.word
                            fadeToArray(1, 1000) children
                        return Promise.all promises
                .then =>
                    if next_child?
                        pos = node._positions_array
                        curr = pos.indexOf(node) + 1
                        next = pos.indexOf(next_child) + 1
                        if curr < next
                            fade_array = pos.slice curr, next
                        else
                            fade_array = pos.slice(next, curr).reverse()
                        @chainedFadeIn fade_array, 1000
                .then =>
                    if next_child?
                        fadeToArray(1, 1000) next_child._text_object.children
                        @panCameraToBBox next_child._text_object
                .then ->
                    traverse next_child unless ! next_child?


    addLines: (lines) =>
        lines_object = new THREE.Object3D()
        lines_object.scale.multiplyScalar(SCALE_TEXT)
        lines_object.updateMatrixWorld(true)
        @scene.add lines_object

        root = linesToTree lines

        @addObjects(lines_object)(root)

        traverse = (parent) =>
            return if ! parent.children?

            positions_array = d3.shuffle parent.children.concat parent
            parent_index = positions_array.indexOf parent
            parent_y = parent._text_object.position.y

            parent._positions_array = positions_array

            positions_array.forEach (node, index) =>
                offset_from_parent = index - parent_index
                obj = node._text_object
                line_height = obj._layout.height + LINE_SPACING
                obj.position.y = parent_y + offset_from_parent * line_height

            parent.children.forEach alignToNode(parent)
            parent.children.forEach traverse

        traverse root

        @animateLines root

    newTest: -> new Test(@scene, @camera)

class Test extends Main
    constructor: (@scene, @camera) ->

    foo: ->
        console.log @camera.position

# .transition()
# .duration duration
# .delay (_, i) -> i * 10
# # .tween "fadeOpacity", ->
# #     fadeOpacityTween.bind(this)(1)
# .tween "fadeOpacity", ->
#     from = this.material.uniforms.opacity.value
#     i = d3.interpolate from, to
#     (t) ->
#         this.material.uniforms.opacity.value = i(t)
# .each "end", resolve

# fadeOpacityTween = (to, obj) ->
#     from = this.material.uniforms.opacity.value
#     i = d3.interpolate from, to
#     (t) ->
#         this.material.uniforms.opacity.value = i(t)

# addBBox = (node) =>
#     bbox = new THREE.BoundingBoxHelper( node._text_object, 0xff0000 )
#     do bbox.update
#     @scene.add bbox
#     if node.children
#         node.children.forEach addBBox
# addBBox root

# module.exports = Main

# bbox = new THREE.BoundingBoxHelper( root._text_object, 0xff0000 )
# do bbox.update
#
# @scene.add bbox

# bbox = new THREE.BoundingBoxHelper( root._text_object, 0xff0000 )
# do bbox.update
#
# @scene.add bbox
#
# @panCameraToPosition bbox.box.center(), 1000
#     .then => @zoomToBoundingBoxWidth(bbox.box, 1000)

# app = createOrbitViewer({
#     clearColor: 'rgb(255, 255, 255)',
#     clearAlpha: 1.0,
#     fov: 55,
#     position: new THREE.Vector3(0, -4, -5)
# })
# @renderer = app.renderer
# @scene = app.scene

# axis_helper = new THREE.AxisHelper(50)
# @scene.add( axis_helper )
#
# grid_helper = new THREE.GridHelper(20, 1)
# grid_helper.rotateX(Math.PI / 2)
# @scene.add grid_helper

# grid_helper_y = new THREE.GridHelper(20, 1)
# @scene.add grid_helper_y

# geometry = new THREE.BoxGeometry( 10, 10, 10, 2, 2, 2 );
# object = new THREE.Mesh( geometry );

# edges = new THREE.EdgesHelper( object, 0x00ff00 );
# @scene.add( edges );

# d3.transition().duration(0)
#     .transition().duration(1e3)
#     .tween "fadeLine", ->
#         return (t) -> console.log(t)
#     .each "end", -> console.log "end one"
#     .transition().duration(1e3)
#     .tween "fadeLine", ->
#         return (t) -> console.log(t)
#     .each "end", -> console.log "end two"
#     .transition().duration(1e3)
#     .tween "fadeLine", ->
#         return (t) -> console.log(t)
#     .each "end", -> console.log "end three"

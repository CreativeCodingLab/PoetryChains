window.THREE = require("three")
createGeometry = require('three-bmfont-text')
Shader = require "./shaders/sdf"
xtend = require 'xtend'
createOrbitViewer = require('three-orbit-viewer')(THREE)
assert = require "assert"

class Main
    SCALE_TEXT = 0.005
    RADIUS = 400

    constructor: ->
        console.log "Starting Vis"

        @renderer = new THREE.WebGLRenderer()
        @renderer.setPixelRatio( window.devicePixelRatio )
        @renderer.setSize( window.innerWidth, window.innerHeight )
        @renderer.setClearColor( "#eeeeee" )

        app = createOrbitViewer({
            clearColor: 'rgb(255, 255, 255)',
            clearAlpha: 1.0,
            fov: 55,
            position: new THREE.Vector3(0, -4, -5)
        })
        @renderer = app.renderer

        @scene = app.scene
        # @scene = new THREE.Scene()

        document.body.appendChild( @renderer.domElement )

        @camera = new THREE.PerspectiveCamera( 70, window.innerWidth / window.innerHeight, 1, 1000 )
        _x = 0
        _y = 0
        @camera.position.z = -10
        @camera.position.x = _x
        @camera.position.y = _y
        @camera.lookAt new THREE.Vector3(_x,_y,0)

        light = new THREE.PointLight()
        light.position.set( 200, 100, 150 )
        @scene.add( light )

        axis_helper = new THREE.AxisHelper(50)
        @scene.add( axis_helper )

        grid_helper = new THREE.GridHelper(20, 1)
        grid_helper.rotateX(Math.PI / 2)
        @scene.add grid_helper

        # grid_helper_y = new THREE.GridHelper(20, 1)
        # @scene.add grid_helper_y

        # geometry = new THREE.BoxGeometry( 10, 10, 10, 2, 2, 2 );
        # object = new THREE.Mesh( geometry );

        # edges = new THREE.EdgesHelper( object, 0x00ff00 );
        # @scene.add( edges );

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
            smooth: 1/8, # Note: This is related to camera distance... Somehow
            side: THREE.DoubleSide,
            transparent: true,
            opacity: 0,
            color: 'rgb(10, 10, 10)'
        }))
        mesh = new THREE.Mesh(geometry, material)
        mesh

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

    getMeshFromString: (string) =>
        string_geom = @getTextGeometry(string)
        string_mesh = @getTextMesh(string_geom)
        string_mesh.scale.multiplyScalar(-1)
        string_mesh

    getLineObject: (_line, index) =>
        line_geometry = @getTextGeometry _line
        line_layout = line_geometry.layout
        glyph_positions = line_layout.glyphs.map (g) -> g.position

        letterObjects = _line.split("").map (letter, index) =>
            letter_mesh = @getMeshFromString(letter)
            letter_mesh.position.x = - glyph_positions[index][0]
            letter_mesh

        # TODO: Pack up words...

        lineObject = new THREE.Object3D()
        lineObject.add.apply(lineObject, letterObjects)
        lineObject.position.y = - (index || 0) * line_layout.height
        lineObject._line = _line
        lineObject

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
                lineObject._line = line
                lineObject
            .map positionLines

        chainObject = new THREE.Object3D()
        chainObject.add.apply(chainObject, lineObjects)
        chainObject.scale.multiplyScalar(SCALE_TEXT)
        @scene.add(chainObject)

        d3.selectAll(lineObjects).transition()
            .duration (4000)
            .delay (_,i) -> i * 5000
            .ease "poly", 5
            .tween "fadeOpacity", ->
                i = d3.interpolate(0,0.5)
                (t) -> this.children.forEach (mesh) ->
                    mesh.material.uniforms.opacity.value = i(t)

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

    setPositions = (root) =>
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
                    RADIUS * Math.cos(radians) + node.position.x,
                    RADIUS * Math.sin(radians) + node.position.y
                )
                if circle_node.position?
                    check = pos.y.toFixed(5) is circle_node.position.y.toFixed(5)
                    assert(check)
                else
                    circle_node.position = pos

            if node.children?
                node.children.forEach traverse

        traverse(root)
        return root

    addNetwork: (network) =>
        network_object = new THREE.Object3D()
        network_object.scale.multiplyScalar(SCALE_TEXT)
        @scene.add network_object

        root = makeTree network
        root = setPositions root

        traverse = (node) =>
            return if ! node.position?

            text_object = @getLineObject(node.val)
            text_object.children.forEach (mesh) ->
                mesh.material.uniforms.opacity.value = 0
            text_object.position.copy(node.position)
            network_object.add text_object

            d3.select(text_object).transition()
                .duration (1000)
                .ease "poly", 5
                .tween "fadeOpacity", ->
                    i = d3.interpolate(0,0.5)
                    (t) -> this.children.forEach (mesh) ->
                        mesh.material.uniforms.opacity.value = i(t)
                .each "end", ->
                    if node.children
                        node.children.forEach traverse
                    else
                        network_object.remove (this)

        traverse(root)

    animate: =>
        requestAnimationFrame @animate
        @renderer.render( @scene, @camera )

module.exports = Main

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

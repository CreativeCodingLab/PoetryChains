window.THREE = require("three")
createGeometry = require('three-bmfont-text')
Shader = require "./shaders/sdf"
xtend = require 'xtend'
createOrbitViewer = require('three-orbit-viewer')(THREE)

class Main
    constructor: ->
        console.log "Starting Vis"

        @renderer = new THREE.WebGLRenderer()
        @renderer.setPixelRatio( window.devicePixelRatio )
        @renderer.setSize( window.innerWidth, window.innerHeight )
        @renderer.setClearColor( "#eeeeee" )

        # app = createOrbitViewer({
        #     clearColor: 'rgb(255, 255, 255)',
        #     clearAlpha: 1.0,
        #     fov: 55,
        #     position: new THREE.Vector3(0, -4, -5)
        # })
        # @renderer = app.renderer

        @scene = new THREE.Scene()
        # @scene = app.scene

        document.body.appendChild( @renderer.domElement )

        @camera = new THREE.PerspectiveCamera( 70, window.innerWidth / window.innerHeight, 1, 1000 )
        _x = -2
        _y = -2
        @camera.position.z = -5
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
            smooth: 1/64,
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

    getLineObject: (_line, index) =>
        line_geometry = @getTextGeometry(_line.line)
        line_layout = line_geometry.layout
        glyph_positions = line_layout.glyphs.map (g) -> g.position

        letterObjects = _line.line.split("").map (letter, index) =>
            letter_geom = @getTextGeometry(letter)
            letter_mesh = @getTextMesh(letter_geom)
            letter_mesh.scale.multiplyScalar(-1)
            letter_mesh.position.x = - glyph_positions[index][0]
            letter_mesh

        # TODO: Pack up words...

        lineObject = new THREE.Object3D()
        lineObject.add.apply(lineObject, letterObjects)
        lineObject.position.y = -index * line_layout.height
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

    SCALE_TEXT = 0.005

    addChain: (text) =>
        lineObjects = processChain(text)
            .map @getLineObject
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

    RADIUS = 1
    addNode: (node) =>
        console.log(node)

    addNetwork: (network) =>
        @addNode network[0]

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

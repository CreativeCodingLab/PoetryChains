window.THREE = require("three")
createGeometry = require('three-bmfont-text')
Shader = require "./shaders/sdf"
xtend = require 'xtend'
createOrbitViewer = require('three-orbit-viewer')(THREE)

class Main
    SCALE_TEXT = 0.005
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
        @camera.position.z = -10
        @camera.position.x = -1
        @camera.position.y = 0
        @camera.lookAt new THREE.Vector3(-1,0,0)

        light = new THREE.PointLight()
        light.position.set( 200, 100, 150 )
        @scene.add( light )

        helper = new THREE.AxisHelper(50)
        @scene.add( helper )

        grid_helper = new THREE.GridHelper(20, 1)
        grid_helper.rotateX(Math.PI / 2)
        @scene.add grid_helper

        # grid_helper_y = new THREE.GridHelper(20, 1)
        # @scene.add grid_helper_y

        geometry = new THREE.BoxGeometry( 10, 10, 10, 2, 2, 2 );
        object = new THREE.Mesh( geometry );

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
            smooth: 1/32,
            side: THREE.DoubleSide,
            transparent: false,
            color: 'rgb(10, 10, 10)'
        }))
        new THREE.Mesh(geometry, material)

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

    getTextObject: (geometry) ->
        mesh = @getTextMesh(geometry)
        textAnchor = new THREE.Object3D()
        textAnchor.add(mesh)
        textAnchor.scale.multiplyScalar(-1)
        textAnchor

    getLineObject: (_line, index) =>
        line_geometry = @getTextGeometry(_line.line)
        line_layout = line_geometry.layout
        glyph_positions = line_layout.glyphs.map (g) -> g.position

        letterObjects = _line.line.split("").map (letter, index) =>
            letter_geom = @getTextGeometry(letter)
            letter_object = @getTextObject(letter_geom)
            letter_object.position.x = - glyph_positions[index][0]
            letter_object

        # TODO: Pack up words...

        lineObject = new THREE.Object3D()
        lineObject.add.apply(lineObject, letterObjects)
        lineObject.position.y = -index * line_layout.height
        lineObject._line = _line
        lineObject

    addChain: (text) =>
        lineObjects = processChain(text)
            .map @getLineObject

        chainObject = new THREE.Object3D()
        chainObject.add.apply(chainObject, lineObjects)

        chainObject.children.forEach (line, index, array) ->
            return if index is 0

            prev = array[index - 1]
            prev_connector_idx = prev._line.connector_index
            my_prev_connector_idx = line._line.my_prev_connector_index

            line.position.x = prev.position.x
            line.position.x += prev.children[prev_connector_idx].position.x
            line.position.x -= line.children[my_prev_connector_idx].position.x

        chainObject.scale.multiplyScalar(SCALE_TEXT)

        @scene.add(chainObject)

    animate: =>
        requestAnimationFrame @animate
        @renderer.render( @scene, @camera )

module.exports = Main

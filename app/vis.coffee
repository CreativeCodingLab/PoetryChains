window.THREE = require("three")
createGeometry = require('three-bmfont-text')
Shader = require "./shaders/sdf"
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
        @camera.position.z = -4
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
                prev = array[i-1].connector
                prev_idx = obj.line.indexOf prev
                obj.prev_connector = prev
                obj.prev_connector_index = prev_idx
            obj

    getTextObject: (geometry) ->
        mesh = @getTextMesh(geometry)
        textAnchor = new THREE.Object3D()
        textAnchor.add(mesh)
        textAnchor.scale.multiplyScalar(0.005)
        textAnchor.scale.multiplyScalar(-1)
        textAnchor

    addChain: (text) =>
        chain = processChain(text)

        lineObjects = chain.map (c, index) =>
            geometry = @getTextGeometry(c.line)
            textObject = @getTextObject(geometry)
            textObject.position.y = 1 * index
            textObject

        chainObject = new THREE.Object3D()
        chainObject.add.apply(chainObject, lineObjects)

        @scene.add(chainObject)


    animate: =>
        requestAnimationFrame @animate
        @renderer.render( @scene, @camera )

module.exports = Main

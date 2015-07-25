window.THREE = require("three")
createGeometry = require('three-bmfont-text')
Shader = require "./shaders/sdf"
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

        document.body.appendChild( @renderer.domElement )

        @camera = new THREE.PerspectiveCamera( 70, window.innerWidth / window.innerHeight, 1, 1000 )
        @camera.position.z = 2
        @camera.position.x = -1
        @camera.position.y = 1

        @scene = new THREE.Scene()
        # @scene = app.scene

        light = new THREE.PointLight()
        light.position.set( 200, 100, 150 )
        @scene.add( light )

        helper = new THREE.AxisHelper(50)
        @scene.add( helper )

        grid_helper = new THREE.GridHelper(20, 10)
        @scene.add grid_helper

        geometry = new THREE.BoxGeometry( 10, 10, 10, 2, 2, 2 );
        object = new THREE.Mesh( geometry );

        edges = new THREE.EdgesHelper( object, 0x00ff00 );

        # @scene.add( edges );

        @textAnchor = new THREE.Object3D()

    setTexture: (@texture) ->
        maxAni = @renderer.getMaxAnisotropy()

        @texture.needsUpdate = true
        @texture.minFilter = THREE.LinearMipMapLinearFilter
        @texture.magFilter = THREE.LinearFilter
        @texture.generateMipmaps = true
        @texture.anisotropy = maxAni

    setFont: (@font) ->

    tempAddText: (text) ->
        geometry = createGeometry
            text: text
            font: @font

        material = new THREE.ShaderMaterial(Shader({
            map: @texture,
            smooth: 1/32,
            side: THREE.DoubleSide,
            transparent: false,
            color: 'rgb(10, 10, 10)'
        }))

        mesh = new THREE.Mesh(geometry, material)

        @textAnchor.add(mesh)
        @textAnchor.scale.multiplyScalar(-0.005)

        @scene.add(@textAnchor)


    animate: =>
        requestAnimationFrame @animate
        @renderer.render( @scene, @camera )

module.exports = Main

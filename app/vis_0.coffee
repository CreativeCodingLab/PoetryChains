THREE = require("three")

class Main
    renderer = undefined
    scene = undefined
    camera = undefined

    init: ->
        renderer = new THREE.WebGLRenderer();
        renderer.setPixelRatio( window.devicePixelRatio );
        renderer.setSize( window.innerWidth, window.innerHeight );
        renderer.setClearColor( "white" );

        document.body.appendChild( renderer.domElement );

        camera = new THREE.PerspectiveCamera( 70, window.innerWidth / window.innerHeight, 1, 1000 );
        camera.position.z = 100;
        camera.position.x = 10;
        camera.position.y = 10;

        scene = new THREE.Scene();

        light = new THREE.PointLight();
        light.position.set( 200, 100, 150 );
        scene.add( light );

        helper = new THREE.AxisHelper(50);
        scene.add( helper );

    _animate = ->
        requestAnimationFrame( _animate );
        renderer.render( scene, camera );

    animate: _animate

module.exports = Main

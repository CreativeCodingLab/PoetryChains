Main = require "./Main"

module.exports = class IntroVis extends Main
  constructor: (@scene, @camera, @font, @texture) ->
    @log "New IntroVis."

  start: =>
    return @_addIntro()

  _addIntro: ->
    text_title = @getLineObject("Poetry Chains & Collocation Nets")
    text_author = @getLineObject("by Angus Forbes, with Paul Murray")

    lineObject2 = @getLineObject("A series of animated explorations")
    lineObject3 = @getLineObject("through the collected poems of Emily Dickinson")

    text_url = @getLineObject("http://evl.uic.edu/creativecoding")

    text_title.position.y = 30;
    text_author.position.y = text_title.position.y - text_title._layout.height - 50
    text_author.position.x = text_title.position.x - 50
    lineObject2.position.y = text_author.position.y - text_author._layout.height - 180
    lineObject2.position.x = text_title.position.x - 10

    lineObject3.position.y = lineObject2.position.y - lineObject2._layout.height - 10
    lineObject3.position.x = text_title.position.x - 50

    text_url.position.y = lineObject3.position.y - lineObject2._layout.height - 200
    text_url.position.x = text_title.position.x - 10

    text_title.scale.multiplyScalar(1.5)
    text_author.scale.multiplyScalar(0.7)
    lineObject2.scale.multiplyScalar(0.7)
    lineObject3.scale.multiplyScalar(0.7)
    text_url.scale.multiplyScalar(0.5)

    # The objects must be scaled
    # but you can also add everything to a parent object, and scale that:

    parent = new THREE.Object3D()
    parent.add(text_title)
    parent.add(text_author)
    parent.add(lineObject2)
    parent.add(lineObject3)
    parent.add(text_url)
    parent.scale.multiplyScalar(@scaleText)

    @scene.add(parent)

    parent.updateMatrixWorld(true)

    faded = @fadeAll(parent.children, 1, 2500)

    bbox = @getBBox parent
    x = bbox.center().x - 0.2
    y = bbox.center().y
    z = bbox.center().z + @getZoomDistanceFromBox bbox, 1.2
    panned = @panCameraToPosition3 new THREE.Vector3(x,y,z), 1, true

    return Promise.all([faded, panned]).then => @wait 15000
      .then => @fadeAll(parent.children, 0, 1000)

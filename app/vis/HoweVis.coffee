Main = require "./Main"

module.exports = class HoweVis extends Main
  constructor: (@scene, @camera, @font, @texture) ->
    @log "New HoweVis."

  start: (data) =>
    return @_addHowe data

  _addHowe: (text) =>

    parent = new THREE.Object3D()
    parent.updateMatrixWorld(true)
    parent.scale.multiplyScalar(@scaleText)
    @scene.add(parent)

    x = (Math.random() * 1000.0)
    y = (Math.random() * 1000.0)
    #z = (Math.random() * 100.0)
    rz = Math.random() * Math.PI * 2.0
    lh = Math.random() * 150
    numlines = 0

    lines = []

    for line in text
      lineobj = @getLineObject(line)

      if Math.random() > 0.8 or numlines > 6
        x = (Math.random() * 1000.0)
        y = (Math.random() * 500.0)
        #z = (Math.random() * 100.0)
        rz = Math.random() * Math.PI * 2.0
        lh = Math.random() * 150
        numlines = 0
      else
        y -= lh

      lineobj.rotateZ(rz)
      lineobj.translateX(x)
      lineobj.translateY(y)
      numlines = numlines + 1
      lines.push(lineobj)

    @scene.add(parent)

    reduction = (prev, curr) =>
      prev.then =>
        parent.add(curr)
        @fadeToArray(1, 1000) curr.children
        bbox = @getBBox parent
        x = bbox.center().x
        y = bbox.center().y
        z = bbox.center().z + @getZoomDistanceFromBox bbox, 2.5

        return @panCameraToPosition3 new THREE.Vector3(x,y,z), 1000, true

    promise = lines.reduce reduction, Promise.resolve()
      .then =>
        @wait 3000
      .then =>
        @fadeAll(parent.children, 0, 1000)
      .then =>
        parent.remove.apply parent, parent.children
        @scene.remove(parent)

    return promise

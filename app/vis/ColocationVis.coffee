Main = require "./Main"

module.exports = class ColocationVis extends Main
  constructor: (@scene, @camera, @font, @texture) ->
    console.info "New ColocationVis."

  rotation: 0

  start: (network) =>
    radius = 700
    rotation = @rotation # Math.PI / 2.2

    network_object = new THREE.Object3D()
    network_object.scale.multiplyScalar(@scaleText)
    network_object.rotateX rotation

    @scene.add network_object

    root = makeTree network
    root = setNetworkPositions root, radius

    return @animate root, network_object
      .then =>
        @wait 3000
      .then =>
        @fadeAll network_object.children, 0, 1000
      .then =>
        network_object.remove.apply network_object, network_object.children
        @scene.remove network_object

  animate: (root, network_object) ->

    traverse = (node, index, array) =>
      # return Promise.resolve() if ! node.position?
      # console.log array

      node = @setTextObject(node)
      text_object = node._text_object
      text_object.rotateX -@rotation
      network_object.add text_object

      delay = 1000

      ################################
      # ANIMATE COLOCATION NETWORK
      #
      # console.log index
      return Promise.resolve().then =>
          # if node.parent
          #   console.log node
          #   return @wait(Math.random() * delay)
          return
        .then =>
          @fadeToArray(1, 1000) text_object.children
        .then =>
          if node.children
            # return faded_in.then =>
            return Promise.resolve().then =>
                # if array
                #   return @wait(delay * array.length)
                # return @wait(delay * 10)
                return
              .then =>
                @wait(delay * 2)
                  .then => @panCameraToObject(text_object)
              .then =>
                if node.parent?
                  siblings = node.parent.children.filter (child) ->
                    return child._text_object isnt text_object
                  if node.parent.parent
                    siblings = siblings.concat(node.parent.parent)
                  promises = siblings.map (sibling) =>
                    @fadeToArray(0, 1000) sibling._text_object.children
                      .then -> network_object.remove(sibling._text_object)
                  return Promise.all promises
              .then => @wait 1e3
              .then =>
                promises = node.children.map (child) =>
                  @wait(Math.random() * delay)
                    .then => traverse(child)
                return Promise.all promises
          else
            return Promise.resolve()

    return traverse(root)

  setTextObject: (node) =>
    text_object = @getLineObject(node.val)
    text_object.children.forEach (mesh) ->
      mesh.material.uniforms.opacity.value = 0
    text_object.position.copy(node.position)
    node._text_object = text_object
    node

  setNetworkPositions = (root, radius) ->
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
          # 0,
          # radius * Math.sin(radians) + node.position.z
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

  getRadians = (a, b) ->
    dx = a.position.x - b.position.x
    dy = a.position.y - b.position.y
    Math.atan2(dy, dx)

  makeTree = (network) ->
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

Main = require "./Main"
d3 = require "d3"

module.exports = class ColocationVis extends Main
  constructor: (@scene, @camera, @font, @texture) ->
    @log "New ColocationVis."

  rotation: 0
  maxSizeScale: 2

  start: (network) =>
    radius = 600
    rotation = @rotation
    network_object = @getParentObject()

    maxAmount = getMaxAmount network

    @amountScale = d3.scale.linear()
      .domain([1, maxAmount])
      .range([1, @maxSizeScale])

    root = makeTree network
    root = @setNetworkPositions root, radius

    return @animate root, network_object
      .then =>
        @wait 3000
      .then =>
        @fadeAll network_object.children, 0, 1000
      .then =>
        network_object.remove.apply network_object, network_object.children

  animate: (root, network_object) ->

    network_object.add root._text_object
    @fadeToArray(1, 1000) root._text_object.children

    traverse = (node, index, array) =>
      delay = 1000

      next_child = node.children.filter((_) -> _.children?)[0]

      if node.children?
        @addChildren node

      return @adjustCameraToFitWidth node._text_object.parent, 1.7
        .then => @wait 1e3
        .then =>
          if next_child?
            @moveChildren node, delay
              .then => @wait 2e3
              .then =>
                @fadeOutSiblingsAndGrandparent(next_child)
                # traverse next_child
              .then => traverse next_child

    return traverse(root)

  addChildren: (node) ->
    node.children.map (child) =>
      child._text_object or= @getTextObject child
      node._text_object.parent.add child._text_object
      scale = @amountScale child.amt || 1
      child._text_object.scale.multiplyScalar scale

  moveChildren: (node, delay) ->
    node.children.map (child) =>
      child._end_position = child._text_object.position.clone()
      child._start_position = node._text_object.position.clone()
      child._start_size = new THREE.Vector3(0.01, 0.01, 0.01)
      child._end_size = child._text_object.scale.clone()
      child._text_object.position.copy child._start_position
      child._text_object.scale.copy child._start_size

    self = this

    return new Promise (resolve) ->
      d3.selectAll(node.children).transition()
        .duration 2000
        .delay -> Math.random() * delay
        .tween "moveChild", ->
          start = this._start_position
          end = this._end_position
          position = d3.interpolate start, end

          startSize = this._start_size
          endSize = this._end_size
          scale = d3.interpolate startSize, endSize
          return (t) ->
            this._text_object.position.copy position(t)
            this._text_object.scale.copy scale(t)
        .each ->
          self.fadeToArray(1, 3000) this._text_object.children
          d3.transition().each "end", resolve

  fadeInChildren: (node, delay) ->
    promises = node.children.map (child) =>
      # Stagger fade-in of children
      @wait Math.random() * delay
        .then => @fadeToArray(1, 1000) child._text_object.children
    return Promise.all promises

  fadeOutSiblingsAndGrandparent: (node) ->
    others = node.parent.children.filter (child) ->
      return child isnt node
    if node.parent.parent
      others = others.concat(node.parent.parent)
    promises = others.map (relative) =>
      @fadeToArray(0, 1000) relative._text_object.children
        .then -> relative._text_object.parent.remove(relative._text_object)
    return Promise.all promises

  getTextObject: (node) =>
    text_object = @getLineObject(node.val)
    text_object.position.copy(node.position)
    return text_object

  setTextObject: (node) =>
    # text_object = @getLineObject(node.val)
    # text_object.position.copy(node.position)
    # node._text_object = text_object
    node._text_object = @getTextObject node
    node

  setNetworkPositions: (root, radius) ->
    root.position = new THREE.Vector3()
    radianScale = d3.scale.ordinal().rangePoints [0, 2 * Math.PI]
    node = root
    do traverse = (node) =>
      return if ! node.children?
      offset = if node.parent? then getRadians(node.parent, node) else 0
      # The circle nodes include the current node's children and its parent
      circle_nodes = if node.parent?
        [node.parent].concat(node.children)
      else node.children
      # Set the radian scale's domain to evenly space the circle nodes
      radianScale.domain d3.range(circle_nodes.length + 1)
      # Set the cirlce node positions
      circle_nodes.forEach (circle_node, index) ->
        radians = radianScale(index) + offset
        pos = new THREE.Vector3(
          radius * Math.cos(radians) + node.position.x,
          radius * Math.sin(radians) + node.position.y
        )
        unless circle_node.position?
          circle_node.position = pos

      node = @setTextObject(node)
      node._text_object.rotateX -@rotation

      if node.children?
        node.children.forEach traverse
    return node

  getRadians = (a, b) ->
    dx = a.position.x - b.position.x
    dy = a.position.y - b.position.y
    Math.atan2(dy, dx)

  getMaxAmount = (network) ->
    _max = network.map (_) -> _.colocations
      .map (_) -> d3.max(_, (d) -> d.amt)
    return d3.max(_max)

  makeTree = (network) ->
    network = network.map (d) ->
      val: d.word
      children: d.colocations
    reducer = (child, parent, index, array) ->
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
    return network.reduceRight(reducer)

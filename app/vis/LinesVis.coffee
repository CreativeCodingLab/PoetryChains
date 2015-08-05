Main = require "./Main"

module.exports = class LinesVis extends Main
  lineSpacing: 40

  constructor: (@scene, @camera, @font, @texture) ->
    console.info "New LinesVis."
    lines_object = new THREE.Object3D()
    lines_object.scale.multiplyScalar(@scaleText)
    lines_object.updateMatrixWorld(true)
    @scene.add lines_object
    @lines_object = lines_object

  start: (data) ->
    # Convert lines data to tree structure
    root = linesToTree data

    # Add empty Object3Ds
    root = @addObjects root

    # Position objects
    root = @positionObjects root

    @animateLines root
      .then =>
        @fadeAll @lines_object.children, 0, 2000
      .then =>
        @lines_object.remove.apply(@lines_object, @lines_object.children)

  ########################
  # ANIMATE LINES
  animateLines: (root) =>
    # Fade in the root
    @lines_object.add root._text_object
    @fadeToArray(1, 1000) root._text_object.children
    @panCameraToObject root._text_object
      .then => return @traverse root

  fadeOutOthers: (object) ->
    others = object.parent.children.filter (child) ->
      child isnt object
    promises = others.map (each) =>
      @fadeToArray(0, 1000) each.children
        .then => object.parent.remove each
    return Promise.all promises

  traverse: (node) =>
    console.assert node.word isnt "", "node.word is '#{node.word}'", node
    return if ! node.children?
    return if node.word is ""

    next_child = node.children.filter((_) -> _.children?)[0]

    # Start promise chain
    return Promise.resolve()
      .then =>
        return @fadeOutOthers node._text_object
      .then =>
        # Fade in children
        if next_child?
          promises = node.children.map (child) =>
            @lines_object.add child._text_object
            # Get the array of letters for the target word only
            children = @getLetterObjectsForWord child._text_object, node.word
            @fadeToArray(1, 1000) children
          return Promise.all promises
      .then =>
        # Chained fade-in of child lines
        if next_child?
          pos = node._positions_array
          curr = pos.indexOf(node)
          next = pos.indexOf(next_child)
          if curr < next
            fade_array = pos.slice(curr + 1, next + 1)
          else
            fade_array = pos.slice(next, curr).reverse()
          @chainedFadeIn fade_array, 1000
      .then =>
        if next_child?
          # fadeToArray(1, 1000) next_child._text_object.children
          @panCameraToObject next_child._text_object
      .then =>
        @wait 3e3
      .then =>
        if next_child?
          return @traverse next_child
        else
          return Promise.resolve()

  positionObjects: (parent) =>
    do traverse = (parent) =>
      return if ! parent.children?

      positions_array = d3.shuffle parent.children.concat parent
      parent_index = positions_array.indexOf parent
      parent_y = parent._text_object.position.y

      parent._positions_array = positions_array

      positions_array.forEach (node, index) =>
        offset_from_parent = index - parent_index
        obj = node._text_object
        line_height = obj._layout.height + @lineSpacing
        obj.position.y = parent_y + offset_from_parent * line_height

      parent.children.forEach @alignToNode(parent)
      parent.children.forEach traverse

    return parent

  # TODO: Make this much more general and add it to Main
  alignToNode: (parent) ->
    (child) =>
      parent_x = parent._text_object.position.x
      word = word or parent.word
      offset = [ parent, child ]
          .map (_) =>
            idx = @getWordIndex _.line, word
            console.assert idx isnt -1, "#{_.line}, #{word}"
            _._text_object.children[idx].position.x
          .reduce (a, b) -> a - b
      child._text_object.position.x = parent_x + offset

  addObjects: (node) ->
    do traverse = (node) =>
      node._text_object = @getLineObject node.line
      node.children.forEach traverse if node.children
    return node

  linesToTree = (lines) ->
    lines = lines.map (line) ->
      line: line.line
      word: line.word
      sIdx: line.sIdx
      eIdx: line.eIdx
      children: line.lines
    reducer = (prev, current, index, array) ->
      prev_index = current.children
          .map (_) -> _.line
          .indexOf(prev.line)
      current.children[prev_index] = prev
      prev._parent = current
      current
    lines.reduceRight reducer

Main = require "./Main"

module.exports = class LinesVis extends Main
  lineSpacing: 40

  constructor: (@scene, @camera, @font, @texture) ->
    @log "New LinesVis."

    @lines_object = @getParentObject()

  start: (data) ->
    data = sanitizeData data
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

  ######################################################################
  # ANIMATE LINES
  animateLines: (root) =>
    # Fade in the root
    @lines_object.add root._text_object
    @fadeToArray(1, 1000) root._text_object.children
    @adjustCameraToFitWidth root._text_object
      .then => return @traverse root

  traverse: (node) =>
    console.assert node.word isnt "", "node.word is '#{node.word}'", node
    return if ! node.children?
    return if node.word is ""

    # Does this node have a child with more children?
    next_child = node.children.filter((_) -> _.children?)[0]

    # Start promise chain
    return Promise.resolve()
      .then =>
        return @fadeOutOthers node._text_object
      .then =>
        if next_child?
          return @fadeInChildWords node
      .then =>
        if next_child?
          return @chainedFadeInChildren(node, next_child)
      .then =>
        @viewFullLines node
        @wait 3e3
      .then =>
        if next_child?
          return @traverse next_child
        else
          return Promise.resolve()

  viewFullLines: (node) ->
    # Clone the parent, and remove its children
    parent = node._text_object.parent
    parentClone = parent.clone()
    parentClone.children = []
    # Add parentClone as a sibling of the original
    parent.parent.add parentClone
    # Clone all sibling nodes
    # And get nodes where all letters have non-zero opacity
    clonedLines = parent.children.map (each) -> each.clone()
      .filter (line) ->
        return line.children.every (child) ->
          return child.material.uniforms.opacity.value > 0
    # Add them to parentClone
    parentClone.add.apply parentClone, clonedLines
    bbox = @getBBox parentClone
    parentClone.parent.remove parentClone
    @adjustCameraToFitBox bbox, 1.3

  chainedFadeIn: (array, duration) ->
    reduction = (promise, curr, index, array) =>
      return promise.then =>
        @fadeToArray(1, 1000) curr._text_object.children
        # @adjustCameraToFitWidth curr._text_object
        @viewFullLines curr
    return array.reduce reduction, Promise.resolve()

  chainedFadeInChildren: (node, next_child) ->
    pos = node._positions_array
    curr = pos.indexOf(node)
    next = pos.indexOf(next_child)
    if curr < next
      fade_array = pos.slice(curr + 1, next + 1)
    else
      fade_array = pos.slice(next, curr).reverse()
    return @chainedFadeIn fade_array, 1000

  fadeInChildWords: (node) ->
    # Fade in children, target word only
    promises = node.children.map (child) =>
      @lines_object.add child._text_object
      # Get the array of letters for the target word only
      children = @getLetterObjectsForWord child._text_object, node.word
      return @fadeToArray(1, 1000) children
    return Promise.all promises

  fadeOutOthers: (object) ->
    others = object.parent.children.filter (child) ->
      child isnt object
    promises = others.map (each) =>
      @fadeToArray(0, 1000) each.children
        .then => object.parent.remove each
    return Promise.all promises

  positionObjects: (parent) =>
    do traverse = (parent) =>
      return if ! parent.children?

      positions_array = d3.shuffle parent.children.concat parent
      parent_index = positions_array.indexOf parent
      parent_y = parent._text_object.position.y
      # Set the array determining positons for this node and its children
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
  # TODO: Use sIdx and eIdx
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
    return lines.reduceRight reducer

  sanitizeData = (data) ->
    return data.map (each) ->
      if each.sIdx is each.eIdx
        if each.line[each.sIdx] isnt ""
          each.word = each.line[each.sIdx]
          each.eIdx = each.sIdx + 1
        else
          console.error each, each.line[each.sIdx+1]
      console.assert each.sIdx isnt each.eIdx, each
      console.assert each.word isnt "", each
      return each

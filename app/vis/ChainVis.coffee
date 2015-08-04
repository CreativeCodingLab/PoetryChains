Main = require "./Main"
assert = require "assert"

module.exports = class ChainVis extends Main
  constructor: (@scene, @camera, @font, @texture) ->
    console.info "New ChainVis."

  start: (data) =>
    reducer = (prev, curr) =>
      return prev.then (lastObject) =>
          @_addChain curr, lastObject
            .then (last) =>
              @wait 10e3
                .then () -> return last
            .then @_endChain
    promise = data.reduce reducer, Promise.resolve()
      .then =>
        p = @parentObject()
        c = p.children
        return @fadeAll p.children, 0, 2000
          .then => p.remove.apply p, c
    return promise

  _endChain: (lastObject) =>
    # console.info "Done with one chain."
    siblings = lastObject.parent.children.filter (child) ->
      child isnt lastObject
    @fadeAll(siblings, 0, 1000)
    @adjustCamera lastObject
      .then ->
        lastObject.parent.remove.apply(lastObject.parent, siblings)
        return lastObject
      .then (lastObject) =>
        lastWord = lastObject._line.connector
        # console.log lastWord
        accessor = (obj) -> obj._line.line
        lastWordLetters = @getLetterObjectsForWord lastObject, lastWord, accessor
        assert lastWordLetters.length is lastWord.length
        siblings = @getSiblingsFromSubset lastObject, lastWordLetters
        return @fadeToArray(0, 1000)(siblings)
        # @fadeToArray(0.2, 500) lastWordLetters
      .then =>
        lastObject.remove.apply(lastObject, siblings)
        @adjustCamera lastObject
        lastObject.name = "last_word"
        # console.log lastObject._letters()
        return lastObject

  _addChain: (text, lastObject) =>
    processed = @processChain(text)

    lineObjects = processed.map (line, index) =>
        lineObject = @getLineObject(line.line, index)
        lineObject._line = line
        return lineObject

    if lastObject?
      last_word = lastObject._letters().join("")
      @alignObjectsByWord lastObject, lineObjects[0], last_word
      lineObjects.forEach (obj) -> obj.position.copy lineObjects[0].position

    # if lastObject?
      # lineObjects[0] = @addToExistingObject lastObject, lineObjects[0]
      # lineObjects.forEach (obj) -> obj.position.copy lineObjects[0].position

    lineObjects = lineObjects.map (lineObject, index) =>
        height = lineObject._layout.height
        lineObject.position.y += - (index) * (height + 20)
        return lineObject
      .map positionLines

    chainObject = @parentObject()

    ########################
    # ANIMATE POETRY CHAIN
    reducer = (prev, curr, index, array) =>
      prev.then =>
        chainObject.add curr
        word = curr._line.prev_connector
        return if ! word? # word.length is 0
        console.assert word isnt "", "Connecting word is '#{word}'", curr._line
        return if word is ""
        accessor = (obj) -> obj._line.line
        one_word_array = @getLetterObjectsForWord curr, word, accessor
        bbox = @getBBoxFromSubset curr, one_word_array
        return @fadeToArray(1, 1000) one_word_array
        # return @panCameraToBBox bbox, 1000
      .then =>
        @adjustCamera chainObject
        @fadeToArray(1, 1000) curr.children
            .then -> return curr

    first = Promise.resolve()
    return lineObjects.reduce reducer, first

  positionLines = (line, index, array) ->
    return line if index is 0

    prev = array[index - 1]
    prev_connector_idx = prev._line.connector_index
    my_prev_connector_idx = line._line.my_prev_connector_index

    line.position.x = prev.position.x
    line.position.x += prev.children[prev_connector_idx].position.x
    line.position.x -= line.children[my_prev_connector_idx].position.x
    line

  processChain: (chain) =>
    chain.map (obj, i, array) =>
      #obj.connector_index = obj.line.indexOf obj.connector
      obj.connector_index = obj.line.toLowerCase().indexOf obj.connector.toLowerCase()
      if i > 0
        prev = array[i-1]
        prev_con = prev.connector
        # my_prev_idx = obj.line.indexOf prev_con
        my_prev_idx = @getWordIndex obj.line, prev_con
        prev_idx = prev.connector_index
        obj.prev_connector = prev_con
        obj.my_prev_connector_index = my_prev_idx
        obj.prev_connector_index = prev_idx
      obj

d3 = require "d3"
Vis = require "./vis"

vis = new Vis()
vis.speedMultiplier = 0.1

do ->
  font_loaded = new Promise (resolve) ->
    require('./load')(
      font: "fnt/palatino.fnt",
      image: "fnt/palatino.png"
    , (font, texture) -> resolve({ font: font, texture: texture }))

  font_loaded.then (obj) ->
    vis.setTexture(obj.texture)
    vis.setFont(obj.font)
  .then ->
    switch window.location.hash
      when "", "#all" then do all
      when "#chain" then do chainMode
      when "#colocation" then do colocationMode
      when "#lines" then do linesMode
      when "#intro" then do introMode
      when "#howe" then do howeMode

apiUrl = (call) ->
  "#{window.location.origin}/api/#{call}"

getJson = (apiCall, message) ->
  new Promise (resolve) ->
    console.info message
    url = apiUrl apiCall
    d3.json url, resolve

modeGetter = () ->
  order = [ "intro", "chain", "lines", "colocation", "howe" ]
  index = -1
  ->
    if ++index is order.length then index = 0
    return order[index]

getModeFunc = (mode) ->
  switch mode
    when "intro" then vis.addIntro
    when "chain" then vis.addChain
    when "colocation" then vis.addNetwork
    when "lines" then vis.addLines
    when "howe" then vis.addHowe

getLastWord = (data, mode) ->
  if mode is "chain"
    _last = data[data.length-1]
    return _last[_last.length-1].connector
  if mode is "lines"
    return data[data.length-1].word
  if mode is "colocation"
    return data[data.length-1].word
  else
    return undefined

getModeData = (mode, word) ->
  if mode is "intro"
    return Promise.resolve()
  else if word?
    return getJson "get-#{mode}.json?word=#{word}", "Requesting: #{mode}"
  else
    return getJson "get-#{mode}.json", "Requesting: #{mode}"

all = ->
  getNextMode = modeGetter()
  console.info "Starting all."

  mode = getNextMode()
  got_first_data = getModeData mode
    .then (data) -> repeat mode, data

  repeat = (mode, data) ->
    console.info "Mode: #{mode}"
    current_mode_done = getModeFunc(mode)(data)

    lastWord = getLastWord(data, mode)
    next_mode = getNextMode()
    got_next_mode_data = getModeData next_mode, lastWord

    Promise.all([got_next_mode_data, current_mode_done])
      .then (array) ->
        next_data = array[0]
        repeat next_mode, next_data

  # current_mode_done = got_first_data
  #   .then (d) -> return getModeFunc(mode)(d)
  #
  # current_mode_done
  #   .then -> console.info "#{mode} mode is done."
  #
  # next_mode = getNextMode()
  #
  # got_next_data = got_first_data
  #   .then (d) ->
  #     lastWord = getLastWord(d, mode)
  #     return getModeData next_mode, lastWord
  #
  # Promise.all([got_next_data, current_mode_done])
  #   .then (array) ->
  #     next_data = array[0]
  #     console.log next_data
  #     return getModeFunc(next_mode)(next_data)
  #   .then (last_data) ->
  #     console.info "#{next_mode} mode is done."
  #     console.log last_data


  # mode = getNext()
  # console.info "mode: #{mode}"
  # got_first = getJson "get-#{mode}.json", "Requesting: #{mode}"
  #
  # doNextMode = (d) ->
  #   switch mode
  #     when "chain" then vis.addChain d
  #   lastWord = getLastWord(d, mode)
  #   console.log mode
  #   console.log d
  #   console.log lastWord
  #   mode = getNext()
  #   getJson "get-#{mode}.json?word=#{lastWord}", "Requesting: #{mode}"
  #     .then doNextMode
  #
  # got_first.then doNextMode

linesMode = ->
  console.info "Starting Lines Mode."
  getJson "get-lines.json", "Requesting Lines..."
    .then vis.addLines

chainMode = ->
  console.info "Starting Chain Mode."
  getJson "get-chain.json", "Requesting poetry chain..."
    .then vis.addChain

colocationMode = ->
  console.info "Starting Colocation Mode."
  getJson "get-colocation.json", "Requesting colocation network..."
    .then vis.addNetwork

introMode = ->
  console.info "Starting Intro Mode."
  vis.addIntro()

howeMode = ->
  console.info "Starting Howe Mode."
  getJson "get-howe.json", "Requesting list of lines..."
    .then vis.addHowe

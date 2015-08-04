d3 = require "d3"
Vis = require "./vis"

vis = new Vis()

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

apiUrl = (call) ->
  "#{window.location.origin}/api/#{call}"

getJson = (apiCall, message) ->
  new Promise (resolve) ->
    console.info message
    url = apiUrl apiCall
    d3.json url, resolve

modeGetter = () ->
  order = [ "chain", "lines", "colocation" ]
  index = 2
  ->
    if ++index is order.length then index = 0
    return order[index]

getLastWord = (data, mode) ->
  console.log data, mode
  if mode is "chain"
    _last = data[data.length-1]
    return _last[_last.length-1].connector
  # last = if mode is "chain" then data[data.length-1]

all = ->
  getNext = modeGetter()
  console.info "Starting all."

  mode = getNext()
  got_first = getJson "get-#{mode}.json", "Requesting: #{mode}"

  got_first.then (d) ->
    lastWord = getLastWord(d, mode)
    next_mode = getNext()
    getJson "get-#{next_mode}.json?word=#{lastWord}", "Requesting: #{next_mode}"
    console.log lastWord

  # next = (word) ->
  #   mode = getNext()
  #   got_this_data = getJson "get-#{mode}.json", "Requesting: #{mode}"
  #     .then (d) -> console.log d
  #
  #   next_mode = getNext()
  #
  # next()




linesMode = ->
  console.info "Starting Lines Mode."
  getJson "get-lines.json", "Requesting Lines..."
    .then vis.addLines

chainMode = ->
  console.info "Starting Chain Mode."
  getJson "get-chain.json", "Requesting poetry chain..."
    .then (d) ->
      vis.addChain d[0]

colocationMode = ->
  console.info "Starting Colocation Mode."
  getJson "get-colocation.json", "Requesting colocation network..."
    .then vis.addNetwork

introMode = ->
  console.info "Starting Intro Mode."
  vis.addIntro()

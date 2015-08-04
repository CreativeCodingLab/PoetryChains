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
  if mode is "chain"
    _last = data[data.length-1]
    return _last[_last.length-1].connector
  if mode is "lines"
    return data[data.length-1].word
  if mode is "colocation"
    return data[data.length-1].word

all = ->
  getNext = modeGetter()
  console.info "Starting all."

  mode = getNext()
  console.info "mode: #{mode}"
  got_first = getJson "get-#{mode}.json", "Requesting: #{mode}"

  doNextMode = (d) ->
    lastWord = getLastWord(d, mode)
    console.log mode
    console.log d
    console.log lastWord
    mode = getNext()
    getJson "get-#{mode}.json?word=#{lastWord}", "Requesting: #{mode}"
      .then doNextMode

  got_first.then doNextMode

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

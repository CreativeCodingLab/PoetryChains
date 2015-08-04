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
      when "" then do all
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

all = ->
  console.info "Starting all."
  order = [ "chain", "lines", "colocation" ]
  mode = order[0]

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

howeMode = ->
  console.info "Starting Howe Mode."
  getJson "get-howe.json", "Requesting list of lines..."
    .then vis.addHowe 


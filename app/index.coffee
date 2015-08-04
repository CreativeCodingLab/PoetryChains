d3 = require "d3"
Vis = require "./vis/Main"
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
      when "#howe" then do howeMode

apiUrl = (call) ->
  "#{window.location.origin}/api/#{call}"

getJson = (apiCall, message) ->
  new Promise (resolve) ->
    console.info message
    url = apiUrl apiCall
    d3.json url, resolve

modeGetter = () ->
  # order = [ "intro", "chain", "lines", "colocation", "howe", "howe", "howe", "howe", "howe", "howe" ]
  order = [ "intro", "chain", "lines", "colocation", "howe", "howe", "howe", "howe", "howe", "howe" ]
  # order = [ "intro", "chain", "lines", "colocation", "howe", "howe", "howe", "howe" ]
  index = -1
  ->
    if ++index is order.length then index = 0
    return order[index]

getModeFunc = (mode) ->
  switch mode
    when "intro" then (d) -> vis.getVisType("IntroVis").start(d)
    # when "intro" then vis.addIntro
    # when "chain" then vis.addChain
    when "chain" then (d) -> vis.getVisType("ChainVis").start(d)
    # when "colocation" then vis.addNetwork
    when "colocation" then (d) -> vis.getVisType("ColocationVis").start(d)
    when "lines" then (d) -> vis.getVisType("LinesVis").start(d)
    when "howe" then (d) -> vis.getVisType("HoweVis").start(d)
    # when "lines" then (d) -> vis.getVisType("LinesVis").start(d)
    # when "howe" then vis.addHowe

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

linesMode = ->
  console.info "Starting Lines Mode."
  getJson "get-lines.json", "Requesting Lines..."
    # .then vis.addLines
    .then (d) -> vis.getVisType("LinesVis").start(d)

chainMode = ->
  console.info "Starting Chain Mode."
  getJson "get-chain.json", "Requesting poetry chain..."
    # .then vis.addChain
    .then (d) -> vis.getVisType("ChainVis").start(d)

colocationMode = ->
  console.info "Starting Colocation Mode."
  getJson "get-colocation.json", "Requesting colocation network..."
    # .then vis.addNetwork
    .then (d) -> vis.getVisType("ColocationVis").start(d)

introMode = ->
  console.info "Starting Intro Mode."
  vis.addIntro()

howeMode = ->
  console.info "Starting Howe Mode."
  getJson "get-howe.json", "Requesting list of lines..."
    .then vis.addHowe

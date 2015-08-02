d3 = require "d3"
Vis = require "./vis"

vis = new Vis()

do ->
    font_loaded = new Promise (resolve) ->
        require('./load')(
            font: "fnt/Palatino-Linotype.fnt",
            image: "fnt/Palatino-Linotype.png"
        , (font, texture) -> resolve({ font: font, texture: texture }))

    font_loaded.then (obj) ->
        vis.setTexture(obj.texture)
        vis.setFont(obj.font)
    .then ->
        switch window.location.hash
            when "", "#chain" then do chainMode
            when "#colocation" then do colocationMode
            when "#lines" then do linesMode

        # test = vis.newTest()
        # interval = -> test.foo()
        # setInterval interval, 1000

apiUrl = (call) ->
    "#{window.location.origin}/api/#{call}"

getJson = (apiCall, message) ->
    new Promise (resolve) ->
        console.info message
        url = apiUrl apiCall
        d3.json url, resolve

linesMode = ->
    console.info "Starting Lines Mode."
    getJson "get-lines.json", "Requesting Lines..."
        .then vis.addLines

chainMode = ->
    console.info "Starting Chain Mode."
    getJson "get-chain.json", "Requesting poetry chain..."
        .then (d) ->
            vis._addChain d[0]

colocationMode = ->
    console.info "Starting Colocation Mode."
    getJson "get-colocation.json", "Requesting colocation network..."
        .then vis.addNetwork

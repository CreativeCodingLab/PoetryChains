d3 = require "d3"
Vis = require "./vis"

vis = new Vis()

do ->
    font_loaded = new Promise (resolve) ->
        do vis.animate

        require('./load')({
            # font: 'fnt/DejaVu-sdf.fnt',
            # image: 'fnt/DejaVu-sdf.png'
            # font: "fnt/Lato-Regular-64.fnt",
            # image: "fnt/lato.png"
            # font: "fnt/test-font.fnt",
            # image: "fnt/test-font.png"
            font: "fnt/Palatino-Linotype.fnt",
            image: "fnt/Palatino-Linotype.png"
        }, (font, texture) -> resolve({ font: font, texture: texture }))

    font_loaded.then (obj) ->
        vis.setTexture(obj.texture)
        vis.setFont(obj.font)
    .then ->
        switch window.location.hash
            when "", "#chain" then do chainMode
            when "#colocation" then do colocationMode

    chainMode = ->
        console.info "Starting Chain Mode."

        poetry_chain_loaded = new Promise (resolve) ->
            console.log "Requesting poetry chain..."
            url = "#{window.location.origin}/api/get-chain.json"
            d3.json(url, resolve)

        poetry_chain_loaded.then (d) ->
            # TODO: Get font with em-dash
            # d.forEach (chain) ->
            #     chain.forEach (line) ->
            #         line.line = line.line.replace("--", "—")
            vis.addChain d[0]

    colocationMode = ->
        console.info "Starting Colocation Mode."

        network_loaded = new Promise (resolve) ->
            console.log "Requesting colocation network..."
            url = "#{window.location.origin}/api/get-colocation.json"
            d3.json(url, resolve)

        network_loaded.then (d) ->
            vis.addNetwork d

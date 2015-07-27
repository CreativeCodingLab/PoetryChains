d3 = require "d3"
Vis = require "./vis"

vis = new Vis()

font_loaded = new Promise (resolve) ->
    do vis.animate

    require('./load')({
        # font: 'fnt/DejaVu-sdf.fnt',
        # image: 'fnt/DejaVu-sdf.png'
        font: "fnt/Lato-Regular-64.fnt",
        image: "fnt/lato.png"
    }, (font, texture) -> resolve({ font: font, texture: texture }))

font_loaded.then (obj) ->
    vis.setTexture(obj.texture)
    vis.setFont(obj.font)

poetry_chain_loaded = new Promise (resolve) ->
    console.log "Requesting poetry chain..."
    url = "#{window.location.href}api/get-chain.json"
    d3.json(url, resolve)

poetry_chain_loaded.then (d) ->
    # d.forEach (chain) ->
    #     chain.forEach (line) ->
    #         line.line = line.line.replace("--", "—")

    vis.addChain d[0]

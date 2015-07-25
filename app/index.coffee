test = require "./test"
Vis = require "./vis2"

vis = new Vis()

font_loaded = new Promise (resolve) ->
    do vis.animate

    require('./load')({
        font: 'fnt/DejaVu-sdf.fnt',
        image: 'fnt/DejaVu-sdf.png'
    }, (font, texture) -> resolve({ font: font, texture: texture }))

font_loaded.then (obj) ->
    vis.setTexture(obj.texture)
    vis.setFont(obj.font)
    vis.tempAddText("foo bar")

console.log "hello from app"

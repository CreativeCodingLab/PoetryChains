express = require("express")
poetryFunctions = require "./poetry-chains-json"
browserify = require 'browserify-middleware'
coffeeify = require 'coffeeify'
path = require "path"

browserify.settings('extensions', ['.coffee'])
browserify.settings('transform', [coffeeify])
browserify.settings('grep', /\.coffee$|\.js$/)

app = express()

app.use require("cors")()

app.get("/api/get-chain.json", (request, response) ->
    poetryFunctions().poetryChain().then (data) ->
        response.json(data)
)

app.get("/api/get-colocation.json", (request, response) ->
    poetryFunctions().colocationNet().then (data) ->
        response.json(data)
)

app.get("/api/get-lines.json", (request, response) ->
    poetryFunctions().lineMaker().then (data) ->
        response.json(data)
)

app.get "/app", browserify("./app/index.coffee")

static_path = path.resolve __dirname, "static"
app.use("/", express.static(static_path))

server = app.listen(process.env.PORT || 8888, process.env.IP, ->
    a = server.address().address
    p = server.address().port
    console.log("Listening to the universe at #{a}, port #{p}")
)

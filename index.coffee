express = require("express")
poetryFunctions = require "./poetry-chains-java"
browserify = require 'browserify-middleware'
coffeeify = require 'coffeeify'
path = require "path"

browserify.settings('extensions', ['.coffee'])
browserify.settings('transform', [coffeeify])
browserify.settings('grep', /\.coffee$|\.js$/)

app = express()

app.use require("cors")()

process.env.PORT = 8766

app.get "/log/:message", (request, response) ->
  console.log "#{new Date()}: #{request.params.message}"
  response.end()

app.use (request, response, next) ->
  console.log "#{new Date()}: Got request.";
  next()

app.get("/api/get-chain.json", (request, response) ->
  word = request.query.word
  poetryFunctions().poetryChain(word).then (data) ->
    response.json(data)
)

app.get("/api/get-colocation.json", (request, response) ->
  word = request.query.word
  poetryFunctions().colocationNet(word).then (data) ->
    response.json(data)
)

app.get("/api/get-lines.json", (request, response) ->
  word = request.query.word
  poetryFunctions().lineMaker(word).then (data) ->
    response.json(data)
)

app.get("/api/get-howe.json", (request, response) ->
    poetryFunctions().howeMaker().then (data) ->
        response.json(data)
)

app.get "/app", browserify("./app/index.coffee")

static_path = path.resolve __dirname, "static"
app.use("/", express.static(static_path))

server = app.listen(process.env.PORT || 8888, process.env.IP, ->
#server = app.listen(port, process.env.IP, ->
  a = server.address().address
  p = server.address().port
  console.log("Listening to the universe at #{a}, port #{p}")
)

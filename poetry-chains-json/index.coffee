childProcess = require('child_process')
path = require("path")
Promise = require("promise")

runScript = (scriptPath) ->
    java_directory = path.resolve(__dirname, "PoetryChains")
    command = "cd #{java_directory}; #{scriptPath}"

    new Promise (resolve, reject) ->
        childProcess.exec(command, (error, stdout, stderr) ->
            # console.log(error, stdout, stderr)
            reject(error) if (error)
            json = JSON.parse(stdout)
            resolve(json)
        )

poetryChain = ->
    runScript("./run_poetry_chain.sh")

collocationNet = ->
    runScript("./run_collocation_net.sh")

module.exports = ->
    {
        poetryChain: -> runScript("./run_poetry_chain.sh")
        collocationNet: -> runScript("./run_collocation_net.sh")
    }

# module.exports = () -> "HELLO"

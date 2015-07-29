childProcess = require('child_process')
path = require("path")
Promise = require("promise")

replaceEmDash = (text) ->
    text.replace(/--/g, "—")

runScript = (scriptPath) ->
    java_directory = path.resolve(__dirname, "PoetryChains")
    command = "cd #{java_directory}; #{scriptPath}"

    new Promise (resolve, reject) ->
        childProcess.exec(command, (error, stdout, stderr) ->
            reject(error) if (error)
            stdout = replaceEmDash stdout
            json = JSON.parse(stdout)
            resolve json
        )

module.exports = ->
    {
        poetryChain: -> runScript("./run_poetry_chain.sh")
        colocationNet: -> runScript("./run_colocation_net.sh")
        lineMaker: -> runScript("./run_lines.sh")
    }

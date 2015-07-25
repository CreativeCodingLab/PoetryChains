childProcess = require('child_process')
path = require("path")
Promise = require("promise")

module.exports = ->
    dir = path.resolve(__dirname, "PoetryChains")
    command = "cd " + dir + "; ./run_poetry_chain.sh"

    new Promise (resolve, reject) ->
        childProcess.exec(command, (error, stdout, stderr) ->
            reject(error) if (error)    
            json = JSON.parse(stdout)
            resolve(json)
        )

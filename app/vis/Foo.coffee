class Foo
  test: -> console.info "this is a test"

  another: ->
    Bar = require "./Bar"
    bar = new Bar()
    debugger

module.exports = Foo

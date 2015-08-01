{CompositeDisposable} = require 'atom'
RegexMatcherUtil = require('./RegexMatcherUtil')
TodoManager = require('./views/todo-manager')

module.exports =
  config:
    regexes:
      type: 'array'
      default: [{
          regexName: 'TODO',
          regexString: '/\\b@?TODO:?\\s(.+$)/g'
      }, {
        regexName: 'NOTE',
        regexString: '/\\b@?NOTE:?\\s(.+$)/g'
      }]
      items:
        type: 'object'
        properties:
          regexString:
            type: 'string'
          regexName:
            type: 'string'
    ignoredNames:
      type: 'array'
      default: [
        '*/node_modules/'
        '*/vendor/'
        '*/bower_components/'
      ]
      items:
        type: 'string'

  activate: ->
    @subscriptions = new CompositeDisposable()
    @todoPanes = []
    results = []

    @subscriptions.add(atom.commands.add('atom-workspace',
    'todo-manager:add': => @add())
    )

  add: ->
    if @bottomDock
      newTodoPane = new TodoManager()
      @todoPanes.push(newTodoPane)
      @bottomDock.addPane(newTodoPane, 'TODO')

  deactivate: ->
    @subscriptions.dispose()
    for pane in @todoPanes
      @bottomDock.deletePane(pane.getId())

  consumeBottomDock: (@bottomDock) ->
    @add()

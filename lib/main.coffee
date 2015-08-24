{CompositeDisposable} = require 'atom'
{BasicTabButton} = require 'atom-bottom-dock'
RegexMatcherUtil = require './regexMatcherUtil'
TodoManager = require './views/todo-manager'

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
        '**/node_modules/**'
        '**/vendor/**'
        '**/bower_components/**'
      ]
      items:
        type: 'string'

  activate: ->
    @subscriptions = new CompositeDisposable()
    @panes = []
    results = []

    packageFound = atom.packages.getAvailablePackageNames()
      .indexOf('bottom-dock') != -1

    unless packageFound
      atom.notifications.addError 'Could not find Bottom-Dock',
        detail: 'Todo-Manager: The bottom-dock package is a dependency. \n
        Learn more about bottom-dock here: https://atom.io/packages/bottom-dock'
        dismissable: true

    @subscriptions.add atom.commands.add 'atom-workspace',
      'todo-manager:add': => @add()

  add: ->
    return unless @bottomDock

    newPane = new TodoManager()
    @panes.push newPane

    @bottomDock.addPane newPane, 'TODO'

  deactivate: ->
    @subscriptions.dispose()
    @bottomDock.deletePane pane.getId() for pane in @panes

  consumeBottomDock: (@bottomDock) ->
    @subscriptions.add @bottomDock.onDidFinishResizing =>
      pane.resize() for pane in @panes
    @add()

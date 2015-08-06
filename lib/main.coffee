{CompositeDisposable} = require('atom')
{BasicTabButton} = require('atom-bottom-dock')
RegexMatcherUtil = require('./regexMatcherUtil')
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
        '**/node_modules/**'
        '**/vendor/**'
        '**/bower_components/**'
      ]
      items:
        type: 'string'

  activate: ->
    @subscriptions = new CompositeDisposable()
    @todoPanes = []
    results = []

    packageFound = atom.packages.getAvailablePackageNames()
      .indexOf('bottom-dock') != -1
    if not packageFound
      atom.notifications.addError('Could not find Bottom-Dock', {
        detail: 'Todo-Manager: The bottom-dock package is a dependency. \n
        Learn more about bottom-dock here: https://atom.io/packages/bottom-dock'
        dismissable: true
      })

    @subscriptions.add(atom.commands.add('atom-workspace',
    'todo-manager:add': => @add())
    )

  add: ->
    if @bottomDock
      newPane = new TodoManager()
      @todoPanes.push(newPane)

      config =
        name: 'TODO'
        id: newPane.getId()
        active: newPane.isActive()

      newTabButton = new BasicTabButton(config)

      @bottomDock.addPane(newPane, newTabButton)

  deactivate: ->
    @subscriptions.dispose()
    for pane in @todoPanes
      @bottomDock.deletePane(pane.getId())

  consumeBottomDock: (@bottomDock) ->
    @add()

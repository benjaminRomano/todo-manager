{View} = require('space-pen')


class TodoElement extends View
  @content: ({match}) ->
    @li class: 'todo-element', =>
      @span click: 'onClick', match.matchText

  initialize: ({@match}) ->

  onClick: =>
    @goToMatch(@match.filePath, @match.position)

  goToMatch: (filePath, position) ->
    atom.workspace.open(filePath, {
      initialLine: position[0]
      initialColumn: position[1]
      })

module.exports = TodoElement

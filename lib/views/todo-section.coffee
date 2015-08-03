{View, $} = require('space-pen')
TodoElement = require('./todo-element')


class TodoSection extends View
  @content: ({key, groupedMatches }) ->
    @div class: 'todo-section', =>
      @div =>
        @label class: 'todo-group-header highlight-info', key + ":"
      for subKey, matches of groupedMatches
        @label class: 'todo-sub-group-header highlight-success', subKey + ":"
        @ul outlet: 'matches', class: 'todo-element', =>
          for match in matches
            @subview 'todo-element', new TodoElement(match: match)

  initialize: () ->

  setActive: (active) ->
    if active
      @show()
    else
      @hide()

  destroy: ->
    for child in @matches.children()
      child = $(child).view()
      child.remove()

module.exports = TodoSection

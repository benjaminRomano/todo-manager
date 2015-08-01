{DockPaneView} = require('atom-bottom-dock')
{CompositeDisposable} = require('atom')
{$} = require('space-pen')
_ = require('lodash')

RegexMatcherUtil = require('../regexMatcherUtil')
TodoSection = require('./todo-section')

class TodoManager extends DockPaneView
  @content: ->
    @div class: 'todo-manager', =>
      @div outlet: 'filters', class: 'filters', =>
        @label class: 'filter-label', 'Search in:'
        @div outlet: 'fileFiltersContainer', class: 'btn-group', =>
          @button class: 'btn', click: 'getMatchesForAllFiles', 'All Files'
          @button class: 'btn', click: 'getMatchesForOpenFiles', 'Open Files'
          @button class: 'btn', click: 'getMatchesForCurrentFile', 'Current File'
        @label class: 'filter-label', 'Group by:'
        @div outlet: 'groupByFiltersContainer', class: 'btn-group', =>
          @button class: 'btn selected', click: 'groupByFile', 'File'
          @button class: 'btn', click: 'groupByRegex', 'Regex'
      @div outlet: 'todoSections', class: 'todo-sections', ->

  initialize: ->
    super()
    @regexMatcherUtil = new RegexMatcherUtil()

    @subscriptions = new CompositeDisposable()
    @subscriptions.add(atom.workspace.onDidAddTextEditor(@onPaneChanges))
    @subscriptions.add(atom.workspace.onDidDestroyPaneItem(@onPaneChanges))
    @subscriptions.add(atom.workspace.onDidChangeActivePaneItem(@onPaneChanges))

    @groupByFilter = 'File'
    @setActiveFilter(@groupByFiltersContainer, @groupByFilter)

    @getMatchesForOpenFiles()

  onPaneChanges: =>
    activeFileFilter = @getActiveFilter(@fileFiltersContainer)
    if activeFileFilter == 'Open Files'
      @getMatchesForOpenFiles()
    else if activeFileFilter == 'Current File'
      @getMatchesForCurrentFile()

  getMatchesForAllFiles: =>
    @setActiveFilter(@fileFiltersContainer, 'All Files')
    @matchingOptions = { paths: '*' }

    @getMatches(@matchingOptions)

  getMatchesForOpenFiles: =>
    @setActiveFilter(@fileFiltersContainer, 'Open Files')
    @matchingOptions = { fetchFromWorkspace: true }
    @getMatches(@matchingOptions)

  getMatchesForCurrentFile: =>
    @setActiveFilter(@fileFiltersContainer, 'Current File')
    @matchingOptions = { fetchFromWorkspace: true, currEditorOnly: true }
    @getMatches(@matchingOptions)

  setActiveFilter: (container, text) ->
    for child in container.children()
      child = $(child)
      if child.text() == text
        child.addClass('selected')
      else
        child.removeClass('selected')

  getActiveFilter: (container) ->
    for child in container.children()
      child = $(child)
      if child.hasClass('selected')
        return child.text()
    return null

  addMatches: (nestedGroupedMatches) =>
    @todoSections.empty()

    #value is another grouping
    for key, groupedMatches of nestedGroupedMatches
      todoSection = new TodoSection({ key, groupedMatches })
      @todoSections.append(todoSection)

  groupMatches: (matches) =>
    @matches = matches
    if not @groupByFilter
      @groupByFilter = 'File'
      @setActiveFilter(@groupByFiltersContainer, @groupByFilter)

    if @groupByFilter == 'File'
      groupedMatches = _.groupBy(matches, (match) -> return match.filePath)
      for filePath, matches of groupedMatches
        groupedMatches[filePath] = _.groupBy(matches, (match) -> return match.regexName)
      return groupedMatches
    else
      groupedMatches = _.groupBy(matches, (match) -> return match.regexName)
      for filePath, matches of groupedMatches
        groupedMatches[filePath] = _.groupBy(matches, (match) -> return match.filePath)
      return groupedMatches

  getMatches: (options) ->
    @todoSections.empty()

    regexes = atom.config.get('todo-manager.regexes')
    ignoredNames = atom.config.get('todo-manager.ignoredNames')
    globallyIgnoredNames = atom.config.get('core.ignoredNames')
    allIgnoredNames = ignoredNames.concat(globallyIgnoredNames)

    @regexMatcherUtil.getMatches(regexes, allIgnoredNames, options)
      .then(@groupMatches)
      .then(@addMatches)

  groupByFile: ->
    @groupByFilter = 'File'
    @setActiveFilter(@groupByFiltersContainer, @groupByFilter)
    @addMatches(@groupMatches(@matches)) if @matches

  groupByRegex: ->
    @groupByFilter = 'Regex'
    @setActiveFilter(@groupByFiltersContainer, @groupByFilter)
    @addMatches(@groupMatches(@matches)) if @matches


  refresh: ->
    @matchingOptions = @matchingOptions or { paths: '*'}
    @getMatches(@matchingOptions)

  destroy: ->
    @subscriptions.dispose if @subscriptions
    if @todoSections
      for todoSection in @todoSections.children()
        todoSection.destroy()
        todoSection.remove()
    @remove()

module.exports = TodoManager

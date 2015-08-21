{DockPaneView} = require 'atom-bottom-dock'
{CompositeDisposable} = require 'atom'
{$} = require 'space-pen'
_ = require 'lodash'

RegexMatcherUtil = require '../regexMatcherUtil'
TodoSection = require './todo-section'
FilterConstants = require '../filter-constants'


# TODO: Move filters to constants
class TodoManager extends DockPaneView
  @content: ->
    @div class: 'todo-manager', =>
      @div outlet: 'filters', class: 'filters', =>
        @label class: 'filter-label', 'Search in:'
        @div outlet: 'fileFiltersContainer', class: 'btn-group', =>
          @button class: 'btn', click: 'getMatchesForAllFiles', FilterConstants.file.allFiles
          @button class: 'btn', click: 'getMatchesForOpenFiles', FilterConstants.file.openFiles
          @button class: 'btn', click: 'getMatchesForCurrentFile', FilterConstants.file.currentFile
        @label class: 'filter-label', 'Group by:'
        @div outlet: 'groupByFiltersContainer', class: 'btn-group', =>
          @button class: 'btn selected', click: 'groupByFile', 'File'
          @button class: 'btn', click: 'groupByRegex', 'Regex'
      @div outlet: 'todoSectionsContainer', class: 'todo-sections-container', ->

  initialize: ->
    super()
    @regexMatcherUtil = new RegexMatcherUtil()

    @subscriptions = new CompositeDisposable()
    @subscriptions.add atom.workspace.onDidAddTextEditor @onPaneChanges
    @subscriptions.add atom.workspace.onDidDestroyPaneItem @onPaneChanges
    @subscriptions.add atom.workspace.onDidChangeActivePaneItem @onPaneChanges
    @subscriptions.add atom.workspace.onDidChangeActivePaneItem @onPaneChanges

    @getMatchesForOpenFiles()


  onPaneChanges: =>
    activeFileFilter = @getActiveFilter @fileFiltersContainer
    if activeFileFilter == FilterConstants.file.openFiles
      @getMatchesForOpenFiles()
    else if activeFileFilter == FilterConstants.file.currentFile
      @getMatchesForCurrentFile()

  getMatchesForAllFiles: =>
    @setActiveFilter @fileFiltersContainer, FilterConstants.file.allFiles
    @getMatches paths: '*'

  getMatchesForOpenFiles: =>
    @setActiveFilter @fileFiltersContainer, FilterConstants.file.openFiles
    @getMatches fetchFromWorkspace: true

  getMatchesForCurrentFile: =>
    @setActiveFilter @fileFiltersContainer, FilterConstants.file.currentFile
    @getMatches fetchFromWorkspace: true, currEditorOnly: true

  setActiveFilter: (container, text) ->
    for child in container.children()
      child = $(child)
      if child.text() == text
        child.addClass 'selected'
      else
        child.removeClass 'selected'

  getActiveFilter: (container) ->
    for child in container.children()
      child = $(child)
      if child.hasClass 'selected'
        return child.text()
    return null

  addMatches: (nestedGroupedMatches) =>
    @todoSectionsContainer.empty()

    #value is another grouping
    for key, groupedMatches of nestedGroupedMatches
      todoSection = new TodoSection {key, groupedMatches}
      @todoSectionsContainer.append todoSection

  groupMatches: (matches) =>
    @matches = matches
    groupByFilter = @getActiveFilter @groupByFiltersContainer
    if not groupByFilter
      @setActiveFilter @groupByFiltersContainer, FilterConstants.groupBy.file
      groupByFilter = FilterConstants.groupBy.file

    if groupByFilter == FilterConstants.groupBy.file
      groupedMatches = _.groupBy matches, (match) -> match.relativePath
      for filePath, matches of groupedMatches
        groupedMatches[filePath] = _.groupBy matches, (match) -> match.regexName
      return groupedMatches
    else
      groupedMatches = _.groupBy matches, (match) -> match.regexName
      for filePath, matches of groupedMatches
        groupedMatches[filePath] = _.groupBy matches, (match) -> match.relativePath
      return groupedMatches

  getMatches: (options) ->
    @todoSectionsContainer.empty()

    regexes = atom.config.get 'todo-manager.regexes'
    ignoredNames = atom.config.get 'todo-manager.ignoredNames'
    globallyIgnoredNames = atom.config.get 'core.ignoredNames'
    allIgnoredNames = ignoredNames.concat globallyIgnoredNames

    @regexMatcherUtil.getMatches(regexes, allIgnoredNames, options)
      .then(@groupMatches)
      .then(@addMatches)

  groupByFile: ->
    @setActiveFilter @groupByFiltersContainer, FilterConstants.groupBy.file
    @addMatches(@groupMatches(@matches)) if @matches

  groupByRegex: ->
    @setActiveFilter @groupByFiltersContainer, FilterConstants.groupBy.regex
    @addMatches(@groupMatches(@matches)) if @matches


  refresh: ->
    fileFilter = @getActiveFilter @fileFiltersContainer
    if fileFilter == FilterConstants.file.allFiles
      @getMatchesForAllFiles()
    else if fileFilter == FilterConstants.file.openFiles
      @getMatchesForOpenFiles()
    else if fileFilter == FilterConstants.file.currentFile
      @getMatchesForCurrentFile()
    else
      @getMatchesForOpenFiles()

  destroy: ->
    @subscriptions?.dispose
    if @todoSectionsContainer
      for todoSection in @todoSectionsContainer.children()
        todoSection = $(todoSection).view()
        todoSection.destroy()
        todoSection.remove()
    @remove()

module.exports = TodoManager

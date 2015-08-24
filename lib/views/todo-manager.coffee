{DockPaneView, TableView, Toolbar, FilterSelector} = require 'atom-bottom-dock'
{CompositeDisposable} = require 'atom'
{$} = require 'space-pen'
_ = require 'lodash'

RegexMatcherUtil = require '../regexMatcherUtil'
FilterConstants = require '../filter-constants'

class TodoManager extends DockPaneView
  @content: ->
    @div class: 'todo-manager', style: 'display:flex;', =>
      @subview 'toolbar', new Toolbar()

  initialize: ->
    super()
    @regexMatcherUtil = new RegexMatcherUtil()

    columns = [
      {id: "regex", name: "Regex", field: "regex", sortable: true }
      {id: "mesage", name: "Message", field: "message", sortable: true }
      {id: "path", name: "Path", field: "path", sortable: true }
      {id: "line", name: "Line", field: "line", sortable: true }
    ]

    @table = new TableView [], columns
    @append @table

    @table.onDidClickGridItem (row) =>
      @goToMatch row.match.filePath, row.match.position

    fileFiltersConfig =
      label: 'Search in:'
      activeFilter: FilterConstants.file.openFiles
      filters: [{
        value: FilterConstants.file.allFiles
      }, {
        value: FilterConstants.file.openFiles
      }, {
        value: FilterConstants.file.currentFile
      }]

    @fileFilterSelector = new FilterSelector fileFiltersConfig
    @fileFilterSelector.onDidChangeFilter => @refresh()
    @toolbar.addLeftTile item: @fileFilterSelector, priority: 0

    @subscriptions = new CompositeDisposable()
    @subscriptions.add atom.workspace.onDidAddTextEditor @onPaneChanges
    @subscriptions.add atom.workspace.onDidDestroyPaneItem @onPaneChanges
    @subscriptions.add atom.workspace.onDidChangeActivePaneItem @onPaneChanges
    @subscriptions.add atom.workspace.onDidChangeActivePaneItem @onPaneChanges

    @table.onDidFinishAttaching =>
      @getMatchesForOpenFiles()

  setActive: (active) ->
    super(active)
    @table?.resize(true) if active

  resize: ->
    @table.resize(true)

  onPaneChanges: =>
    activeFileFilter = @fileFilterSelector.getActiveFilter()
    if activeFileFilter == FilterConstants.file.openFiles
      @getMatchesForOpenFiles()
    else if activeFileFilter == FilterConstants.file.currentFile
      @getMatchesForCurrentFile()

  getMatchesForAllFiles: =>
    @fileFilterSelector.setActiveFilter FilterConstants.file.allFiles
    @getMatches paths: '*'

  getMatchesForOpenFiles: =>
    @fileFilterSelector.setActiveFilter FilterConstants.file.openFiles
    @getMatches fetchFromWorkspace: true

  getMatchesForCurrentFile: =>
    @fileFilterSelector.setActiveFilter FilterConstants.file.currentFile
    @getMatches fetchFromWorkspace: true, currEditorOnly: true

  addMatches: (matches) =>
    @table.deleteAllRows()

    data = []
    for match in matches
      data.push
        regex: match.regexName
        message: match.matchText
        path: match.relativePath
        line: match.position[0]
        match: match

    @table.addRows data

  goToMatch: (filePath, position) ->
    atom.workspace.open filePath,
      initialLine: position[0]
      initialColumn: position[1]

  getMatches: (options) ->
    @table.deleteAllRows()

    regexes = atom.config.get 'todo-manager.regexes'
    ignoredNames = atom.config.get 'todo-manager.ignoredNames'
    globallyIgnoredNames = atom.config.get 'core.ignoredNames'
    allIgnoredNames = ignoredNames.concat globallyIgnoredNames

    @regexMatcherUtil.getMatches(regexes, allIgnoredNames, options)
      .then(@addMatches)

  refresh: =>
    fileFilter = @fileFilterSelector.getActiveFilter()
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
    @remove()

module.exports = TodoManager

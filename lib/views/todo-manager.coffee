{DockPaneView, SortableTable, Toolbar, FilterSelector} = require 'atom-bottom-dock'
{CompositeDisposable} = require 'atom'
{$} = require 'space-pen'
_ = require 'lodash'

RegexMatcherUtil = require '../regexMatcherUtil'
FilterConstants = require '../filter-constants'

class TodoManager extends DockPaneView
  @content: ->
    @div class: 'todo-manager', style: 'display:flex;', =>
      @subview 'toolbar', new Toolbar()
      @subview 'todoTable', new SortableTable headers: ['Regex', 'Message', 'Path', 'Line']

  initialize: ->
    super()
    @regexMatcherUtil = new RegexMatcherUtil()

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

    @getMatchesForOpenFiles()

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
    @todoTable.body.empty()

    for match in matches
      row = $("<tr>
        <td>#{match.regexName}</td>
        <td>#{match.matchText}</td>
        <td>#{match.relativePath}</td>
        <td>#{match.position[0]}</td>
      </tr>")

      do (match) =>
        row.on 'click', =>
          @goToMatch match.filePath, match.position

      @todoTable.body.append row

    @todoTable.body.trigger 'update'

  goToMatch: (filePath, position) ->
    atom.workspace.open filePath,
      initialLine: position[0]
      initialColumn: position[1]

  getMatches: (options) ->
    @todoTable.body.empty()

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

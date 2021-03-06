minimatch = require 'minimatch'
path = require 'path'

class RegexMatcherUtil
  constructor: () ->

  # match {matchText, range}
  # newMatch: { matchText, regexName, filePath, relativeFilePath, position}
  cleanUpMatch: (match, filePath, regexName, regex) ->
    matchText = match.matchText.replace(/(\*\/|\?>|-->|#>|-}|\]\])\s*$/, '').trim()

    newMatch =
      matchText: matchText
      regexName: regexName
      filePath: filePath
      relativePath: @getRelativePath filePath
      position: match.range[0]

    return newMatch

  getRelativePath: (filePath) ->
    [projectPath, relativePath] = atom.project.relativizePath filePath

    unless atom.project.getPaths().length > 1 and projectPath
      return relativePath

    dirs = projectPath.split path.sep
    return path.join(dirs[dirs.length - 1], relativePath)

  # {regexString, regexName}
  getMatches: (regexes, ignoredNames, options) ->
    options = options or paths: '*'
    searchPromises = []

    for regex in regexes
      regExp = @makeRegexObj regex.regexString
      continue unless regExp
      if options.fetchFromWorkspace
        searchPromises.push(@fetchFromWorkspace(regExp, regex.regexName, ignoredNames, options))
      else
        searchPromises.push(@fetchRegexItem(regExp, regex.regexName, ignoredNames, options))

    return Promise.resolve [] unless searchPromises.length

    Promise.all(searchPromises).then((searchResults) ->
      searchResults.reduce((a, b) -> return a.concat b)
    )

  makeRegexObj: (regexString) ->
    pattern = regexString.match(/\/(.+)\//)?[1]
    flags = regexString.match(/\/(\w+$)/)?[1]
    return null unless pattern
    new RegExp pattern, flags

  fetchRegexItem: (regex, regexName, ignoredNames, options) ->
    ignoredNames = ignoredNames or []

    searchResults = []
    promise = atom.workspace.scan(regex, options, (matchesForFile, error) =>
      return unless matchesForFile
      return if @isIgnored matchesForFile.filePath, ignoredNames

      for match in matchesForFile.matches
        cleanedUpMatch = @cleanUpMatch match, matchesForFile.filePath, regexName, regex
        searchResults.push cleanedUpMatch
    )

    promise.then -> searchResults

  fetchFromWorkspace: (regex, regexName, ignoredNames, options) ->
    currEditorOnly = !!options?.currEditorOnly

    editors = []
    if currEditorOnly
      activeTextEditor = atom.workspace.getActiveTextEditor()
      editors = [].concat activeTextEditor  if activeTextEditor
    else
      editors = atom.workspace.getTextEditors()

    searchResults = []
    for editor in editors
      editor.scan regex, (match, error) =>
        return unless match
        return if @isIgnored editor.getPath(), ignoredNames

        basicMatch =
          matchText: match.matchText,
          range: match.range.serialize()

        cleanedUpMatch = @cleanUpMatch basicMatch, editor.getPath(), regexName, regex
        searchResults.push cleanedUpMatch
    console.log('all good')
    return new Promise((resolve, reject) => resolve(searchResults))
    # deferred.resolve searchResults
    # deferred.promise

  isIgnored: (path, ignoredNames) ->
    return true unless path

    for ignoredName in ignoredNames
      isAMatch = minimatch path, ignoredName, matchBase: true, dot: true
      return true if isAMatch
    return false

module.exports = RegexMatcherUtil

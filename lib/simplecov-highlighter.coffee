SimplecovHighlighterView = require './simplecov-highlighter-view'
{CompositeDisposable} = require 'atom'

module.exports = SimplecovHighlighter =
  simplecovHighlighterView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    @simplecovHighlighterView = new SimplecovHighlighterView(state.simplecovHighlighterViewState)
    #@modalPanel = atom.workspace.addModalPanel(item: @simplecovHighlighterView.getElement(), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'simplecov-highlighter:toggle': => @toggle()

    # Own stuff
    @coverageMarkers = []
    @coverageData = {}
    @showingCoverage
    @decorations = []

    atom.workspace.observeTextEditors(@.loadAndProcessCoverageForEditor.bind(@))
    @coveragePanel = atom.workspace.addBottomPanel(item: @simplecovHighlighterView.getElement(), visible: true)

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @simplecovHighlighterView.destroy()

  serialize: ->
    simplecovHighlighterViewState: @simplecovHighlighterView.serialize()

  toggle: ->
    if @showingCoverage
      decoration.destroy() for decoration in @decorations
      @decorations = []
      @coveragePanel.hide()
    else
      @.decorateEditorMarkers(editor) for editor in atom.workspace.getTextEditors()
      @coveragePanel.show()
    @showingCoverage = not @showingCoverage

  loadAndProcessCoverageForEditor: (editor) ->
    @editor = editor
    openDirectories = atom.project.getDirectories()
    currentFilePath = editor.getPath()
    console.log(currentFilePath)
    currentProjectDirectory = dir for dir in openDirectories when currentFilePath.match(dir.getPath())

    return if currentProjectDirectory == undefined

    coverageDirectory = currentProjectDirectory.getSubdirectory('coverage')
    if coverageDirectory.existsSync()
      fs = require 'fs'
      fs.readFile (coverageDirectory.getPath() + '/.resultset.json'), @.parseAndProcessCoverage.bind(@)

  parseAndProcessCoverage: (err, data) ->
    coverageObject = JSON.parse(data)
    editorMarkers = @.processEditorCoverage(@editor, coverageObject)
    @coverageData[@editor.getPath()] = editorMarkers
    @.decorateEditorMarkers(editor) for editor in atom.workspace.getTextEditors() if @showingCoverage

  processEditorCoverage: (editor, coverageObject) ->
    editorPath = editor.getPath()
    directoryCoverage = coverageObject.RSpec.coverage
    directoryLineCoverage = directoryCoverage[editorPath]

    return if directoryLineCoverage == null || directoryLineCoverage == undefined

    editorMarkers = []

    line = 0
    for lineHits in directoryLineCoverage
      range = [[line, 0], [line, 1]]
      editorMarkers.push [editor.markBufferRange(range), lineHits]
      line += 1

    return editorMarkers

  decorateEditorMarkers: (editor) ->
    editorCoverageData = @coverageData[editor.getPath()]

    if editorCoverageData != undefined
      for [marker, lineHits] in editorCoverageData
        console.log marker
        console.log lineHits

        if lineHits != null
          if lineHits > 0
            decoration = editor.decorateMarker(marker, type: 'line', class: "coverage-hit")
          else
            decoration = editor.decorateMarker(marker, type: 'line', class: "coverage-missed")
          @decorations.push decoration

  showMessage: (message) ->
    messageContainer = document.createElement('div')
    messageContainer.textContent = message
    messagePanel = atom.workspace.addModalPanel(item: messageContainer, visible: false)
    messagePanel.show()
    setTimeout (-> messagePanel.destroy()), 2000

  coverageInfoContext: ->
    editor = atom.workspace.getActiveTextEditor()
    editorCoverageData = @coverageData[editor.getPath()]

    coverageInfo = document.createElement('div')

    if editorCoverageData != undefined
      coverageInfo.textContent = "Coverage showing"
    else
      coverageInfo.textContent = "No coverage data found for current file."

    return coverageInfo

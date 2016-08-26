SimplecovHighlighterView = require './simplecov-highlighter-view'
{CompositeDisposable} = require 'atom'

module.exports = SimplecovHighlighter =
  simplecovHighlighterView: null
  subscriptions: null

  activate: (state) ->
    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'simplecov-highlighter:toggle': => @toggle()

    @coverageMarkers = []
    @showingCoverage
    @decorations = []
    @coverageFilePaths = []

    @simplecovHighlighterView = new SimplecovHighlighterView(state.simplecovHighlighterViewState)
    @coveragePanel = atom.workspace.addBottomPanel(item: @simplecovHighlighterView.getElement(), visible: true)

    atom.workspace.observeActivePaneItem(@loadAndProcessCoverage.bind(@))

  deactivate: ->
    @subscriptions.dispose()
    @simplecovHighlighterView.destroy()

  serialize: ->
    simplecovHighlighterViewState: @simplecovHighlighterView.serialize()

  toggle: ->
    if this.showingCoverage
      marker.destroy() for marker in @coverageMarkers
      @coverageMarkers = []
      @coveragePanel.hide()
    else
      @markAndDecorateEditor(this.coverageObject)
      @coveragePanel.show()

    @showingCoverage = !this.showingCoverage

  loadAndProcessCoverage: (item) ->
    for currentProjectDirectory in atom.project.getDirectories()
      coverageDirectory = currentProjectDirectory.getSubdirectory('coverage')

      if coverageDirectory.existsSync()
        fs = require 'fs'
        coverageFilePath = coverageDirectory.getPath() + '/.resultset.json'

        fs.readFile(coverageFilePath, @parseAndProcessCoverage.bind(@))

        if coverageFilePath not in @coverageFilePaths
          @coverageFilePaths.push coverageFilePath
          that = @
          fs.watch(coverageFilePath, @loadAndProcessCoverage.bind(@))

  parseAndProcessCoverage: (err, data) ->
    if @coverageObject
      @coverageObject = MergeRecursive(@coverageObject, JSON.parse(data))
    else
      @coverageObject = JSON.parse(data)

    @markAndDecorateEditor(this.coverageObject) if @showingCoverage

  markAndDecorateEditor: (coverageObject) ->
    editor = atom.workspace.getActiveTextEditor()

    try
      lineCoverage = coverageObject.RSpec.coverage[editor.getPath()]
    catch error
      @simplecovHighlighterView.showNoCoverageData()

    if lineCoverage
      [hitMarkers, missedMarkers] = @markEditor(lineCoverage, editor)

      editor.decorateMarker(marker, type: 'line', class: "coverage-hit") for marker in hitMarkers
      editor.decorateMarker(marker, type: 'line', class: "coverage-missed") for marker in missedMarkers

      marker.destroy() for marker in @coverageMarkers
      @coverageMarkers = []
      #destroy old and push new markers
      @coverageMarkers.push marker for marker in hitMarkers
      @coverageMarkers.push marker for marker in missedMarkers

      @simplecovHighlighterView.showCoverageInfo(lineCoverage)

  markEditor: (lineCoverage, editor) ->
    hitMarkers = []
    missedMarkers = []

    line = 0
    for lineHits in lineCoverage
      range = [[line, 0], [line, 1]]
      if lineHits != null
        if lineHits == 0
          missedMarkers.push editor.markBufferRange(range)
        else
          hitMarkers.push editor.markBufferRange(range)
      line += 1

    return [hitMarkers, missedMarkers]


MergeRecursive = (obj1, obj2) ->
  for p of obj2
    try
      # Property in destination object set; update its value.
      if obj2[p].constructor == Object
        obj1[p] = MergeRecursive(obj1[p], obj2[p])
      else
        obj1[p] = obj2[p]
    catch e
      # Property in destination object not set; create it and set its value.
      obj1[p] = obj2[p]
  debugger;
  obj1

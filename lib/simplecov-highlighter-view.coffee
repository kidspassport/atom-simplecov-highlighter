module.exports =
class SimplecovHighlighterView
  constructor: (serializedState) ->
    # Create root element
    @element = document.createElement('div')
    @element.classList.add('simplecov-highlighter-status')

    # Create message element
    message = document.createElement('div')
    message.textContent = "100% Coverage."
    message.classList.add('green')

    @element.appendChild(message)

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @element.remove()

  getElement: ->
    @element

  showCoverageInfo: (lineCoverage) ->
    if !lineCoverage
      @showNoCoverageData()
      return

    editor = atom.workspace.getActiveTextEditor()

    # Create message element
    message = document.createElement('div')

    totalLines = lineCoverage.filter((count) -> count != null)
    hitLines = totalLines.filter((count) -> count > 0)

    if totalLines.length == 0
      percentCoverage = 100
    else
      percentCoverage = ((hitLines.length / totalLines.length * 10000)|0)/100
    message.textContent = "" + percentCoverage + "% coverage"

    if percentCoverage > 90
      message.classList.add('green')
    else if percentCoverage > 80
      message.classList.add('yellow')
    else
      message.classList.add('red')

    @clearContent()
    @getElement().appendChild(message)

  showNoCoverageData: ->
    @clearContent()
    message = document.createElement('div')
    message.textContent = "No coverage data found for current file"
    @getElement().appendChild(message)

  clearContent: ->
    while (@getElement().hasChildNodes())
      @getElement().removeChild(@getElement().lastChild)

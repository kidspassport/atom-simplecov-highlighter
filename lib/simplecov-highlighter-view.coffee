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

{CompositeDisposable} = require 'atom'
{View} = require 'atom-space-pen-views'
_ = require 'underscore-plus'
Grim = require 'grim'

module.exports =
class DeprecationCopStatusBarView extends View
  @content: ->
    @div class: 'deprecation-cop-status inline-block text-warning', tabindex: -1, =>
      @span class: 'icon icon-alert'
      @span class: 'deprecation-number', outlet: 'deprecationNumber', '0'

  lastLength: null
  toolTipDisposable: null

  initialize: ->
    debouncedUpdateDeprecatedSelectorCount = _.debounce(@update, 1000)

    @subscriptions = new CompositeDisposable
    @subscriptions.add Grim.on 'updated', @update
    @subscriptions.add(atom.styles.onDidUpdateDeprecations(debouncedUpdateDeprecatedSelectorCount))

  destroy: ->
    @subscriptions.dispose()
    @detach()

  attached: ->
    @update()
    @click ->
      workspaceElement = atom.views.getView(atom.workspace)
      atom.commands.dispatch workspaceElement, 'deprecation-cop:view'

  getDeprecatedCallCount: ->
    Grim.getDeprecations().map((d) -> d.getStackCount()).reduce(((a, b) -> a + b), 0)

  update: =>
    length = @getDeprecatedCallCount() + Object.keys(atom.styles.getDeprecations()).length

    return if @lastLength is length

    @lastLength = length
    @deprecationNumber.text("#{_.pluralize(length, 'deprecation')}")
    @toolTipDisposable?.dispose()
    @toolTipDisposable = atom.tooltips.add @element, title: "#{_.pluralize(length, 'call')} to deprecated methods"

    if length is 0
      @hide()
    else
      @show()

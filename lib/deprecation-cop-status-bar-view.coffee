{CompositeDisposable} = require 'atom'
{$, $$, View} = require 'atom-space-pen-views'
_ = require 'underscore-plus'
Grim = require 'grim'

{getSelectorDeprecations, getSelectorDeprecationsCount} = require './helpers'

module.exports =
class DeprecationCopStatusBarView extends View
  @content: ->
    @div class: 'deprecation-cop-status inline-block text-warning', tabindex: -1, =>
      @span class: 'icon icon-alert'
      @span class: 'deprecation-number', outlet: 'deprecationNumber', '0'

  lastLength: null
  toolTipDisposable: null

  initialize: ->
    @debouncedUpdateDeprecatedSelectorCount = _.debounce(@updateDeprecatedSelectorCount, 1000)

    @subscriptions = new CompositeDisposable
    @subscriptions.add Grim.on 'updated', @update
    @subscriptions.add atom.packages.onDidLoadPackage @debouncedUpdateDeprecatedSelectorCount
    @subscriptions.add atom.packages.onDidUnloadPackage @debouncedUpdateDeprecatedSelectorCount
    @subscriptions.add atom.packages.onDidActivatePackage @debouncedUpdateDeprecatedSelectorCount

    @subscriptions.add atom.keymaps.onDidReloadKeymap (event) =>
      @debouncedUpdateDeprecatedSelectorCount() if event.path is atom.keymaps.getUserKeymapPath()

    userStylesheetPath = atom.styles.getUserStyleSheetPath()
    stylesChanged = (element) =>
      @debouncedUpdateDeprecatedSelectorCount() if element.getAttribute('source-path') is userStylesheetPath
    @subscriptions.add atom.styles.onDidUpdateStyleElement(stylesChanged)
    @subscriptions.add atom.styles.onDidAddStyleElement(stylesChanged)

    @hide()

  destroy: ->
    @subscriptions.dispose()
    @detach()

  attached: ->
    @debouncedUpdateDeprecatedSelectorCount()
    @click ->
      workspaceElement = atom.views.getView(atom.workspace)
      atom.commands.dispatch workspaceElement, 'deprecation-cop:view'

  getDeprecatedSelectorCount: ->
    @deprecatedSelectorCount ?= getSelectorDeprecationsCount()

  getDeprecatedCallCount: ->
    Grim.getDeprecations().map((d) -> d.getStackCount()).reduce(((a, b) -> a + b), 0)

  updateDeprecatedSelectorCount: =>
    @deprecatedSelectorCount = null
    @update()

  update: =>
    length = @getDeprecatedCallCount() + @getDeprecatedSelectorCount()

    return if @lastLength is length

    @lastLength = length
    @deprecationNumber.text("#{_.pluralize(length, 'deprecation')}")
    @toolTipDisposable?.dispose()
    @toolTipDisposable = atom.tooltips.add @element, title: "#{_.pluralize(length, 'call')} to deprecated methods"

    if length is 0
      @hide()
    else
      @show()

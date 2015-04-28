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
    @subscriptions = new CompositeDisposable
    @subscriptions.add Grim.on 'updated', @update
    @subscriptions.add atom.packages.onDidLoadPackage @updateDeprecatedSelectorCount
    @subscriptions.add atom.packages.onDidUnloadPackage @updateDeprecatedSelectorCount
    @subscriptions.add atom.packages.onDidActivatePackage @updateDeprecatedSelectorCount

  destroy: ->
    @subscriptions.dispose()
    @detach()

  attached: ->
    @update()
    @click ->
      workspaceElement = atom.views.getView(atom.workspace)
      atom.commands.dispatch workspaceElement, 'deprecation-cop:view'

  getDeprecatedSelectorCount: ->
    @deprecatedSelectorCount ?= getSelectorDeprecationsCount()
  
  getDeprecatedCallCount: ->
    Grim.getDeprecations().map((d) -> d.getStacks().length).reduce(((a, b) -> a + b), 0)

  updateDeprecatedSelectorCount: =>
    @deprecatedSelectorCount = null
    @update()

  update: =>
    length = @getDeprecatedCallCount() + @getDeprecatedSelectorCount()

    return if @lastLength == length

    @lastLength = length
    @deprecationNumber.text(length)
    @toolTipDisposable?.dispose()
    @toolTipDisposable = atom.tooltips.add @element, title: "#{_.pluralize(length, 'call')} to deprecated methods"

    if length == 0
      @hide()
    else
      @show()

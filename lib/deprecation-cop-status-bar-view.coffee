{$, $$, View} = require 'atom'
_ = require 'underscore-plus'
Grim = require 'grim'

module.exports =
class DeprecationCopStatusBarView extends View
  @content: ->
    @div class: 'deprecation-cop-status inline-block text-warning', tabindex: -1, =>
      @span class: 'icon icon-alert'
      @span class: 'deprecation-number', outlet: 'deprecationNumber', '0'

  lastLength: null

  initialize: ->
    @subscribe Grim, 'updated', @update

  destroy: ->
    @detach()

  afterAttach: ->
    @update()
    @subscribe this, 'click', => atom.workspaceView.trigger 'deprecation-cop:view'

  update: =>
    length = Grim.getDeprecationsLength()
    return if lastLength == length

    lastLength = length
    @deprecationNumber.text(length)
    @destroyTooltip()
    @setTooltip("#{_.pluralize(length, 'call')} to deprecated methods")

    if length == 0
      @hide()
    else
      @show()

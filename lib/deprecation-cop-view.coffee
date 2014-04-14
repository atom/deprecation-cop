{$, $$, ScrollView} = require 'atom'
Grim = require 'grim'

module.exports =
class DeprecationCopView extends ScrollView
  @content: ->
    @div class: 'deprecation-cop pane-item', tabindex: -1, =>
      @div class: 'tool-panel padded', =>
        @div class: 'panel-heading', "Deprecated calls"
        @ul outlet: 'deprecationList'


  constructor: ({@uri}) ->
    @update()

  destroy: ->
    @detach()

  getUri: ->
    @uri

  getTitle: ->
    'Deprecation Cop'

  update: ->
    console.log Grim.getLog()
    for method, {count, message, stackTraces} of Grim.getLog()
      @list.append $$ ->
        @li class: 'inset-panel', =>
          @div class: 'panel-heading', method
          @div class: 'block', "Called #{count} time(s)"
          @div class: 'block', message
          for stackTrace in stackTraces
            @div class: 'block', stackTrace

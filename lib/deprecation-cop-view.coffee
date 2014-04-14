{$, $$, ScrollView} = require 'atom'
Grim = require 'grim'

module.exports =
class DeprecationCopView extends ScrollView
  @content: ->
    @div class: 'deprecation-cop pane-item', tabindex: -1, =>
      @div class: 'panel', =>
        @div class: 'panel-heading', "Deprecated calls"
        @ul outlet: 'list', class: 'list-tree has-collapsable-children padded'

  initialize: ({@uri}) ->
    @update()
    @on 'click', '.list-nested-item', -> $(this).toggleClass('collapsed')

  destroy: ->
    @detach()

  getUri: ->
    @uri

  getTitle: ->
    'Deprecation Cop'

  update: ->
    methodList = []
    methodList.push [method, metadata] for method, metadata of Grim.getLog()
    methodList.sort (a, b) -> b[1].count - a[1].count

    for [method, {count, message, stackTraces}] in methodList
      @list.append $$ ->
        @li class: 'list-nested-item collapsed', =>
          @div class: 'list-item', =>
            @span class: 'text-highlight', method
            @span " (called #{count} times)"

          @ul class: 'list', =>
            for stackTrace in stackTraces
              @li class: 'list-item stack-trace', =>
                @span class: 'icon icon-alert'
                @span stackTrace.split("\n")[3].replace(/^\s*at\s*/, '')
                @pre stackTrace

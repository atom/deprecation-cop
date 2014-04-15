{$, $$, ScrollView} = require 'atom'
path = require 'path'
fs = require 'fs-plus'
Grim = require 'grim'

module.exports =
class DeprecationCopView extends ScrollView
  @content: ->
    @div class: 'deprecation-cop pane-item', tabindex: -1, =>
      @div class: 'panel', =>
        @div class: 'panel-heading', =>
          @div class: 'btn-toolbar pull-right', =>
            @div class: 'btn-group', =>
              @button outlet: 'refreshButton', class: 'btn refresh', 'Refresh'
          @span "Deprecated calls"
        @ul outlet: 'list', class: 'list-tree has-collapsable-children padded'

  initialize: ({@uri}) ->
    @update()
    @subscribe this, 'click', '.list-nested-item', -> $(this).toggleClass('collapsed')
    @subscribe Grim, 'updated', => @refreshButton.show()
    @refreshButton.click => @update()

  destroy: ->
    @detach()

  getUri: ->
    @uri

  getTitle: ->
    'Deprecation Cop'

  getPackagePathsByPackageName: ->
    return @packagePathsByPackageName if @packagePathsByPackageName?

    @packagePathsByPackageName = {}
    for {name} in atom.packages.getLoadedPackages()
      @packagePathsByPackageName[name] = atom.packages.resolvePackagePath(name)

    @packagePathsByPackageName

  getPackageName: (stack) ->
    resourcePath = atom.getLoadSettings().resourcePath
    for callsite in stack
      filePath = callsite.getFileName()

      for packageName, packagePath of @getPackagePathsByPackageName()
        relativePath = path.relative(packagePath, filePath)
        unless /^\.\./.test(relativePath)
          return packageName

    null

  formatStack: (stack) ->
    @defaultError ?= new Error("Deprecation Error")
    Error.prepareStackTrace(@defaultError, stack)

  update: ->
    @refreshButton.hide()
    methodList = []
    methodList.push [method, metadata] for method, metadata of Grim.getLog()
    methodList.sort (a, b) -> b[1].count - a[1].count

    self = this
    @list.empty()
    for [method, {count, message, stacks}] in methodList
      @list.append $$ ->
        @li class: 'list-nested-item collapsed', =>
          @div class: 'list-item', =>
            @span class: 'text-highlight', method
            @span " (called #{count} times)"

          @ul class: 'list', =>
            @li message
            for stack in stacks
              @li class: 'list-item stack-trace', =>
                @span class: 'icon icon-alert'
                if self.getPackageName(stack)
                  @span self.getPackageName(stack) + " package"
                else
                  "atom core"
                @pre class: 'stack-trace', self.formatStack(stack)

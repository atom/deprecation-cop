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
        @ul outlet: 'list', class: 'list-tree has-collapsable-children'

  initialize: ({@uri}) ->
    @update()

    @subscribe Grim, 'updated', =>
      @refreshButton.show()

    @subscribe @refreshButton, 'click', =>
      @update()

    @subscribe this, 'click', '.deprecation-info', ->
      $(this).parent().toggleClass('collapsed')

    @subscribe this, 'click', '.stack-line-location', ->
      atom.open pathsToOpen: [this.href.replace('file://', '')]

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
    for {functionName, location, fileName} in stack
      for packageName, packagePath of @getPackagePathsByPackageName()
        relativePath = path.relative(packagePath, fileName)
        unless /^\.\./.test(relativePath)
          return packageName

    null

  update: ->
    @refreshButton.hide()
    deprecations = Grim.getDeprecations()
    deprecations.sort (a, b) -> b.getCallCount() - a.getCallCount()
    @list.empty()

    if deprecations.length == 0
      @list.append $$ ->
        @li class: 'list-item', "No deprecated calls"
    else
      self = this
      for deprecation in deprecations
        @list.append $$ ->
          @li class: 'deprecation list-nested-item collapsed', =>
            @div class: 'deprecation-info list-item', =>
              @span class: 'text-highlight', deprecation.getOriginName()
              @span " (called #{deprecation.getCallCount()} times)"

            @ul class: 'list', =>
              @li class: 'list-item', =>
                @div class: 'list-item text-success', deprecation.getMessage()

              stacks = deprecation.getStacks()
              stacks.sort (a, b) -> b.callCount - a.callCount
              for stack in stacks
                @li class: 'list-item', =>
                  @span class: 'icon icon-alert'
                  if self.getPackageName(stack)
                    @span self.getPackageName(stack) + " package (called #{stack.callCount} times)"
                  else
                    @span "atom core"  + " (called #{stack.callCount} times)"
                  @div class: 'stack-trace', =>
                    for {functionName, location, fileName} in stack
                      @div class: 'stack-line', =>
                        @span functionName
                        @span " - "
                        @a class:'stack-line-location', href:location, location

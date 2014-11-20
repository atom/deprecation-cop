{$, $$, ScrollView} = require 'atom'
path = require 'path'
fs = require 'fs'
_ = require 'underscore-plus'
fs = require 'fs-plus'
Grim = require 'grim'
SelectorLinter = require 'atom-selector-linter'
marked = require 'marked'

module.exports =
class DeprecationCopView extends ScrollView
  @content: ->
    @div class: 'deprecation-cop pane-item native-key-bindings', tabindex: -1, =>
      @div class: 'panel', =>
        @div class: 'panel-heading', =>
          @div class: 'btn-toolbar pull-right', =>
            @div class: 'btn-group', =>
              @button outlet: 'refreshCallsButton', class: 'btn refresh', 'Refresh'
          @span "Deprecated calls"
        @ul outlet: 'list', class: 'list-tree has-collapsable-children'

        @div class: 'panel-heading', =>
          @div class: 'btn-toolbar pull-right', =>
            @div class: 'btn-group', =>
              @button outlet: 'refreshSelectorsButton', class: 'btn refresh-selectors', 'Refresh'
          @span "Deprecated selectors"
        @ul outlet: 'selectorList', class: 'selectors list-tree has-collapsable-children'

  initialize: ({@uri}) ->
    @subscribe Grim, 'updated', =>
      @refreshCallsButton.show()

    @subscribe atom.packages.onDidActivateAll =>
      @refreshSelectorsButton.show()

  afterAttach: ->
    @updateCalls()
    @updateSelectors()
    @subscribeToEvents()

  subscribeToEvents: ->
    # afterAttach is called 2x when dep cop is the active pane item on reload.
    return if @subscribedToEvents

    @subscribe @refreshCallsButton, 'click', =>
      @updateCalls()
    @subscribe @refreshSelectorsButton, 'click', =>
      @updateSelectors()

    @subscribe this, 'click', '.deprecation-info', ->
      $(this).parent().toggleClass('collapsed')

    @subscribe this, 'click', '.stack-line-location, .source-file a', ->
      pathToOpen = @href.replace('file://', '')
      pathToOpen = pathToOpen.replace(/^\//, '') if process.platform is 'win32'
      atom.open(pathsToOpen: [pathToOpen])

    @subscribedToEvents = true

  destroy: ->
    @detach()

  serialize: ->
    deserializer: @constructor.name
    uri: @getUri()

  getUri: ->
    @uri

  getTitle: ->
    'Deprecation Cop'

  getIconName: ->
    'alert'

  getPackagePathsByPackageName: ->
    return @packagePathsByPackageName if @packagePathsByPackageName?

    @packagePathsByPackageName = {}
    for pack in atom.packages.getLoadedPackages()
      @packagePathsByPackageName[pack.name] = pack.path

    @packagePathsByPackageName

  getPackageName: (stack) ->
    resourcePath = atom.getLoadSettings().resourcePath

    packagePaths = @getPackagePathsByPackageName()
    for packageName, packagePath of packagePaths
      if packagePath.indexOf('.atom/dev/packages') > -1 or packagePath.indexOf('.atom/packages') > -1
        packagePaths[packageName] = fs.realpathSync(packagePath)

    for i in [1...stack.length]
      {functionName, location, fileName} = stack[i]

      # Empty when it was run from the dev console
      return unless fileName

      for packageName, packagePath of packagePaths
        relativePath = path.relative(packagePath, fileName)
        return packageName unless /^\.\./.test(relativePath)
    return

  createIssueUrl: (packageName, deprecation, stack) ->
    return unless repo = atom.packages.getActivePackage(packageName)?.metadata?.repository
    repoUrl = repo.url ? repo
    repoUrl = repoUrl.replace(/\.git$/, '')

    title = "#{deprecation.getOriginName()} is deprecated."
    stacktrace = stack.map(({functionName, location}) -> "#{functionName} (#{location})").join("\n")
    body = "#{deprecation.getMessage()}\n```\n#{stacktrace}\n```"
    "#{repoUrl}/issues/new?title=#{encodeURI(title)}&body=#{encodeURI(body)}"

  updateCalls: ->
    @refreshCallsButton.hide()
    deprecations = Grim.getDeprecations()
    deprecations.sort (a, b) -> b.getCallCount() - a.getCallCount()
    @list.empty()

    packageDeprecations = {}
    for deprecation in deprecations
      stacks = deprecation.getStacks()
      stacks.sort (a, b) -> b.callCount - a.callCount
      for stack in stacks
        packageName = (@getPackageName(stack) or '').toLowerCase()
        packageDeprecations[packageName] ?= []
        packageDeprecations[packageName].push {deprecation, stack}

    # I feel guilty about this nested code catastrophe
    if deprecations.length == 0
      @list.append $$ ->
        @li class: 'list-item', "No deprecated calls"
    else
      self = this
      packageNames = _.keys(packageDeprecations)
      packageNames.sort()
      for packageName in packageNames
        @list.append $$ ->
          @li class: 'deprecation list-nested-item collapsed', =>
            @div class: 'deprecation-info list-item', =>
              @span class: 'text-highlight', packageName or 'atom core'
              @span " (#{_.pluralize(packageDeprecations[packageName].length, 'deprecation')})"

            @ul class: 'list', =>
              for {deprecation, stack} in packageDeprecations[packageName]
                @li class: 'list-item deprecation-detail', =>
                  @span class: 'text-warning icon icon-alert'
                  @div class: 'list-item deprecation-message', =>
                    @raw marked(deprecation.getMessage())

                  @div class: 'btn-toolbar', =>
                    @span "Called #{_.pluralize(stack.callCount, 'time')}"
                    if packageName and url = self.createIssueUrl(packageName, deprecation, stack)
                      @a href:url, "Create Issue on #{packageName} repo"

                  @div class: 'stack-trace', =>
                    for {functionName, location, fileName} in stack
                      @div class: 'stack-line', =>
                        @span functionName
                        @span " - "
                        @a class:'stack-line-location', href:location, location

  updateSelectors: ->
    @refreshSelectorsButton.hide()
    @selectorList.empty()

    linter = new SelectorLinter(maxPerPackage: 50)
    for pkg in atom.packages.getActivePackages()
      linter.checkPackage(pkg)

    for packageName, deprecationsByFile of linter.getDeprecations()
      @selectorList.append $$ ->
        @li class: 'deprecation list-nested-item collapsed', =>
          @div class: 'deprecation-info list-item', =>
            @span class: 'text-highlight', packageName

          @ul class: 'list', =>
            for sourcePath, deprecations of deprecationsByFile
              @li class: 'list-item source-file', =>
                @a href: path.join(deprecations[0].packagePath, sourcePath), sourcePath
                @ul class: 'list', =>
                  for deprecation in deprecations
                    @li class: 'list-item text-success', deprecation.message

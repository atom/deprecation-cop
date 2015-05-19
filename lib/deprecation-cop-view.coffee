{Disposable, CompositeDisposable} = require 'atom'
{$, $$, ScrollView} = require 'atom-space-pen-views'
path = require 'path'
_ = require 'underscore-plus'
fs = require 'fs-plus'
Grim = require 'grim'
marked = require 'marked'

{getSelectorDeprecations} = require './helpers'

module.exports =
class DeprecationCopView extends ScrollView
  @content: ->
    @div class: 'deprecation-cop pane-item native-key-bindings', tabindex: -1, =>
      @div class: 'panel', =>
        @div class: 'panel-heading', =>
          @span "Deprecated calls"
        @ul outlet: 'list', class: 'list-tree has-collapsable-children'

        @div class: 'panel-heading', =>
          @span "Deprecated selectors"
        @ul outlet: 'selectorList', class: 'selectors list-tree has-collapsable-children'

  initialize: ({@uri}) ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add Grim.on 'updated', @handleGrimUpdated
    @subscriptions.add atom.packages.onDidActivateInitialPackages =>
      @updateSelectors()

    @subscriptions.add atom.packages.onDidActivatePackage (pack) =>
      @updateSelectors() if pack.isTheme()

    @subscriptions.add atom.keymaps.onDidReloadKeymap (event) =>
      @updateSelectors() if event.path is atom.keymaps.getUserKeymapPath()

    userStylesheetPath = atom.styles.getUserStyleSheetPath()
    stylesChanged = (element) =>
      @updateSelectors() if element.getAttribute('source-path') is userStylesheetPath
    @subscriptions.add atom.styles.onDidUpdateStyleElement(stylesChanged)
    @subscriptions.add atom.styles.onDidAddStyleElement(stylesChanged)

    @debouncedUpdateCalls = _.debounce(@updateCalls, 1000)

  attached: ->
    @updateCalls()
    @updateSelectors()
    @subscribeToEvents()

  subscribeToEvents: ->
    # afterAttach is called 2x when dep cop is the active pane item on reload.
    return if @subscribedToEvents

    @on 'click', '.deprecation-info', ->
      $(this).parent().toggleClass('collapsed')

    @on 'click', '.check-for-update', ->
      atom.workspace.open('atom://config/updates')
      false

    @on 'click', '.disable-package', ->
      if @dataset.packageName
        atom.packages.disablePackage(@dataset.packageName)
      false

    @on 'click', '.stack-line-location, .source-url', ->
      pathToOpen = @href.replace('file://', '')
      pathToOpen = pathToOpen.replace(/^\//, '') if process.platform is 'win32'
      atom.open(pathsToOpen: [pathToOpen])

    @on 'click', '.issue-url', ->
      # win32 can only handle a 2048 length link, so we use the shortener.
      return if process.platform isnt 'win32'

      openExternally = (urlToOpen=@href) =>
        require('shell').openExternal(urlToOpen)

      $.ajax 'http://git.io',
        type: 'POST'
        data: url: @href
        success: (data, status, xhr) ->
          openExternally(xhr.getResponseHeader('Location'))
        error: ->
          openExternally()

      false

    @subscribedToEvents = true

  destroy: ->
    @subscriptions.dispose()
    @detach()

  serialize: ->
    deserializer: @constructor.name
    uri: @getURI()

  handleGrimUpdated: =>
    @debouncedUpdateCalls()

  getURI: ->
    @uri

  getTitle: ->
    'Deprecation Cop'

  getIconName: ->
    'alert'

  # TODO: remove these after removing all deprecations from core. They are NOPs
  onDidChangeTitle: -> new Disposable
  onDidChangeModified: -> new Disposable

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
        packagePaths[packageName] = fs.absolute(packagePath)

    for i in [1...stack.length]
      {functionName, location, fileName} = stack[i]

      # Empty when it was run from the dev console
      return unless fileName

      # Continue to next stack entry if call is in node_modules
      continue if fileName.includes("#{path.sep}node_modules#{path.sep}")

      for packageName, packagePath of packagePaths
        relativePath = path.relative(packagePath, fileName)
        return packageName unless /^\.\./.test(relativePath)

      return "Your local #{path.basename(fileName)} file" if atom.getUserInitScriptPath() is fileName

    return

  createIssueUrl: (packageName, deprecation, stack) ->
    return unless repo = atom.packages.getActivePackage(packageName)?.metadata?.repository
    repoUrl = repo.url ? repo
    repoUrl = repoUrl.replace(/\.git$/, '')

    title = "#{deprecation.getOriginName()} is deprecated."
    stacktrace = stack.map(({functionName, location}) -> "#{functionName} (#{location})").join("\n")
    body = "#{deprecation.getMessage()}\n```\n#{stacktrace}\n```"
    "#{repoUrl}/issues/new?title=#{encodeURI(title)}&body=#{encodeURI(body)}"

  createSelectorIssueUrl: (packageName, deprecation, sourcePath) ->
    return unless repo = atom.packages.getActivePackage(packageName)?.metadata?.repository
    repoUrl = repo.url ? repo
    repoUrl = repoUrl.replace(/\.git$/, '')

    title = deprecation.message
    body = "In #{sourcePath}: #{deprecation.message}"
    "#{repoUrl}/issues/new?title=#{encodeURI(title)}&body=#{encodeURI(body)}"

  updateCalls: ->
    deprecations = Grim.getDeprecations()
    deprecations.sort (a, b) -> b.getCallCount() - a.getCallCount()
    @list.empty()

    packageDeprecations = {}
    for deprecation in deprecations
      stacks = deprecation.getStacks()
      stacks.sort (a, b) -> b.callCount - a.callCount
      for stack in stacks
        packageName = stack.metadata?.packageName ? (@getPackageName(stack) or '').toLowerCase()
        packageDeprecations[packageName] ?= []
        packageDeprecations[packageName].push {deprecation, stack}

    # I feel guilty about this nested code catastrophe
    if deprecations.length is 0
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

              if packageName and atom.packages.getLoadedPackage(packageName)
                @div class: 'padded', =>
                  @div class: 'btn-group', =>
                    @button class: 'btn check-for-update', 'Check for Update'
                    @button class: 'btn disable-package', 'data-package-name': packageName, 'Disable Package'

              for {deprecation, stack} in packageDeprecations[packageName]
                @li class: 'list-item deprecation-detail', =>
                  @span class: 'text-warning icon icon-alert'
                  @div class: 'list-item deprecation-message', =>
                    @raw marked(deprecation.getMessage())

                  @div class: 'btn-toolbar', =>
                    @span "Called #{_.pluralize(stack.callCount, 'time')}"
                    if packageName and url = self.createIssueUrl(packageName, deprecation, stack)
                      @a class: 'issue-url', href: url, "Create Issue on #{packageName} repo"

                  @div class: 'stack-trace', =>
                    for {functionName, location, fileName} in stack
                      @div class: 'stack-line', =>
                        @span functionName
                        @span " - "
                        @a class:'stack-line-location', href: location, location

  updateSelectors: ->
    @selectorList.empty()
    self = this

    deprecations = getSelectorDeprecations()

    if Object.keys(deprecations).length is 0
      @selectorList.append $$ ->
        @li class: 'list-item', "No deprecated selectors"
      return

    for packageName, deprecationsByFile of deprecations
      @selectorList.append $$ ->
        @li class: 'deprecation list-nested-item collapsed', =>
          @div class: 'deprecation-info list-item', =>
            @span class: 'text-highlight', packageName

          @ul class: 'list', =>
            for sourcePath, deprecations of deprecationsByFile
              @li class: 'list-item source-file', =>
                @a class: 'source-url', href: path.join(deprecations[0].packagePath, sourcePath), sourcePath
                @ul class: 'list', =>
                  for deprecation in deprecations
                    @li class: 'list-item deprecation-detail', =>
                      @span class: 'text-warning icon icon-alert'
                      @div class: 'list-item deprecation-message', =>
                        @raw marked(deprecation.message)

                      @div class: 'btn-toolbar', =>
                        if url = self.createSelectorIssueUrl(packageName, deprecation, sourcePath)
                          @a class: 'issue-url', href: url, "Create Issue on #{packageName} repo"

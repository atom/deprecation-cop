{Disposable, CompositeDisposable} = require 'atom'
{$, $$, ScrollView} = require 'atom-space-pen-views'
path = require 'path'
_ = require 'underscore-plus'
fs = require 'fs-plus'
Grim = require 'grim'
marked = require 'marked'

module.exports =
class DeprecationCopView extends ScrollView
  @content: ->
    @div class: 'deprecation-cop pane-item native-key-bindings', tabindex: -1, =>
      @div class: 'panel', =>
        @div class: 'padded deprecation-overview', =>
          @div class: 'pull-right btn-group', =>
            @button class: 'btn btn-primary check-for-update', 'Check for Updates'

        @div class: 'panel-heading', =>
          @span "Deprecated calls"
        @ul outlet: 'list', class: 'list-tree has-collapsable-children'

        @div class: 'panel-heading', =>
          @span "Deprecated selectors"
        @ul outlet: 'selectorList', class: 'selectors list-tree has-collapsable-children'

  initialize: ({@uri}) ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add(Grim.on('updated', @handleGrimUpdated))
    # TODO: Remove conditional when the new StyleManager deprecation APIs reach stable.
    if atom.styles.onDidUpdateDeprecations?
      @subscriptions.add(atom.styles.onDidUpdateDeprecations(=> @updateSelectors()))
    @debouncedUpdateCalls = _.debounce(@updateCalls, 1000)

  attached: ->
    @updateCalls()
    @updateSelectors()
    @subscribeToEvents()

  subscribeToEvents: ->
    # afterAttach is called 2x when dep cop is the active pane item on reload.
    return if @subscribedToEvents

    self = this

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
      self.openIssueUrl(@dataset.repoUrl, @dataset.issueUrl, @dataset.issueTitle)
      false

    @subscribedToEvents = true

  findSimilarIssues: (repoUrl, issueTitle) ->
    url = "https://api.github.com/search/issues"
    repo = repoUrl.replace /http(s)?:\/\/(\d+\.)?github.com\//gi, ''
    query = "#{issueTitle} repo:#{repo}"

    new Promise (resolve, reject) ->
      $.ajax "#{url}?q=#{encodeURI(query)}&sort=created",
        accept: 'application/vnd.github.v3+json'
        contentType: 'application/json'
        success: (data) ->
          if data.items?
            issues = {}
            for issue in data.items
              issues[issue.state] = issue if issue.title.indexOf(issueTitle) > -1 and not issues[issue.state]?
            return resolve(issues) if issues.open? or issues.closed?
          resolve(null)
        error: ->
          resolve(null)

  openIssueUrl: (repoUrl, issueUrl, issueTitle) ->
    openExternally = (urlToOpen) ->
      require('shell').openExternal(urlToOpen)

    @findSimilarIssues(repoUrl, issueTitle).then (issues) ->
      if issues?.open or issues?.closed
        issue = issues.open or issues.closed
        openExternally(issue.html_url)
      else if process.platform is 'win32'
        $.ajax 'http://git.io',
          type: 'POST'
          data: url: issueUrl
          success: (data, status, xhr) ->
            openExternally(xhr.getResponseHeader('Location'))
          error: ->
            openExternally(issueUrl)
      else
        openExternally(issueUrl)

  destroy: ->
    @subscriptions.dispose()
    @detach()

  serialize: ->
    deserializer: @constructor.name
    uri: @getURI()
    version: 1

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
    packagePaths = @getPackagePathsByPackageName()
    for packageName, packagePath of packagePaths
      if packagePath.indexOf('.atom/dev/packages') > -1 or packagePath.indexOf('.atom/packages') > -1
        packagePaths[packageName] = fs.absolute(packagePath)

    for i in [1...stack.length]
      {fileName} = stack[i]

      # Empty when it was run from the dev console
      return unless fileName

      # Continue to next stack entry if call is in node_modules
      continue if fileName.includes("#{path.sep}node_modules#{path.sep}")

      for packageName, packagePath of packagePaths
        relativePath = path.relative(packagePath, fileName)
        return packageName unless /^\.\./.test(relativePath)

      return "Your local #{path.basename(fileName)} file" if atom.getUserInitScriptPath() is fileName

    return

  getRepoUrl: (packageName) ->
    return unless repo = atom.packages.getLoadedPackage(packageName)?.metadata?.repository
    repoUrl = repo.url ? repo
    repoUrl.replace(/\.git$/, '')

  createIssueUrl: (packageName, deprecation, stack) ->
    repoUrl = @getRepoUrl(packageName)
    return unless repoUrl

    title = "#{deprecation.getOriginName()} is deprecated."
    stacktrace = stack.map(({functionName, location}) -> "#{functionName} (#{location})").join("\n")
    body = "#{deprecation.getMessage()}\n```\n#{stacktrace}\n```"
    "#{repoUrl}/issues/new?title=#{encodeURI(title)}&body=#{encodeURI(body)}"

  createSelectorIssueUrl: (packageName, title, body) ->
    repoUrl = @getRepoUrl(packageName)
    if repoUrl
      "#{repoUrl}/issues/new?title=#{encodeURI(title)}&body=#{encodeURI(body)}"
    else
      null

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

                  if packageName and issueUrl = self.createIssueUrl(packageName, deprecation, stack)
                    repoUrl = self.getRepoUrl(packageName)
                    issueTitle = "#{deprecation.getOriginName()} is deprecated."
                    @div class: 'btn-toolbar', =>
                      @button class: 'btn issue-url', 'data-issue-title': issueTitle, 'data-repo-url': repoUrl, 'data-issue-url': issueUrl, 'Report Issue'

                  @div class: 'stack-trace', =>
                    for {functionName, location} in stack
                      @div class: 'stack-line', =>
                        @span functionName
                        @span " - "
                        @a class: 'stack-line-location', href: location, location

  updateSelectors: ->
    @selectorList.empty()
    self = this

    deprecationsByPackageName = @getSelectorDeprecationsByPackageName()
    if deprecationsByPackageName.size is 0
      @selectorList.append $$ ->
        @li class: 'list-item', "No deprecated selectors"
      return

    for packageName, packageDeprecations of deprecationsByPackageName
      @selectorList.append $$ ->
        @li class: 'deprecation list-nested-item collapsed', =>
          @div class: 'deprecation-info list-item', =>
            @span class: 'text-highlight', packageName

          @ul class: 'list', =>
            if packageName and atom.packages.getLoadedPackage(packageName)
              @div class: 'padded', =>
                @div class: 'btn-group', =>
                  @button class: 'btn check-for-update', 'Check for Update'
                  @button class: 'btn disable-package', 'data-package-name': packageName, 'Disable Package'

            for {packagePath, sourcePath, deprecation} in packageDeprecations
              relativeSourcePath = path.relative(packagePath, sourcePath)
              @li class: 'list-item source-file', =>
                @a class: 'source-url', href: sourcePath, relativeSourcePath
                @ul class: 'list', =>
                  @li class: 'list-item deprecation-detail', =>
                    @span class: 'text-warning icon icon-alert'
                    @div class: 'list-item deprecation-message', =>
                      @raw marked(deprecation.message)

                    issueTitle = "Deprecated selector in `#{relativeSourcePath}`"
                    issueBody = "In `#{relativeSourcePath}`: \n\n#{deprecation.message}"
                    if issueUrl = self.createSelectorIssueUrl(packageName, issueTitle, issueBody)
                      repoUrl = self.getRepoUrl(packageName)
                      @div class: 'btn-toolbar', =>
                        @button class: 'btn issue-url', 'data-issue-title': issueTitle, 'data-repo-url': repoUrl, 'data-issue-url': issueUrl, 'Report Issue'

  getSelectorDeprecationsByPackageName: ->
    # TODO: Remove conditional when the new StyleManager deprecation APIs reach stable.
    if atom.styles.getDeprecations?
      deprecationsByPackageName = {}
      for sourcePath, deprecation of atom.styles.getDeprecations()
        components = sourcePath.split(path.sep)
        packagesComponentIndex = components.indexOf('packages')
        if packagesComponentIndex isnt -1
          packageName = components[packagesComponentIndex + 1]
          packagePath = components.slice(0, packagesComponentIndex + 1).join(path.sep)
        else
          packageName = 'Other' # could be Atom Core or the personal style sheet
          packagePath = ''

        deprecationsByPackageName[packageName] ?= []
        deprecationsByPackageName[packageName].push({packagePath, sourcePath, deprecation})
      deprecationsByPackageName
    else
      {}

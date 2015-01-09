DeprecationCopView = null

viewUri = 'atom://deprecation-cop'
createView = (state) ->
  DeprecationCopView ?= require './deprecation-cop-view'
  new DeprecationCopView(state)

atom.deserializers.add
  name: 'DeprecationCopView'
  deserialize: createView

module.exports =
  deprecationCopView: null
  deprecationCopStatusBarView: null
  commandSubscription: null

  activate: ->
    atom.workspace.addOpener (uriToOpen) =>
      return unless uriToOpen is viewUri
      @deprecationCopView = createView(uri: uriToOpen)

    activatedDisposable = atom.packages.onDidActivateInitialPackages =>
      DeprecationCopStatusBarView = require './deprecation-cop-status-bar-view'
      @deprecationCopStatusBarView ?= new DeprecationCopStatusBarView()
      workspaceElement = atom.views.getView(atom.workspace)
      statusBar = workspaceElement.querySelector('.status-bar')
      statusBar?.addRightTile(item: @deprecationCopStatusBarView)
      activatedDisposable.dispose()

    @commandSubscription = atom.commands.add 'atom-workspace', 'deprecation-cop:view', ->
      atom.workspace.open(viewUri)

  deactivate: ->
    @deprecationCopView?.destroy()
    @deprecationCopStatusBarView?.destroy()
    @commandSubscription?.dispose()

    @deprecationCopView = null
    @deprecationCopStatusBarView = null
    @commandSubscription = null

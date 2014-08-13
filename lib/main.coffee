DeprecationCopView = require './deprecation-cop-view'
DeprecationCopStatusBarView = require './deprecation-cop-status-bar-view'

viewUri = 'atom://deprecation-cop'

module.exports =
  deprecationCopView: null
  deprecationCopStatusBarView: null

  activate: ->
    atom.workspace.registerOpener (uriToOpen) =>
      return unless uriToOpen is viewUri
      @deprecationCopView = new DeprecationCopView(uriToOpen)

    atom.packages.once 'activated', =>
      @deprecationCopStatusBarView ?= new DeprecationCopStatusBarView()
      atom.workspaceView.statusBar?.appendRight(@deprecationCopStatusBarView)

    atom.workspaceView.command 'deprecation-cop:view', ->
      atom.workspaceView.open(viewUri)

  deactivate: ->
    @deprecationCopView?.destroy()
    @deprecationCopStatusBarView?.destroy()

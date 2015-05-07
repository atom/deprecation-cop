Grim = require 'grim'

DeprecationCopView = null

viewUri = 'atom://deprecation-cop'
createView = (state) ->
  DeprecationCopView ?= require './deprecation-cop-view'
  new DeprecationCopView(state)

module.exports =
  deprecationCopView: null
  deprecationCopStatusBarView: null
  commandSubscription: null

  activate: ->
    atom.workspace.addOpener (uriToOpen) =>
      return unless uriToOpen is viewUri
      @deprecationCopView = createView(uri: uriToOpen)

    @commandSubscription = atom.commands.add 'atom-workspace', 'deprecation-cop:view', ->
      atom.workspace.open(viewUri)

  deactivate: ->
    @deprecationCopView?.destroy()
    @deprecationCopStatusBarView?.destroy()
    @commandSubscription?.dispose()

    @deprecationCopView = null
    @deprecationCopStatusBarView = null
    @commandSubscription = null

  consumeStatusBar: (statusBar) ->
    DeprecationCopStatusBarView = require './deprecation-cop-status-bar-view'
    @deprecationCopStatusBarView ?= new DeprecationCopStatusBarView()
    statusBar.addRightTile(item: @deprecationCopStatusBarView, priority: 150)

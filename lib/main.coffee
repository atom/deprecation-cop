Grim = require 'grim'

DeprecationCopView = null
deprecationCopView = null

viewUri = 'atom://deprecation-cop'
createView = (state) ->
  DeprecationCopView ?= require './deprecation-cop-view'
  deprecationCopView ?= new DeprecationCopView(state)
  deprecationCopView

deserializer =
  name: 'DeprecationCopView'
  version: 1
  deserialize: createView
atom.deserializers.add(deserializer)

module.exports =
  deprecationCopView: null
  deprecationCopStatusBarView: null
  commandSubscription: null

  activate: ->
    atom.workspace.addOpener (uriToOpen) ->
      createView(uri: uriToOpen) if uriToOpen is viewUri

    @commandSubscription = atom.commands.add 'atom-workspace', 'deprecation-cop:view', ->
      atom.workspace.open(viewUri)

  deactivate: ->
    deprecationCopView?.destroy()
    @deprecationCopStatusBarView?.destroy()
    @commandSubscription?.dispose()

    deprecationCopView = null
    @deprecationCopStatusBarView = null
    @commandSubscription = null

  consumeStatusBar: (statusBar) ->
    DeprecationCopStatusBarView = require './deprecation-cop-status-bar-view'
    @deprecationCopStatusBarView ?= new DeprecationCopStatusBarView()
    statusBar.addRightTile(item: @deprecationCopStatusBarView, priority: 150)

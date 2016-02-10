{Disposable, CompositeDisposable} = require 'atom'

ViewURI = 'atom://deprecation-cop'
DeprecationCopView = null

module.exports =
  disposables: null

  activate: ->
    @disposables = new CompositeDisposable

    @disposables.add atom.workspace.addOpener (uri) =>
      @deserializeDeprecationCopView({uri}) if uri is ViewURI

    @disposables.add atom.commands.add 'atom-workspace', 'deprecation-cop:view', ->
      atom.workspace.open(ViewURI)

  deactivate: ->
    @disposables.dispose()
    if pane = atom.workspace.paneForURI(ViewURI)
      pane.destroyItem(pane.itemForURI(ViewURI))

  deserializeDeprecationCopView: (state) ->
    DeprecationCopView ?= require './deprecation-cop-view'
    new DeprecationCopView(state)

  consumeStatusBar: (statusBar) ->
    if atom.inDevMode()
      DeprecationCopStatusBarView = require './deprecation-cop-status-bar-view'
      statusBarView = new DeprecationCopStatusBarView()
      statusBarTile = statusBar.addRightTile(item: statusBarView, priority: 150)
      @disposables.add(new Disposable => statusBarView.destroy())
      @disposables.add(new Disposable => statusBarTile.destroy())

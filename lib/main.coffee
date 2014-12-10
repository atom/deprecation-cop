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

  activate: ->
    atom.workspace.addOpener (uriToOpen) =>
      return unless uriToOpen is viewUri
      @deprecationCopView = createView(uri: uriToOpen)

    # TODO: Uncomment when we're ready to encourage users to file issues about
    # deprecations. It will be when we get closer to the API freeze.
    # atom.packages.once 'activated', =>
    #   DeprecationCopStatusBarView = require './deprecation-cop-status-bar-view'
    #   @deprecationCopStatusBarView ?= new DeprecationCopStatusBarView()
    #   atom.workspaceView.statusBar?.appendRight(@deprecationCopStatusBarView)

    atom.commands.add 'atom-workspace', 'deprecation-cop:view', ->
      atom.workspace.open(viewUri)

  deactivate: ->
    @deprecationCopView?.destroy()
    @deprecationCopStatusBarView?.destroy()

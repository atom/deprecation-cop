DeprecationCopView = require './deprecation-cop-view'

viewUri = 'atom://deprecation-cop'

module.exports =
  activate: ->
    atom.project.registerOpener (uriToOpen) ->
      return unless uriToOpen is viewUri
      @deprecationCopView = new DeprecationCopView(uriToOpen)

    atom.workspaceView.command 'deprecation-cop:view', ->
      atom.workspaceView.open(viewUri)

  deactivate: ->
    @deprecationCopView?.destroy()

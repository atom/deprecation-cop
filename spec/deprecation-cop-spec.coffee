DeprecationCop = require '../lib/deprecation-cop'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "DeprecationCop", ->
  activationPromise = null

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    activationPromise = atom.packages.activatePackage('deprecationCop')

  describe "when the deprecation-cop:toggle event is triggered", ->
    it "attaches and then detaches the view", ->
      expect(atom.workspaceView.find('.deprecation-cop')).not.toExist()

      # This is an activation event, triggering it will cause the package to be
      # activated.
      atom.workspaceView.trigger 'deprecation-cop:toggle'

      waitsForPromise ->
        activationPromise

      runs ->
        expect(atom.workspaceView.find('.deprecation-cop')).toExist()
        atom.workspaceView.trigger 'deprecation-cop:toggle'
        expect(atom.workspaceView.find('.deprecation-cop')).not.toExist()

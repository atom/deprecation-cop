DeprecationCopView = require '../lib/deprecation-cop-view'

describe "DeprecationCop", ->
  [activationPromise, workspaceElement] = []

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    activationPromise = atom.packages.activatePackage('deprecation-cop')

  describe "when the deprecation-cop:view event is triggered", ->
    it "displays deprecation cop pane", ->
      expect(atom.workspace.getActivePane().getActiveItem()).not.toExist()

      atom.commands.dispatch workspaceElement, 'deprecation-cop:view'

      waitsForPromise ->
        activationPromise

      runs ->
        deprecationCopView = atom.workspace.getActivePane().getActiveItem()
        expect(deprecationCopView instanceof DeprecationCopView).toBeTruthy()

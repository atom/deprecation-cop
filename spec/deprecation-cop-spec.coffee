{WorkspaceView} = require 'atom'

DeprecationCopView = require '../lib/deprecation-cop-view'

describe "DeprecationCop", ->
  activationPromise = null

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    activationPromise = atom.packages.activatePackage('deprecation-cop')

  describe "when the deprecation-cop:view event is triggered", ->
    it "displayes deprecation cop pane", ->
      expect(atom.workspace.getActivePane().getActiveItem()).not.toExist()

      atom.workspaceView.trigger 'deprecation-cop:view'

      waitsForPromise ->
        activationPromise

      runs ->
        timeCopView = atom.workspace.getActivePane().getActiveItem()
        expect(timeCopView instanceof DeprecationCopView).toBeTruthy()

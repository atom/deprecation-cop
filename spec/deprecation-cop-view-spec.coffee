{WorkspaceView} = require 'atom'
Grim = require 'grim'
DeprecationCopView = require '../lib/deprecation-cop-view'

describe "DeprecationCopView", ->
  [deprecatedMethod, activationPromise] = []

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    activationPromise = atom.packages.activatePackage('deprecation-cop')
    deprecatedMethod = -> Grim.deprecate("This isn't used")
    deprecatedMethod()
    atom.workspaceView.trigger 'deprecation-cop:view'

    waitsForPromise ->
      activationPromise

  it "displays deprecated methods", ->
    timeCopView = atom.workspace.getActivePane().getActiveItem()
    expect(timeCopView.html()).toMatch /deprecation-cop package/
    expect(timeCopView.html()).toMatch /This isn't used/

{WorkspaceView} = require 'atom'
Grim = require 'grim'
DeprecationCopView = require '../lib/deprecation-cop-view'

xdescribe "DeprecationCopStatusBarView", ->
  [deprecatedMethod, statusBarView] = []

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    sbActivationPromise = atom.packages.activatePackage('status-bar')
    dcActivationPromise = atom.packages.activatePackage('deprecation-cop')

    waitsForPromise -> sbActivationPromise
    waitsForPromise -> dcActivationPromise
    runs ->
      # UGH
      atom.packages.emit 'activated'
      statusBarView = atom.workspaceView.find('.deprecation-cop-status')

  it "adds the status bar view when activated", ->
    expect(statusBarView).toHaveLength 1
    expect(statusBarView.text()).toBe '0'
    expect(statusBarView).not.toShow()

  it "increments when there are deprecated methods", ->
    deprecatedMethod = -> Grim.deprecate("This isn't used")
    anotherDeprecatedMethod = -> Grim.deprecate("This either")
    expect(statusBarView[0].style.display).toBe 'none'
    expect(statusBarView).not.toShow()

    deprecatedMethod()
    expect(statusBarView.text()).toBe '1'
    expect(statusBarView).toShow()

    deprecatedMethod()
    expect(statusBarView.text()).toBe '1'
    expect(statusBarView).toShow()

    anotherDeprecatedMethod()
    expect(statusBarView.text()).toBe '2'
    expect(statusBarView).toShow()

  it 'opens deprecation cop tab when clicked', ->
    expect(atom.workspace.getActivePane().getActiveItem()).not.toExist()
    statusBarView.click()

    waits 0
    runs ->
      depCopView = atom.workspace.getActivePane().getActiveItem()
      expect(depCopView instanceof DeprecationCopView).toBe true

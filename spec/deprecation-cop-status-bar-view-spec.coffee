Grim = require 'grim'
DeprecationCopView = require '../lib/deprecation-cop-view'

xdescribe "DeprecationCopStatusBarView", ->
  [deprecatedMethod, statusBarView, workspaceElement] = []

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    jasmine.attachToDOM(workspaceElement)
    sbActivationPromise = atom.packages.activatePackage('status-bar')
    dcActivationPromise = atom.packages.activatePackage('deprecation-cop')

    waitsForPromise -> sbActivationPromise
    waitsForPromise -> dcActivationPromise
    runs ->
      # UGH
      atom.packages.emitter.emit 'did-activate-all'
      statusBarView = workspaceElement.querySelector('.deprecation-cop-status')

  it "adds the status bar view when activated", ->
    expect(statusBarView).toExist()
    expect(statusBarView.textContent).toBe '0'
    expect(statusBarView).not.toShow()

  it "increments when there are deprecated methods", ->
    deprecatedMethod = -> Grim.deprecate("This isn't used")
    anotherDeprecatedMethod = -> Grim.deprecate("This either")
    expect(statusBarView.style.display).toBe 'none'
    expect(statusBarView).not.toShow()

    deprecatedMethod()
    expect(statusBarView.textContent).toBe '1'
    expect(statusBarView).toShow()

    deprecatedMethod()
    expect(statusBarView.textContent).toBe '1'
    expect(statusBarView).toShow()

    anotherDeprecatedMethod()
    expect(statusBarView.textContent).toBe '2'
    expect(statusBarView).toShow()

  it 'opens deprecation cop tab when clicked', ->
    expect(atom.workspace.getActivePane().getActiveItem()).not.toExist()
    statusBarView.click()

    waits 0
    runs ->
      depCopView = atom.workspace.getActivePane().getActiveItem()
      expect(depCopView instanceof DeprecationCopView).toBe true

path = require 'path'
Grim = require 'grim'
DeprecationCopView = require '../lib/deprecation-cop-view'
_ = require 'underscore-plus'

describe "DeprecationCopStatusBarView", ->
  [deprecatedMethod, statusBarView, workspaceElement] = []

  beforeEach ->
    # jasmine.Clock.useMock() cannot mock _.debounce
    # http://stackoverflow.com/questions/13707047/spec-for-async-functions-using-jasmine
    spyOn(_, 'debounce').andCallFake (func) ->
      -> func.apply(this, arguments)

    jasmine.snapshotDeprecations()

    workspaceElement = atom.views.getView(atom.workspace)
    jasmine.attachToDOM(workspaceElement)
    waitsForPromise -> atom.packages.activatePackage('status-bar')
    waitsForPromise -> atom.packages.activatePackage('deprecation-cop')

    waitsFor ->
      statusBarView = workspaceElement.querySelector('.deprecation-cop-status')

  afterEach ->
    jasmine.restoreDeprecationsSnapshot()

  it "adds the status bar view when activated", ->
    expect(statusBarView).toExist()
    expect(statusBarView.textContent).toBe '0 deprecations'
    expect(statusBarView).not.toShow()

  it "increments when there are deprecated methods", ->
    deprecatedMethod = -> Grim.deprecate("This isn't used")
    anotherDeprecatedMethod = -> Grim.deprecate("This either")
    expect(statusBarView.style.display).toBe 'none'
    expect(statusBarView).not.toShow()

    deprecatedMethod()
    expect(statusBarView.textContent).toBe '1 deprecation'
    expect(statusBarView).toBeVisible()

    deprecatedMethod()
    expect(statusBarView.textContent).toBe '2 deprecations'
    expect(statusBarView).toBeVisible()

    anotherDeprecatedMethod()
    expect(statusBarView.textContent).toBe '3 deprecations'
    expect(statusBarView).toBeVisible()

  it "increments when there are deprecated selectors", ->
    atom.packages.loadPackage(path.join(__dirname, "..", "spec", "fixtures", "package-with-deprecated-selectors"))

    expect(statusBarView.textContent).toBe '3 deprecations'
    expect(statusBarView).toBeVisible()

    atom.packages.unloadPackage('package-with-deprecated-selectors')

    expect(statusBarView.textContent).toBe '0 deprecations'
    expect(statusBarView).not.toBeVisible()

  it "increments when a theme with deprecated selectors is activated", ->
    atom.packages.loadPackage(path.join(__dirname, "..", "spec", "fixtures", "theme-with-deprecated-selectors"))

    expect(statusBarView).not.toBeVisible()
    expect(statusBarView.textContent).toBe '0 deprecations'

    waitsForPromise ->
      atom.packages.activatePackage(path.join(__dirname, "..", "spec", "fixtures", "theme-with-deprecated-selectors"))

    runs ->
      expect(statusBarView).toBeVisible()
      expect(statusBarView.textContent).toBe '1 deprecation'

      atom.packages.deactivatePackage("theme-with-deprecated-selectors")
      atom.packages.unloadPackage("theme-with-deprecated-selectors")

  it 'opens deprecation cop tab when clicked', ->
    expect(atom.workspace.getActivePane().getActiveItem()).not.toExist()
    statusBarView.click()

    waits 0
    runs ->
      depCopView = atom.workspace.getActivePane().getActiveItem()
      expect(depCopView instanceof DeprecationCopView).toBe true

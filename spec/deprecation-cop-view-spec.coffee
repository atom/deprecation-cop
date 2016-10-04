Grim = require 'grim'
path = require 'path'
_ = require 'underscore-plus'

describe "DeprecationCopView", ->
  [deprecationCopView, workspaceElement] = []

  beforeEach ->
    spyOn(_, 'debounce').andCallFake (func) ->
      -> func.apply(this, arguments)

    workspaceElement = atom.views.getView(atom.workspace)
    jasmine.attachToDOM(workspaceElement)

    jasmine.snapshotDeprecations()
    Grim.clearDeprecations()
    deprecatedMethod = -> Grim.deprecate("A test deprecation. This isn't used")
    deprecatedMethod()

    spyOn(Grim, 'deprecate') # Don't fail tests if when using deprecated APIs in deprecation cop's activation
    activationPromise = atom.packages.activatePackage('deprecation-cop')

    atom.commands.dispatch workspaceElement, 'deprecation-cop:view'

    waitsForPromise ->
      activationPromise

    runs ->
      jasmine.unspy(Grim, 'deprecate')
      deprecationCopView = atom.workspace.getActivePane().getActiveItem()

  afterEach ->
    jasmine.restoreDeprecationsSnapshot()

  it "displays deprecated methods", ->
    expect(deprecationCopView.html()).toMatch /Deprecated calls/
    expect(deprecationCopView.html()).toMatch /This isn't used/

  it "displays deprecated selectors", ->
    atom.styles.addStyleSheet("atom-text-editor::shadow { color: red }", sourcePath: path.join('some-dir', 'packages', 'package-1', 'file-1.css'))
    atom.styles.addStyleSheet("atom-text-editor::shadow { color: yellow }", context: 'atom-text-editor', sourcePath: path.join('some-dir', 'packages', 'package-1', 'file-2.css'))
    atom.styles.addStyleSheet('atom-text-editor::shadow { color: blue }', sourcePath: path.join('another-dir', 'packages', 'package-2', 'file-3.css'))
    atom.styles.addStyleSheet('atom-text-editor::shadow { color: gray }', sourcePath: path.join('another-dir', 'node_modules', 'package-3', 'file-4.css'))

    packageItems = deprecationCopView.find("ul.selectors > li")
    expect(packageItems.length).toBe(3)
    expect(packageItems.eq(0).html()).toMatch /package-1/
    expect(packageItems.eq(1).html()).toMatch /package-2/
    expect(packageItems.eq(2).html()).toMatch /Atom Core/

    packageDeprecationItems = packageItems.eq(0).find("li.source-file")
    expect(packageDeprecationItems.length).toBe(2)
    expect(packageDeprecationItems.eq(0).text()).toMatch /atom-text-editor/
    expect(packageDeprecationItems.eq(0).find("a").attr("href")).toBe(path.join('some-dir', 'packages', 'package-1', 'file-1.css'))
    expect(packageDeprecationItems.eq(1).text()).toMatch /:host/
    expect(packageDeprecationItems.eq(1).find("a").attr("href")).toBe(path.join('some-dir', 'packages', 'package-1', 'file-2.css'))

  it 'skips stack entries which go through node_modules/ files when determining package name', ->
    stack = [
      {
        "functionName": "function0"
        "location": path.normalize "/Users/user/.atom/packages/package1/node_modules/atom-space-pen-viewslib/space-pen.js:55:66"
        "fileName": path.normalize "/Users/user/.atom/packages/package1/node_modules/atom-space-pen-views/lib/space-pen.js"
      }
      {
        "functionName": "function1"
        "location": path.normalize "/Users/user/.atom/packages/package1/node_modules/atom-space-pen-viewslib/space-pen.js:15:16"
        "fileName": path.normalize "/Users/user/.atom/packages/package1/node_modules/atom-space-pen-views/lib/space-pen.js"
      }
      {
        "functionName": "function2"
        "location": path.normalize "/Users/user/.atom/packages/package2/lib/module.js:13:14"
        "fileName": path.normalize "/Users/user/.atom/packages/package2/lib/module.js"
      }
    ]

    packagePathsByPackageName =
      package1: path.normalize "/Users/user/.atom/packages/package1"
      package2: path.normalize "/Users/user/.atom/packages/package2"

    spyOn(deprecationCopView, 'getPackagePathsByPackageName').andReturn(packagePathsByPackageName)

    packageName = deprecationCopView.getPackageName(stack)
    expect(packageName).toBe("package2")

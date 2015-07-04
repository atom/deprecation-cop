Grim = require 'grim'
DeprecationCopView = require '../lib/deprecation-cop-view'
path = require 'path'

describe "DeprecationCopView", ->
  [deprecationCopView, workspaceElement] = []

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    jasmine.attachToDOM(workspaceElement)

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
    Grim.clearDeprecations()

  it "displays deprecated methods", ->
    expect(deprecationCopView.html()).toMatch /Deprecated calls/
    expect(deprecationCopView.html()).toMatch /This isn't used/

  it "displays deprecated selectors", ->
    fakePackageDir = path.join(__dirname, "..", "spec", "fixtures", "package-with-deprecated-selectors")

    pack = atom.packages.loadPackage(fakePackageDir)
    spyOn(atom.packages, 'getLoadedPackages').andReturn([pack])
    deprecationCopView.updateSelectors()

    packageItems = deprecationCopView.find("ul.selectors > li")
    expect(packageItems.length).toBe(1)
    expect(packageItems.eq(0).html()).toMatch /package-with-deprecated-selectors/

    packageDeprecationItems = packageItems.eq(0).find("li.source-file")
    expect(packageDeprecationItems.length).toBe(3)
    expect(packageDeprecationItems.eq(0).text()).toMatch /atom-text-editor/
    expect(packageDeprecationItems.eq(0).find("a").attr("href")).toBe(path.join(fakePackageDir, "menus", "old-menu.cson"))
    expect(packageDeprecationItems.eq(1).text()).toMatch /atom-pane-container/
    expect(packageDeprecationItems.eq(1).find("a").attr("href")).toBe(path.join(fakePackageDir, "keymaps", "old-keymap.cson"))
    expect(packageDeprecationItems.eq(2).text()).toMatch /atom-workspace/
    expect(packageDeprecationItems.eq(2).find("a").attr("href")).toBe(path.join(fakePackageDir, "styles", "old-stylesheet.less"))

    jasmine.unspy(atom.packages, 'getLoadedPackages')
    atom.packages.unloadPackage(pack.name)

  it "updates automatically when themes with deprecated selectors are activated", ->
    packageItems = deprecationCopView.find("ul.selectors > li")
    expect(packageItems.length).toBe(1)
    expect(packageItems.text()).toMatch /No deprecated selectors/

    fakePackageDir = path.join(__dirname, "..", "spec", "fixtures", "theme-with-deprecated-selectors")

    waitsForPromise ->
      atom.packages.activatePackage(fakePackageDir)

    runs ->
      packageItems = deprecationCopView.find("ul.selectors > li")
      expect(packageItems.length).toBe(1)
      packageDeprecationItems = packageItems.eq(0).find("li.source-file")
      expect(packageDeprecationItems.length).toBe(1)
      expect(packageDeprecationItems.eq(0).text()).toMatch /atom-workspace/
      expect(packageDeprecationItems.eq(0).find("a").attr("href")).toBe(path.join(fakePackageDir, "styles", "old-stylesheet.less"))

  it 'skips stack entries which go through node_modules/ files when determining package name', ->
    stack = [
      {
        "functionName": "function0"
        "location": "/Users/user/.atom/packages/package1/node_modules/atom-space-pen-viewslib/space-pen.js:55:66"
        "fileName": "/Users/user/.atom/packages/package1/node_modules/atom-space-pen-views/lib/space-pen.js"
      }
      {
        "functionName": "function1"
        "location": "/Users/user/.atom/packages/package1/node_modules/atom-space-pen-viewslib/space-pen.js:15:16"
        "fileName": "/Users/user/.atom/packages/package1/node_modules/atom-space-pen-views/lib/space-pen.js"
      }
      {
        "functionName": "function2"
        "location": "/Users/user/.atom/packages/package2/lib/module.js:13:14"
        "fileName": "/Users/user/.atom/packages/package2/lib/module.js"
      }
    ]

    # fix path separators on Windows
    if process.platform is 'win32'
      for i in [0...stack.length]
        stack[i][property] = value.replace(/\//g, path.sep) for property, value of stack[i]

    packagePathsByPackageName =
      package1: "/Users/user/.atom/packages/package1"
      package2: "/Users/user/.atom/packages/package2"

    spyOn(deprecationCopView, 'getPackagePathsByPackageName').andReturn(packagePathsByPackageName)

    packageName = deprecationCopView.getPackageName(stack)
    expect(packageName).toBe("package2")

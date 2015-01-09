Grim = require 'grim'
DeprecationCopView = require '../lib/deprecation-cop-view'
path = require 'path'

describe "DeprecationCopView", ->
  [deprecationCopView, workspaceElement] = []

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    jasmine.attachToDOM(workspaceElement)

    expect(Grim.getDeprecationsLength()).toBe 0
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
    spyOn(atom.packages, 'getActivePackages').andReturn([pack])
    deprecationCopView.find("button.refresh-selectors").click()

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
    expect(packageDeprecationItems.eq(2).find("a").attr("href")).toBe(path.join(fakePackageDir, "stylesheets", "old-stylesheet.less"))

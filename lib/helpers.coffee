path = require 'path'
SelectorLinter = require 'atom-selector-linter'
CSON = require 'season'
fs = require 'fs-plus'
_ = require 'underscore-plus'

getSelectorDeprecations = ->
  linter = new SelectorLinter(maxPerPackage: 50)
  linter.checkPackage(pkg) for pkg in atom.packages.getLoadedPackages()

  userKeymapPath = atom.keymaps.getUserKeymapPath()

  if fs.isFileSync(userKeymapPath)
    try
      userKeymap = CSON.readFileSync(userKeymapPath)

    if userKeymap
      linter.checkKeymap(userKeymap, {
        packageName: "your local #{path.basename(userKeymapPath)} file"
        packagePath: ""
        sourcePath: userKeymapPath
      })

  userStyleSheetPath = atom.styles.getUserStyleSheetPath()

  if fs.isFileSync(userStyleSheetPath)
    try
      userStyleSheet = fs.readFileSync(userStyleSheetPath, 'utf8')

    if userStyleSheet
      linter.checkUIStylesheet(userStyleSheet, {
        packageName: "your local #{path.basename(userStyleSheetPath)} file"
        packagePath: ""
        sourcePath: userStyleSheetPath
      })

  linter.getDeprecations()

getSelectorDeprecationsCount = ->
  count = 0
  deprecationsByPackageName = exports.getSelectorDeprecations()
  for packageName, deprecationsByFile of deprecationsByPackageName
    for fileName, deprecations of deprecationsByFile
      count += deprecations.length
  count

exports.getSelectorDeprecations = _.debounce getSelectorDeprecations, 1000
exports.getSelectorDeprecationsCount = _.debounce getSelectorDeprecationsCount, 1000

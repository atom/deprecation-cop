SelectorLinter = require 'atom-selector-linter'
CSON = require 'season'
fs = require 'fs-plus'

exports.getSelectorDeprecations = ->
  linter = new SelectorLinter(maxPerPackage: 50)
  linter.checkPackage(pkg) for pkg in atom.packages.getLoadedPackages()
  
  userKeymapPath = atom.keymaps.getUserKeymapPath()
  
  if fs.isFileSync(userKeymapPath)
    try
      userKeymapCson = CSON.readFileSync(userKeymapPath)
    catch error
      console.warn("Failed to load keymap file: #{userKeymapPath}", error)
      
    if userKeymapCson
      linter.checkKeymap(userKeymapCson, {
        packageName: "your local #{path.basename(userKeymapPath)} file"
        packagePath: ""
        sourcePath: userKeymapPath
      })
      
  userStyleSheetPath = atom.styles.getUserStyleSheetPath()
  
  if fs.isFileSync(userStyleSheetPath)
    userStyleSheet = fs.readFileSync(userStyleSheetPath, 'utf8')
    linter.checkUIStylesheet(userStyleSheet, {
      packageName: "your local #{path.basename(userStyleSheetPath)} file"
      packagePath: ""
      sourcePath: userStyleSheetPath
    })
  
  linter.getDeprecations()

exports.getSelectorDeprecationsCount = ->
  count = 0
  deprecationsByPackageName = exports.getSelectorDeprecations()
  for packageName, deprecationsByFile of deprecationsByPackageName
    for fileName, deprecations of deprecationsByFile
      count += deprecations.length
  count

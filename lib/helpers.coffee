SelectorLinter = require 'atom-selector-linter'
CSON = require 'season'
fs = require 'fs-plus'

exports.getSelectorDeprecations = ->
  linter = new SelectorLinter(maxPerPackage: 50)
  linter.checkPackage(pkg) for pkg in atom.packages.getLoadedPackages()
  
  userKeymapPath = atom.keymaps.getUserKeymapPath()
  
  if fs.isFileSync(userKeymapPath)
    linter.checkKeymap(CSON.readFileSync(atom.keymaps.getUserKeymapPath()), {
      packageName: "your local #{path.basename(userKeymapPath)} file",
      packagePath: "",
      sourcePath: userKeymapPath
    })
    
  userStyleSheetPath = atom.styles.getUserStyleSheetPath()
  
  if fs.isFileSync(userStyleSheetPath)
    userStyleSheet = fs.readFileSync(atom.styles.getUserStyleSheetPath(), 'utf8')
    linter.checkSyntaxStylesheet(userStyleSheet, {
      packageName: "your local #{path.basename(userStyleSheetPath)} file",
      packagePath: "",
      sourcePath: userStyleSheetPath
    })
    linter.checkUIStylesheet(userStyleSheet, {
      packageName: "your local #{path.basename(userStyleSheetPath)} file",
      packagePath: "",
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

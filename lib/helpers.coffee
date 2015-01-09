SelectorLinter = require 'atom-selector-linter'

exports.getSelectorDeprecations = ->
  linter = new SelectorLinter(maxPerPackage: 50)
  linter.checkPackage(pkg) for pkg in atom.packages.getLoadedPackages()
  linter.getDeprecations()

exports.getSelectorDeprecationsCount = ->
  count = 0
  deprecationsByPackageName = exports.getSelectorDeprecations()
  for packageName, deprecationsByFile of deprecationsByPackageName
    for fileName, deprecations of deprecationsByFile
      count += deprecations.length
  count

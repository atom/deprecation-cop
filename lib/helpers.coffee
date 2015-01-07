SelectorLinter = require 'atom-selector-linter'

exports.getSelectorDeprecations = ->
  linter = new SelectorLinter(maxPerPackage: 50)
  linter.checkPackage(pkg) for pkg in atom.packages.getActivePackages()
  linter.getDeprecations()

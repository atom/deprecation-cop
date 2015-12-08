DeprecationCopView = null

module.exports = (state) ->
  DeprecationCopView ?= require './deprecation-cop-view'
  new DeprecationCopView(state)

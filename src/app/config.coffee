fs = require 'fs'
_ = require 'underscore'
EventEmitter = require 'event-emitter'
{$$} = require 'space-pen'
jQuery = require 'jquery'
Specificity = require 'specificity'
Theme = require 'theme'

configDirPath = fs.absolute("~/.atom")
configJsonPath = fs.join(configDirPath, "config.json")
userInitScriptPath = fs.join(configDirPath, "atom.coffee")
bundledThemesDirPath = fs.join(resourcePath, "themes")
bundledPackagesDirPath = fs.join(resourcePath, "src/packages")
userThemesDirPath = fs.join(configDirPath, "themes")
userPackagesDirPath = fs.join(configDirPath, "packages")

require.paths.unshift userPackagesDirPath

module.exports =
class Config
  configDirPath: configDirPath
  themeDirPaths: [userThemesDirPath, bundledThemesDirPath]
  packageDirPaths: [userPackagesDirPath, bundledPackagesDirPath]
  settings: null

  constructor: ->
    @settings =
      core: _.clone(require('root-view').configDefaults)
      editor: _.clone(require('editor').configDefaults)

  load: ->
    @loadUserConfig()
    @requireUserInitScript()
    atom.loadPackages()
    atom.loadThemes()

  loadUserConfig: ->
    if fs.exists(configJsonPath)
      userConfig = JSON.parse(fs.read(configJsonPath))
      _.extend(@settings, userConfig)

  get: (keyPath) ->
    _.valueForKeyPath(@settings, keyPath)

  set: (keyPath, value) ->
    keys = keyPath.split('.')
    hash = @settings
    while keys.length > 1
      key = keys.shift()
      hash[key] ?= {}
      hash = hash[key]
    hash[keys.shift()] = value

    @update()
    value

  setDefaults: (keyPath, defaults) ->
    keys = keyPath.split('.')
    hash = @settings
    for key in keys
      hash[key] ?= {}
      hash = hash[key]

    _.defaults hash, defaults
    @update()

  observe: (keyPath, callback) ->
    value = @get(keyPath)
    previousValue = _.clone(value)
    updateCallback = =>
      value = @get(keyPath)
      unless _.isEqual(value, previousValue)
        previousValue = _.clone(value)
        callback(value)

    subscription = { cancel: => @off 'updated', updateCallback  }
    @on 'updated', updateCallback
    callback(value)
    subscription

  update: ->
    @save()
    @trigger 'updated'

  save: ->
    fs.write(configJsonPath, JSON.stringify(@settings, undefined, 2) + "\n")

  requireUserInitScript: ->
    try
      require userInitScriptPath if fs.exists(userInitScriptPath)
    catch error
      console.error "Failed to load `#{userInitScriptPath}`", error.stack, error

_.extend Config.prototype, EventEmitter

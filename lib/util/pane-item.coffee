{CompositeDisposable} = require 'atom'

subs = new CompositeDisposable
panes = new Set

module.exports =
class PaneItem

  @activate: ->
    return if subs?
    subs = new CompositeDisposable
    panes.forEach (Pane) ->
      Pane.registerView()

  @deactivate: ->
    subs.dispose()
    subs = null

  @attachView: (@View) ->
    @registerView()

  @registerView: ->
    panes.add this

    subs.add atom.views.addViewProvider this, (pane) =>
      if pane.element?
        pane.element
      else
        new @View().initialize pane

    subs.add atom.deserializers.add
      name: "Ink#{@name}"
      deserialize: ({id}) =>
        pane = @fromId id
        return if pane.currentPane()
        pane

    subs.add atom.workspace.addOpener (uri) =>
      if (m = uri.match new RegExp "atom://ink-#{@name.toLowerCase()}/(.+)")
        [_, id] = m
        return @fromId id

  @fromId = (id) ->
    @registered ?= {}
    if (pane = @registered[id])
      pane
    else
      pane = @registered[id] = new this
      pane.id = id
      pane

  serialize: ->
    if @id
      deserializer: "Ink#{@constructor.name}"
      id: @id

  currentPane: ->
    for pane in atom.workspace.getPanes()
      return pane if this in pane.getItems()
    return

  activate: ->
    if (pane = @currentPane())
      pane.activate()
      pane.activateItem this
      return pane
    else
      return

  open: (opts) ->
    if @activate() then return Promise.resolve @
    if @id
      atom.workspace.open "atom://ink-#{@constructor.name.toLowerCase()}/#{@id}", opts
    else
      throw new Error 'Pane does not have an ID'

  close: ->
    @currentPane()?.removeItem @


#
# Implement spawnView and title. Override className.
#
class ListItemView extends Backbone.View
  tagName: 'li'
  className: 'list-item'
  events:
    'click a': 'show'

  initialize: (options) ->
    @parent = options.parent
    @listenTo(@model, 'sync', @render)
    @listenTo(@model, 'destroy', @remove)

  childViewPushed: (view) ->
    @options.parent.childViewPushed(view)

  childViewPulled: (view) ->
    @options.parent.childViewPulled(view)

  remove: () ->
    @$el.remove()

  show: (e) ->
    e.stopPropagation()
    if !@showview?
      @showview = @spawnView()
      @showview.render()
    @options.parent.show(@showview)
    false

  render: () ->
    @$el.html("<a href='#'>#{@title()}</a>")
    @

  title: () ->
    @model.get('id')

  spawnView: () ->
    throw new "Implement spawnView in ListItemView subclass."


#
# Define className, modelName, and probably events
#
# implement render
#
class CrmModelView extends Backbone.View
  className: 'crm-model-view'
  events:
    'keypress input': 'onKeypress'
    'submit form': 'noSubmit'
    'click button.save': 'save'
    'click button.destroy': 'destroy'

  initialize: (options) ->
    @parent = options.parent
    @listenTo(@model, 'sync', @render)
    @listenTo(@model, 'destroy', @remove)

  childViewPulled: (view) ->
    @options.parent.childViewPulled(view)

  remove: () ->
    @$el.remove()

  destroy: (e) ->
    @model.destroy({wait: true})

  onKeypress: (e) ->
    if(e.keyCode == 13)
      @model.save()
      return false
    return true

  save: () ->
    updated = {}
    _.each(@$('input'), (el) =>
      matcher = new RegExp(@modelName + "\\[(\\w+)\\]")
      attribute_keys = matcher.exec($(el).prop('name'))
      if attribute_keys? && attribute_keys.length == 2
        updated[ attribute_keys[1] ] = $(el).val()
    )
    @model.save(updated, {wait: true})

  noSubmit: (e) ->
    e.stopPropagation()
    false

  render: () ->
    throw "Implement in subclass"


#
# Override modelName, spawnViewType and className.
#
# Implement title.
#
class ListItemView extends Backbone.View
  modelName: 'some_type'
  tagName: 'li'
  className: 'list-item'
  events:
    'click a': 'show'

  id: () ->
    "list-item-#{@model.get('id')}"

  initialize: (options) ->
    @parent = options.parent
    @listenTo(@model, 'sync', @render)
    @listenTo(@model, 'destroy', @remove)

  childViewPushed: (view) ->
    @parent.childViewPushed(view)

  childViewPulled: (view) ->
    @parent.childViewPulled(view)

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
    new @spawnViewType({model:@model, className: "#{@modelName}-view model-view", id: "#{@modelName}-view-#{@model.get('id')}", parent: @})


#
# Define className, modelName, and probably events
#
# implement render
#
class CrmModelView extends Backbone.View
  className: 'model-view'
  events:
    'keypress input': 'onKeypress'
    'submit form': 'noSubmit'
    'click button.save': 'save'
    'confirm:complete button.destroy': 'destroy'

  initialize: (options) ->
    @parent = options.parent
    @listenTo(@model, 'sync', @render)
    @listenTo(@model, 'destroy', @remove)

  childViewPulled: (view) ->
    @options.parent.childViewPulled(view)

  remove: () ->
    @$el.remove()

  destroy: (e, answer) ->
    @model.destroy({wait: true}) if answer

  onKeypress: (e) ->
    if(e.keyCode == 13)
      @save()
      return false
    return true

  save: () ->
    updated = {}
    _.each(@$(':input:visible'), (el) =>
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

class AppStack extends Backbone.View
  delay: 300

  initialize: (options) ->
    @children = [] # backbone views
    $(document).ajaxStart(() => @toBusy())
    $(document).ajaxStop(() => @toNotBusy())

    @transforms =
      out:
        left: '-50px'
        top: '-50px'
        opacity: '0.5'
      in:
        left: '0px'
        top: '0px'
        opacity: '1.0'
      incoming:
        left: '150px'
        top: '150px'
        opacity: '0.0'

    $(document).bind('keyup', (e) =>
      @childViewPulled(@children[ @children.length - 1]) if ((e.keyCode == 27) && @children.length > 1)
    )

  toBusy: () ->
    return if @children.length == 0
    @children[ @children.length - 1].$('.spinner-container').show()

  toNotBusy: () ->
    return if @children.length == 0
    @children[ @children.length - 1].$('.spinner-container').hide()

  childViewPushed: (view) ->
    if @children.length > 0
      @children[ @children.length - 1].$el
        .css(@transforms['in'])
        .animate(@transforms['out'], @delay, 'easeOutCirc', () ->
        )

    @$el.append(view.el) if @$(view.id).length == 0
    @children.push( view )
    @children[ @children.length - 1 ].$el
      .css(@transforms['incoming'])
      .animate(@transforms['in'], @delay, 'easeOutCirc', () =>
      )

  #
  # view param is used to do backbone removal.
  # it is asssmed that view.$el == @children[ @children.length - 1 ]
  #
  childViewPulled: (view) ->
    return if @children.length <= 1

    if @children.length > 1
      @children[ @children.length - 2 ].$el
        .css(@transforms['out'])
        .animate(@transforms['in'], @delay, 'easeOutCirc', () ->
       )

    lastChild = @children[ @children.length - 1 ]
    lastChild.$el
      .css(@transforms['in'])
      .animate(@transforms['incoming'], @delay, 'easeOutCirc', () =>
        view.remove()
        @children.pop()
      )

#
# Override modelName, spawnListItemType
#
# Optional override render.
#
class AppView extends Backbone.View
  events:
    'click .add-model': 'create'
    'click button.back': 'back'

  initialize: (options) ->
    @parent = options.parent
    @listenTo(@collection, 'reset', @addAll)
    @listenTo(@collection, 'add', @addOne)
    @listenTo(@collection, 'sync', @onSync)
    @listenTo(@collection, 'error', @onError)

  childViewPushed: (view) ->
    @parent.childViewPushed(view)

  childViewPulled: (view) ->
    @parent.childViewPulled(view)

  addAll: () ->
    @collection.each(@addOne, @)

  addOne: (model) ->
    listItemView = new @spawnListItemType({'model':model, 'parent': @})
    @$('.models-list').append(listItemView.render().el)

  create: () ->
    @collection.create({},
      wait: true,
      success: (model, response, options) => @afterSave(model, response, options)
    )

  modelListItemLink: (model) ->
    @$(".models-list #list-item-#{model.get('id')} a")

  afterSave: (model, response, options) ->
    @modelListItemLink(model).trigger('click')

  remove: () ->
    @$el.remove()

  back: () ->
    @parent.childViewPulled(@)

  show: (view) ->
    @$(".models-list .list-item a").removeClass('active')
    @modelListItemLink(view.model).addClass('active')

    @$('.models-show-container').hide()
    @$('.models-show-container .model-view').hide()
    @$('.models-show-container').append(view.el) if @$modelView(view.model.get('id')).length == 0
    @$modelView(view.model.get('id')).show()
    @$('.models-show-container').show()
    view.$(':input:visible').first().focus()

  $modelView: (id) ->
    @$("##{@modelName}-view-" + id)

  onSync: (model, resp, options) ->
    @$(".#{@modelName}-view:visible .control-group")
      .removeClass('error')
      .find('span.help-inline').remove()
    @$('.errors').hide()

  onError: (model, xhr, options) ->
    response = jQuery.parseJSON( xhr.responseText )
    s = ""
    _.each(response.full_messages, (m) ->
      s = "#{s} #{m}."
    )
    @$('.errors').text(s).show()

    if @$modelView(response.object.id).length != 0
      @$modelView(response.object.id)
        .removeClass('error')
        .find('span.help-inline').remove()
      _.each(response.errors, (value, key, list) =>
        @$modelView(response.object.id).find(".control-group.client_#{key}")
          .addClass('error')
          .find('.controls').append('<span class="help-inline">' + value + '</span>').end()
      )



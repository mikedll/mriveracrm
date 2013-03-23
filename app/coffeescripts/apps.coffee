
#
# Override modelName, spawnViewType and className.
#
# Implement title.
#
class ListItemView extends Backbone.View
  modelName: 'some_type'
  tagName: 'li'
  className: 'list-item'

  id: () ->
    "list-item-#{@model.get('id')}"

  initialize: (options) ->
    @events =
      'click a': 'show'
    @parent = options.parent
    @listenTo(@model, 'sync', @render)
    @listenTo(@model, 'destroy', @remove)

  childViewPushed: (view) ->
    @parent.childViewPushed(view)

  childViewPulled: (view) ->
    @parent.childViewPulled(view)

  rebindGlobalHotKeys: () ->
    @parent.rebindGlobalHotKeys()

  remove: () ->
    @$el.remove()

  show: (e) ->
    e.stopPropagation()
    if !@showview?
      @showview = @spawnView()
      @showview.render()
    @parent.show(@showview)
    false

  render: () ->
    @$el.html("<a href='#'></a>") if @$('a').length == 0
    @$('a').text(@title())
    @

  title: () ->
    @model.get('id')

  spawnView: () ->
    new @spawnViewType({model:@model, className: "#{@modelName}-view model-view", id: "#{@modelName}-view-#{@model.get('id')}", parent: @})


#
# Define className, modelName, and probably events and render
#
# implement render
#
class CrmModelView extends Backbone.View
  className: 'model-view'

  initialize: (options) ->
    @events =
      'keypress input': 'onKeypress'
      'ajax:beforeSend form': 'noSubmit'
      'click a.save': 'save'
      'confirm:complete a.destroy': 'destroy'
      'confirm:complete a.put_action': 'putAction'
    @parent = options.parent
    @listenTo(@model, 'sync', @onSync)
    @listenTo(@model, 'destroy', @remove)

  childViewPulled: (view) ->
    @options.parent.childViewPulled(view)

  rebindGlobalHotKeys: () ->
    @parent.rebindGlobalHotKeys()

  putAction: (e, answer) ->
    @model.save(@fromForm(), url: "#{@model.url()}/#{$(e.target).data('action')}", wait: true) if answer

  remove: () ->
    @$el.remove()

  destroy: (e, answer) ->
    @model.destroy({wait: true}) if answer

  onKeypress: (e) ->
    if(e.ctrlKey == false && e.keyCode == 13)
      @save()
      return false
    return true

  fromForm: () ->
    updated = {}
    _.each(@$(':input'), (el) =>
      matcher = new RegExp(@modelName + "\\[(\\w+)\\]")
      attribute_keys = matcher.exec($(el).prop('name'))
      if attribute_keys? && attribute_keys.length == 2
        updated[ attribute_keys[1] ] = $(el).val()
    )
    updated

  copyModelToForm: () ->
    _.each(@$(':input'), (el) =>
      matcher = new RegExp(@modelName + "\\[(\\w+)\\]")
      attribute_key = matcher.exec($(el).prop('name'))
      $(el).val(@model.get(attribute_key[1])) if (attribute_key? && attribute_key.length == 2 && @model.get(attribute_key[1])?)
    )

  save: () ->
    @model.save(@fromForm(), {wait: true})

  noSubmit: (e) ->
    false

  onSync: () ->
    @render()
    @parent.rebindGlobalHotKeys()

  render: () ->
    throw "Implement in subclass"


#
# Override modelName, spawnListItemType
#
# Optional override render.
#
class AppView extends Backbone.View
  initialize: (options) ->
    @events =
      'click .add-model': 'create'
      'click button.back': 'back'

    @parent = options.parent
    @listenTo(@collection, 'reset', @addAll)
    @listenTo(@collection, 'add', @addOne)
    @listenTo(@collection, 'sync', @onSync)
    @listenTo(@collection, 'error', @onError)

  childViewPushed: (view) ->
    @parent.childViewPushed(view)

  childViewPulled: (view) ->
    @parent.childViewPulled(view)

  rebindGlobalHotKeys: () ->
    @parent.rebindGlobalHotKeys()

  addAll: () ->
    @collection.each(@addOne, @)
    @$(".models-list .list-item a").first().trigger('click')

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

  move: (listItem) ->
    listItem.find('a').trigger('click') if listItem.length > 0

  next: () ->
    @move(@$(".models-list .list-item a.active").parent().next())

  previous: () ->
    @move(@$(".models-list .list-item a.active").parent().prev())

  focusTopModelView: () ->
    @$('.models-show-container .model-view:visible').find(':input:visible').first().focus()

  show: (view) ->
    @$('.errors').hide()
    @$(".models-list .list-item a").removeClass('active')
    @modelListItemLink(view.model).addClass('active')

    # lower curtain
    @$('.models-show-container').hide()

    # rearrange stage (hide other model views, show this model view)
    @$('.models-show-container .model-view').hide()
    @$('.models-show-container').append(view.el) if @$modelView(view.model.get('id')).length == 0
    @$modelView(view.model.get('id'))
      .show()

    # raise curtain and focus
    @$('.models-show-container').show()
    @focusTopModelView()
    @parent.rebindGlobalHotKeys()

  $modelView: (id) ->
    @$("##{@modelName}-view-" + id)

  onSync: (model, resp, options) ->
    @$modelView(model.get('id')).find(' .control-group')
      .removeClass('error')
      .find('span.help-inline').remove()
    if @$modelView(model.get('id')).is(':visible')
      @$modelView(model.get('id')).find(':input:visible').first().focus()

    @$('.errors').hide()

  render: () ->
    @$('h1').text(@title)
    @

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


#
# Stack of AppViews
#
class AppStack extends Backbone.View
  delay: 300

  initialize: (options) ->
    @eventHotKeys = new EventHotKeys()
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

    $(document).on('keyup.appstack', (e) =>
      return @childViewPulled(@children[ @children.length - 1]) if ((e.keyCode == 27) && @children.length > 1)

      if (e.ctrlKey)
        return @children[ @children.length - 1].previous() if( e.keyCode == 38)
        return @children[ @children.length - 1].next() if( e.keyCode == 40)
        @eventHotKeys.handleKeyUp(e)
    )

  rebindGlobalHotKeys: (container) ->
    return if @children.length == 0
    @eventHotKeys.bind( @children[ @children.length - 1 ].$el )

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
        @children[ @children.length - 1].focusTopModelView()
        @rebindGlobalHotKeys()
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
        @children[ @children.length - 1].focusTopModelView()
        @rebindGlobalHotKeys()
      )

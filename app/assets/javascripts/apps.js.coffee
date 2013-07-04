

window.AppsConfig =
  dateJsRubyDatetimeFormat: 'yyyy-MM-ddTHH:mm:ss'
  dateJsReadableDatetimeFormat: 'ddd yyyy-MM-dd h:mmtt'
  dateJsReadableDateFormat: 'ddd yyyy-MM-dd'
  datePickerDateFormat: 'D yy-mm-dd'
  datetimePickerTimeFormat: 'h:mmTT'

class window.ComparatorBuilder
  build: (attr, dir, sortType) ->
    comparator = (a,b) ->
      aa = a
      bb = b
      aaval = aa.get(attr)
      bbval = bb.get(attr)

      aNull = !aaval? || (typeof(aaval) == "string" && aaval.trim() == "")
      bNull = !bbval? || (typeof(bbval) == "string" && bbval.trim() == "")
      if aNull || bNull
        # the direction determines whether 1 means "high" or "low"
        # if ascending, then 1 means "high". if desc, -1 "high".
        # null values must always be "higher" than non-null values.
        return (if dir == 'asc' then -1 else 1) if !aNull and bNull # not null a is "greater" than null b regardless of asc or desc
        return (if dir == 'asc' then 1 else -1) if aNull and !bNull # contrapositive of above
        return 0 # both null, equivalent. will still get pushed down in a sort.

      if dir == 'desc'
        t = aaval
        aaval = bbval
        bbval = t

      # Handles types other than string
      if sortType == 'date'
        aaval = Date.parse(aaval)
        bbval = Date.parse(bbval)
      else if sortType == 'int'
        aaval = parseInt(aaval)
        bbval = parseInt(bbval)

      return 1  if aaval > bbval
      return -1 if aaval < bbval
      0

    comparator

class window.BaseView extends Backbone.View
  initialize: (options) ->
    @events = {}
    @parent = options.parent

  childViewPushed: (view) ->
    @parent.childViewPushed(view)

  childViewPulled: (view) ->
    @parent.childViewPulled(view)

  rebindGlobalHotKeys: () ->
    @parent.rebindGlobalHotKeys()

  toRubyDatetime: (val) ->
    d = Date.parse(val)
    d.toString(AppsConfig.dateJsRubyDatetimeFormat) +
      $.timepicker.timezoneOffsetString(-d.getTimezoneOffset(), true)

  toHumanReadableDateFormat: (field) ->
    date = Date.parse(@model.get(field))
    date.toString(AppsConfig.dateJsReadableDateFormat)

  toHumanReadableDateTimeFormat: (field) ->
    v = @model.get(field)
    return "" if !v?
    date = Date.parse(v)
    date.toString(AppsConfig.dateJsReadableDatetimeFormat)

class window.BaseCollection extends Backbone.Collection
  initialize: () ->
    Backbone.Collection.prototype.initialize.apply(this, arguments)
    # underscore.string does not support pluralize
    # if @parent?
    #   @url = () ->
    #     "#{@parent.url()}/#{_(@model).cain().pluralize().underscore().value()}"
    @comparator = (model) ->
      model.get('id')


class window.WithChildrenView extends BaseView
  initialize: (options) ->
    BaseView.prototype.initialize.apply(@, arguments)
    $.extend(@events, 'click a,button': 'checkDisabled')

    $(window).resize( () => @resizeView() )
    @resizeView()

  resizeView: () ->
    h = Math.max( 200, parseInt( $(window).height() * 0.8 ))
    w = Math.max(200, parseInt( $(window).width() * 0.8 ))
    @$el.css(
      'height': h + "px"
      'width': w + "px"
      'margin-left': -(w / 2) + "px"
      'margin-top': -(h / 2) + "px"
    )

  checkDisabled: (e) ->
    if $(e.target).hasClass('disabled')
      e.stopPropagation()
      return false
    return true

  focusTopModelView: () ->
    throw "Must implement in child class."

#
# Override modelName, spawnViewType and className.
#
# Implement title.
#
class window.ListItemView extends BaseView
  modelName: 'some_type'
  tagName: 'li'
  className: 'list-item'

  id: () ->
    if !@model.isNew()
      "list-item-#{@model.get('id')}"
    else
      ""

  initialize: (options) ->
    BaseView.prototype.initialize.apply(@, arguments)
    @events =
      'click a': 'show'
    @parent = options.parent
    @listenTo(@model, 'sync', @onSync)
    @listenTo(@model, 'error', @onError)
    @listenTo(@model, 'destroy', @onDestroy)
    @listenTo(@model, 'remove', @onRemove)
    @listenTo(@model, 'invalid', @onInvalid)
    @listenTo(@model, 'request', @onRequest)
    @listenTo(@model, 'resorted', @onResorted)
    @listenTo(@model, 'change', @onModelChanged)

  onRemove: () ->
    @removeDom()

  onDestroy: () ->
    @removeDom()

  onResorted: () ->
    @removeDom()

  isDirtyForThisView: () ->
    attrs = @model.changedAttributes()
    delete attrs['updated_at']
    !$.isEmptyObject(attrs)

  onModelChanged: (e) ->
    @decorateIfDirty()
    @$('a .titleText').text(@title())

  decorateIfDirty: () ->
    if @isDirtyForThisView()
      @$el.addClass('changed')
    else
      @$el.removeClass('changed')

  removeDom: () ->
    if @showview?
      @showview.remove()
    @$el.remove() # remove DOM element

  show: (e) ->
    e.stopPropagation()
    if !@showview?
      @showview = @spawnView()
      @showview.render()
    @parent.show(@showview)
    false

  render: () ->
    @$el.html("<a href='#'><span class='titleText'></span> <i class='icon-edit'></i></a>") if @$('a').length == 0
    @$('a .titleText').text(@title())
    @

  onRequest: () ->
    @$el.removeClass('error')
    @$el.addClass('requesting')

  onInvalid: () ->
    @$el.addClass('error')

  onSync: (model, resp, options) ->
    @decorateIfDirty()
    @$el.prop('id', @id()) if @$el.prop('id') == ""
    @$el.removeClass('requesting')
    @$el.removeClass('error')
    @render()

  onError: (model, xhr, options) ->
    @$el.removeClass('requesting')
    response = jQuery.parseJSON( xhr.responseText )
    @$el.addClass('error')

  title: () ->
    @model.get('id')

  spawnView: () ->
    new @spawnViewType({model:@model, className: "#{@modelName}-view model-view", parent: @})


#
# Define className, modelName, and probably events and render
#
# implement render
#
class window.CrmModelView extends BaseView
  className: 'model-view'

  id: () ->
    if !@model.isNew()
      "#{@modelName}-view-#{@model.get('id')}"
    else
      ""

  initialize: (options) ->
    BaseView.prototype.initialize.apply(@, arguments)
    @events =
      'keyup input': 'onInputChange'
      'change input': 'onInputChange'
      'ajax:beforeSend form': 'noSubmit'
      'click a.save': 'save'
      'confirm:complete a.destroy': 'destroy'
      'confirm:complete a.put_action': 'putAction'


    @parent = options.parent
    @listenTo(@model, 'sync', @onSync)
    @listenTo(@model, 'destroy', @onDestroy)
    @listenTo(@model, 'remove', @onRemove)
    @listenTo(@model, 'error', @onError)
    @listenTo(@model, 'invalid', @onInvalid)
    @listenTo(@model, 'change', @onChange)

    @attributeMatcher = new RegExp(@modelName + "\\[(\\w+)\\]")

  childViewPulled: (view) ->
    @options.parent.childViewPulled(view)

  rebindGlobalHotKeys: () ->
    @parent.rebindGlobalHotKeys()

  putAction: (e, answer) ->
    @model.save(@fromForm(), url: "#{@model.url()}/#{$(e.target).data('action')}", wait: true) if answer

  onDestroy: () ->
    @removeDom()

  onRemove: () ->
    @removeDom()

  removeDom: () ->
    @$el.remove() if @$el?

  destroy: (e, answer) ->
    @model.destroy({wait: true}) if answer

  onChange: (e) ->
    # check if view is in editing mode or not

  onInputChange: (e) ->
    if(e.ctrlKey == false && e.keyCode == 13)
      @save()
      e.stopPropagation()
      return false

    $el = $(e.target)
    if $el.is(':input')
      attribute_name = @attributeFromInput($el)
      attrs = {}
      attrs[attribute_name] = $el.val()
      @model.set(attrs)

    return true

  attributeFromInput: (elSelection) ->
    matched = @attributeMatcher.exec(elSelection.prop('name'))
    attribute_name = null
    if matched? && matched.length == 2
      attribute_name = matched[1]
    return attribute_name

  fromForm: () ->
    updated = {}
    _.each(@$(':input'), (el) =>
      $el = $(el)
      attribute_name = @attributeFromInput($el)
      if attribute_name?
        if $el.hasClass('datetimepicker') or $el.hasClass('datepicker')
          updated[ attribute_name ] = @toRubyDatetime($el.val())
        else
          updated[ attribute_name ] = $el.val()
    )
    updated

  showNestedCollectionApp: (collectionName, collectionKlass, collectionAppViewKlass) ->
    if !@[collectionName]?
      @[collectionName] = new collectionKlass()
      @[collectionName].parent = @model

    @[collectionName + 'AppView'] = new collectionAppViewKlass({parent: @, collection: @[collectionName]})
    @[collectionName + 'AppView'].render()
    @parent.childViewPushed(@[collectionName + 'AppView'])
    @[collectionName].fetch()

  copyModelToForm: () ->
    _.each(@$(':input'), (el) =>
      el$ = $(el)
      matcher = new RegExp(@modelName + "\\[(\\w+)\\]")
      attribute_key = matcher.exec(el$.prop('name'))
      if (attribute_key? && attribute_key.length == 2 && @model.get(attribute_key[1])?)
        v = @model.get(attribute_key[1])
        if el$.hasClass('datetimepicker')
          v = @toHumanReadableDateTimeFormat(attribute_key[1])
        else if el$.hasClass('hasDatepicker')
          v = @toHumanReadableDateFormat(attribute_key[1])
        el$.val(v)
    )

    _.each(@$('.read-only-field'), (el) =>
      el$ = $(el)
      attribute_key = el$.data('name')
      if (attribute_key? && @model.get(attribute_key)?)
        v = @model.get(attribute_key)
        if el$.hasClass('datetimepicker')
          v = @toHumanReadableDateTimeFormat(attribute_key)
        else if el$.hasClass('hasDatepicker')
          v = @toHumanReadableDateFormat(attribute_key)
        el$.find('.controls').text(v)
    )

    _.each( @$('.put_action, .destroy'), (el) =>
      el$ = $(el)
      enablerValue = @model.get(el$.data('attribute_enabler'))
      if enablerValue?
        if _.any( el$.data('enabled_when').toString().split(/,/), (val) -> val == enablerValue.toString())
          el$.removeClass('disabled')
        else
          el$.addClass('disabled')
    )

  save: () ->
    @clearErrors()
    @model.save(@fromForm())

  renderErrors: (errors) ->
    _.each(errors, (value, key, list) =>
      @$el
        .find(".control-group.#{@modelName}_#{key}")
        .addClass('error')
          .find('.controls').append('<span class="help-inline">' + value + '</span>')
          .end()
        .end()
      )

  onInvalid: () ->
    @renderErrors(@model.validationError) if @model.validationError?

  clearErrors: () ->
    @$el
      .removeClass('error')
      .find('span.help-inline').remove()

  onError: (model, xhr, options) ->
    response = jQuery.parseJSON( xhr.responseText )
    @clearErrors()
    @renderErrors(response.errors)

  noSubmit: (e) ->
    false

  onSync: (model, resp, options) ->
    @$el.prop('id', @id()) if @$el.prop('id') == ""
    @$el.find('.control-group')
      .removeClass('error')
      .find('span.help-inline').remove()
    @copyModelToForm()
    @$el.find(':input:visible').not('.datetimepicker, .datepicker').first().focus() if @$el.is(':visible')
    @parent.rebindGlobalHotKeys()

  render: () ->
    @$el.html($(".#{@modelName}_view_example form").clone())
    @$('input.datepicker').datepicker(
      dateFormat: AppsConfig.datePickerDateFormat
    )
    @copyModelToForm()
    @

class window.SingleModelAppView extends WithChildrenView
  focusTopModelView: () ->
    @$('.models-show-container .model-view:visible').find(':input:visible').not('.datetimepicker, .datepicker').first().focus()

  rebindGlobalHotKeys: (container) ->


#
# Override modelName, spawnListItemType
#
# Optional override render.
#
class window.CollectionAppView extends WithChildrenView
  initialize: (options) ->
    WithChildrenView.prototype.initialize.apply(@, arguments)
    @events =
      'click .add-model': 'create'
      'click button.back': 'back'
      'click a.collection-filter': 'filtersChanged'
      'click .collection-sorts': 'sortsChanged'

    @listenTo(@collection, 'reset', @addAll)
    @listenTo(@collection, 'add', @addOne)
    @listenTo(@collection, 'sync', @onSync)
    @listenTo(@collection, 'error', @onError)

  resizeView: () ->
    h = Math.max( 200, parseInt( $(window).height() * 0.8 ))
    w = Math.max(200, parseInt( $(window).width() * 0.8 ))
    @$el.css(
      'height': h + "px"
      'width': w + "px"
    )

  filtersChanged: (e) ->
    _.each( @collection.toArray(), (model) => @collection.remove(model) )
    data = {}
    _.each( @$('.collection-filter'), (el) ->
      el$ = $(el)
      if e.target == el
        # this button is about to change - we move faster than bootstrap
        # should be improved so that this entire method fires after that stuff is all done
        if !el$.hasClass('active')
          data[el$.data('filter')] = true
      else
        if el$.hasClass('active')
          data[el$.data('filter')] = true
    )
    @collection.fetch(data: data)

  sortsChanged: (e) ->
    target = $(e.target)
    @collection.comparator = (new ComparatorBuilder())
      .build(target.data('sort_attribute'), target.data('sort_direction'), target.data('sort_type'))

    @collection.sort()
    @collection.each( (model) -> model.trigger('resorted') )
    @addAll()

  addAll: () ->
    @collection.each(@addOne, @)
    @$(".models-list .list-item a").first().trigger('click')

  addOne: (model) ->
    listItemView = new @spawnListItemType({'model':model, 'parent': @})
    @$('.models-list').append(listItemView.render().el)

  create: () ->
    @collection.create({},
      wait: false,
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
    @$('.models-show-container .model-view:visible').find(':input:visible').not('.datetimepicker, .datepicker').first().focus()

  show: (view) ->
    @$('.errors').hide()
    @$(".models-list .list-item a").removeClass('active')
    @modelListItemLink(view.model).addClass('active')

    # lower curtain
    @$('.models-show-container').hide()

    # rearrange stage (hide other model views, show this model view)
    @$('.models-show-container .model-view').hide()
    @$('.models-show-container').append(view.el) if !$.contains( @$('.models-show-container').get(0), view.el)
    view.$el.show()

    # raise curtain and focus
    @$('.models-show-container').show()
    @focusTopModelView()
    @parent.rebindGlobalHotKeys()

  $modelView: (id) ->
    @$("##{@modelName}-view-" + id)

  onSync: (model, resp, options) ->
    @$('.errors').hide()

  render: () ->
    @$('h2').text(@title)
    @

  onError: (model, xhr, options) ->
    response = jQuery.parseJSON( xhr.responseText )
    s = ""
    _.chain(response.full_messages).filter((m) ->
      /\w/.test(m)
    ).each((m) ->
      s = "#{s} #{m}"
      s += "." if (!_.contains(['.', '!', '?'], m[ m.length - 1]) )
    )
    @$('.errors').text(s).show()

#
# Stack of Views
#
class window.StackedChildrenView extends WithChildrenView
  delay: 300

  initialize: (options) ->
    WithChildrenView.prototype.initialize.apply(@, arguments)
    @children = []
    @eventHotKeys = new EventHotKeys()
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

    $(document).on('keyup.stackedchildrenview', (e) =>
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

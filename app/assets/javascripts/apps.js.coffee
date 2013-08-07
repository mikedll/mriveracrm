Dropzone.autoDiscover = false;

window.AppsConfig =
  dateJsRubyDatetimeFormat: 'yyyy-MM-ddTHH:mm:ss'
  dateJsReadableDatetimeFormat: 'ddd yyyy-MM-dd h:mmtt'
  dateJsReadableDateFormat: 'ddd yyyy-MM-dd'
  datePickerDateFormat: 'D yy-mm-dd'
  datetimePickerTimeFormat: 'h:mmTT'
  fadeDuration: 1000
  balloonDuration: 2000

class window.Ballooner
  constructor: () ->
  show: (s) ->
    node = $('.apps-general-templates .flash-template .flash').clone()
    node.text(s)
    $('body').append(node)
    setTimeout( () ->
      node.fadeOut(AppsConfig.fadeDuration, () -> node.remove())
    , AppsConfig.balloonDuration)

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

class window.BaseModel extends Backbone.Model
  initialize: () ->
    Backbone.Model.prototype.initialize.apply(this, arguments)
    @_isDirty = false
    @_isInvalid = false
    @_isRequesting = false

    @_lastRequestError = null
    @_attributesSinceSync = {}
    @listenTo(@, 'invalid', @onInvalid)
    @listenTo(@, 'change', @onChange)
    @listenTo(@, 'request', @onRequest)
    @listenTo(@, 'sync', @onSync)
    @listenTo(@, 'error', @onError)

  isDirty: () ->
    return @_isDirty

  isInvalid: () ->
    return @_isInvalid

  isRequesting: () ->
    return @_isRequesting

  onInvalid: () ->
    @_isInvalid = true

  onChange: () ->
    attrs = @changedAttributes()

    # todo: should check if we are out of date
    delete attrs['updated_at']

    _.each(attrs, (value, attribute_name) =>
      if not _.has(@_attributesSinceSync, attribute_name)
        @_attributesSinceSync[attribute_name] = @previous(attribute_name)
      else if @_attributesSinceSync[attribute_name] == @get(attribute_name)
        delete @_attributesSinceSync[attribute_name]
    )
    @_isDirty = !$.isEmptyObject(@_attributesSinceSync)
    if @_isDirty
      if @validate?
        @validate(@attributes)
      @_isInvalid = false if !@validationError?
    else
      @validationError = null
      @_isInvalid = false


  changedAttributesSinceSync: () ->
    _.clone(@_attributesSinceSync)

  onRequest: () ->
    @_isRequesting = true

  onSync: () ->
    @_attributesSinceSync = {}
    @_isRequesting = false
    @_isInvalid = false
    @_isDirty = false

  onError: (model, xhr, options) ->
    @_isRequesting = false
    @_isInvalid = true
    @_lastRequestError = jQuery.parseJSON( xhr.responseText )

class window.BaseView extends Backbone.View
  initialize: (options) ->
    @events = {}
    @parent = options.parent

  childViewPushed: (view) ->
    @parent.childViewPushed(view)

  childViewPulled: (view) ->
    @parent.childViewPulled(view)

  registerDirty: (model) ->
    @parent.registerDirty(model) if @parent?

  unregisterDirty: (model) ->
    @parent.unregisterDirty(model) if @parent?

  clearHighlightedModelErrors: () ->
    @parent.clearHighlightedModelErrors() if @parent?

  rebindGlobalHotKeys: () ->
    @parent.rebindGlobalHotKeys()

  toRubyDatetime: (val) ->
    return null if val.trim() == ""
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
  initialize: (models, options) ->
    Backbone.Collection.prototype.initialize.apply(this, arguments)
    @parent = options['parent'] if _.has(options, 'parent')
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

  disableWithShield: () ->
    @$el.append($('<div class="click-shield"></div>'))
    @$('.click-shield').bind('click', (e) ->
      e.stopPropagation()
      return false
    )
    @$('a,.btn,:input').each((i, el) ->
      old = $(el).attr('tabIndex')
      $(el).data('oldTabIndex', old) if old?
      $(el).attr('tabIndex', '-1')
    )

  removeShield:() ->
    @$('.click-shield').remove()
    @$('a,.btn,:input').each((i, el) ->
      old = $(el).data('oldTabIndex')
      if old?
        $(el).attr('tabIndex', old)
      else
        $(el).removeAttr('tabIndex')
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
    @model.isDirty()

  setTitle: () ->
    s = @title()
    @$('a .titleText').text(if s? && s.trim() != "" then s else "-")

  onModelChanged: (e) ->
    @decorateDirty()
    @decorateError()
    @setTitle()

  decorateDirty: () ->
    if @model.isDirty()
      @parent.registerDirty(@model)
      @$el.addClass('dirty')
    else
      @parent.unregisterDirty(@model)
      @$el.removeClass('dirty')

  decorateRequesting: () ->
    if @model.isRequesting()
      @$el.addClass('requesting')
    else
      @$el.removeClass('requesting')

  decorateError: () ->
    if @model.isInvalid()
      @$el.addClass('error')
    else
      @$el.removeClass('error')

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
    @$el.html($('.list-item-view-title-template a').clone()) if @$('a').length == 0
    @setTitle()
    @

  clearHighlightedModelErrors: () ->
    @$el.removeClass('error')
    @parent.clearHighlightedModelErrors() if @parent?

  onRequest: () ->
    @decorateError()
    @decorateRequesting()

  onInvalid: () ->
    @decorateError()
    @decorateRequesting()

  onSync: (model, resp, options) ->
    @$el.prop('id', @id()) if @$el.prop('id') == ""
    @render()
    @decorateDirty()
    @decorateError()
    @decorateRequesting()

  onError: (model, xhr, options) ->
    @decorateError()
    @decorateRequesting()

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
    @useDirty = true
    @events =
      'keyup :input': 'onInputChange'
      'change :input': 'onInputChange'
      'ajax:beforeSend form': 'noSubmit'
      'click .btn.save': 'save'
      'confirm:complete .btn.revert': 'revert'
      'confirm:complete .btn.destroy': 'destroy'
      'confirm:complete .btn.put_action': 'putAction'


    @parent = options.parent
    @listenTo(@model, 'sync', @onSync)
    @listenTo(@model, 'destroy', @onDestroy)
    @listenTo(@model, 'remove', @onRemove)
    @listenTo(@model, 'error', @onError)
    @listenTo(@model, 'invalid', @onInvalid)
    @listenTo(@model, 'change', @onModelChanged)

    @attributeMatcher = new RegExp(@modelName + "\\[(\\w+)\\]")

    @inputsCache = []
    @readonlyInputsCache = []

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
    e.preventDefault()
    e.stopPropagation()
    @model.destroy({wait: true}) if answer
    return false

  decorateDirty: () ->
    return if !@useDirty
    changed = @model.changedAttributesSinceSync()
    @inputsCache.each((i, domEl)  =>
      el$ = $(domEl)
      attribute_name = @nameFromInput( el$ )
      if attribute_name?
        if @model.isDirty() and _.has(changed, attribute_name)
          el$.closest('.control-group').addClass('warning')
        else
          el$.closest('.control-group').removeClass('warning')
      else
        # this may not be an input related to our model
    )

    @$('.read-only-field').each((i, domEl) =>
      el$ = $(domEl)
      attribute_name = el$.data('name')
      if attribute_name? and @model.isDirty() and _.has(changed, attribute_name)
        el$.closest('.control-group').addClass('warning')
      else
        el$.closest('.control-group').removeClass('warning')
    )

    if @model.isDirty()
      @$('.save').removeClass('disabled')
      @$('.revert').removeClass('disabled')
    else
      @$('.save').addClass('disabled')
      @$('.revert').addClass('disabled')


  onModelChanged: (e) ->
    # since this is the primary editing area of this model,
    # we really don't update it just because the model changes.
    # in the event another editing area updates this,
    # more code needs to be written here.
    #
    # we assume that 1 view will update the model,
    # and other views will really utilize the validate
    # method of this.
    #
    # we do recorate the form, though.
    #
    @decorateDirty()
    if @model.validationError?
      @renderErrors(@model.validationError)
    else
      @clearErrors(@model.changedAttributes())

  onInputChange: (e) ->
    inputOwnedByMe = @inputsCache.filter(e.target)
    if inputOwnedByMe.length == 0
      return true

    if(e.ctrlKey == false && e.keyCode == 13 && !$(e.target).is('textarea'))
      @save()
      e.stopPropagation()
      return false

    nameAndValue = @nameAndValueFromInput($(e.target))
    if nameAndValue?
      attrs = {}
      attrs[nameAndValue[0]] = nameAndValue[1]
      @model.set(attrs)

    return true

  nameFromInput: (elSelection) ->
    attribute_name = null

    if elSelection.hasClass('read-only-field')
      if elSelection.data('name')?
        attribute_name = elSelection.data('name')
    else
      matched = @attributeMatcher.exec(elSelection.prop('name'))
      if matched? && matched.length == 2
        attribute_name = matched[1]
    attribute_name

  #
  # returns null if it can't get the attribute name and value
  #
  # returns [attribute_name, value] otherwise.
  #
  # e.g. ['company', 'Smith and Son']
  #
  nameAndValueFromInput: (elSelection) ->
    attribute_name = @nameFromInput(elSelection)
    if attribute_name?
      if elSelection.hasClass('datetimepicker') or elSelection.hasClass('datepicker')
        val = @toRubyDatetime(elSelection.val())
      else if elSelection.hasClass('float')
        if elSelection.val().trim() == ""
          val = null
        else
          val = parseFloat(elSelection.val())
      else if elSelection.hasClass('decimal')
        if elSelection.val().trim() == ""
          val = null
        else
          val = elSelection.val() # don't bother converting to number - may lose precision
      else if elSelection.is('[type=checkbox]')
        if elSelection.hasClass('boolean')
          val = if elSelection.prop('checked') then true else false
        else
          val = @$('input[type=checkbox][name="' + elSelection.attr('name') + '"]:checked').map(() -> $(this).val()).toArray()
      else
        val = elSelection.val()
      return [attribute_name, val]
    else
      return null

  fromForm: () ->
    updated = {}
    _.each(@$(':input'), (el) =>
      nameAndValue = @nameAndValueFromInput($(el))
      updated[ nameAndValue[0] ] = nameAndValue[1] if nameAndValue?
    )
    updated

  showNestedCollectionApp: (collectionName, collectionKlass, collectionAppViewKlass) ->
    if !@[collectionName]?
      @[collectionName] = new collectionKlass([], parent: @model)

    @[collectionName + 'AppView'] = new collectionAppViewKlass({parent: @, collection: @[collectionName]})
    @[collectionName + 'AppView'].render()

    @parent.childViewPushed(@[collectionName + 'AppView'])
    @[collectionName].reset([]) # this reset should be replaced by a full re-render of the view
    @[collectionName].fetch()

  copyModelToForm: () ->
    @inputsCache.each((i, el) =>
      el$ = $(el)
      attribute_name = @nameFromInput(el$)
      if attribute_name? && @model.get(attribute_name)?
        v = @model.get(attribute_name)
        if el$.is('[type=checkbox]') && el$.hasClass('boolean')
          el$.prop('checked', (v != "false" && v != false))
        else
          if el$.hasClass('datetimepicker')
            v = @toHumanReadableDateTimeFormat(attribute_name)
          else if el$.hasClass('hasDatepicker')
            v = @toHumanReadableDateFormat(attribute_name)
          el$.val(v)
    )

    @readonlyInputsCache.each((i, el) =>
      el$ = $(el)
      attribute_name = el$.data('name')
      if (attribute_name? && @model.get(attribute_name)?)
        v = @model.get(attribute_name)
        if el$.hasClass('datetimepicker')
          v = @toHumanReadableDateTimeFormat(attribute_name)
        else if el$.hasClass('hasDatepicker')
          v = @toHumanReadableDateFormat(attribute_name)
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

  revert: (e, answer) ->
    return if !@model.isDirty()
    if answer
      @model.set(@model.changedAttributesSinceSync())
      @copyModelToForm()
      @clearErrors()
      @clearHighlightedModelErrors()

  save: () ->
    return if !@model.isDirty()
    @clearErrors()
    @model.save()

  renderErrors: (errors) ->
    _.each(errors, (value, key, list) =>
      @$el
        .find(".control-group.#{@modelName}_#{key}")
        .addClass('error')
          .find('.controls').find('span.help-inline').remove().end().append('<span class="help-inline">' + value + '</span>')
          .end()
        .end()
      )

  onInvalid: () ->
    @renderErrors(@model.validationError) if @model.validationError?

  clearErrors: (changedAttributesw) ->
    toFix = @inputsCache

    if arguments.length > 0 and changedAttributes?
      toFix = toFix.filter((el) => _.has(changedAttributes, @nameFromInput($(el))))

    toFix
      .closest('.control-group')
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
    @clearErrors()
    @copyModelToForm()
    @decorateDirty()
    @renderErrors(@model.validationError) if @model.validationError?
    @inputsCache.filter(':visible').not('.datetimepicker, .datepicker').first().focus() if @$el.is(':visible')
    @parent.rebindGlobalHotKeys()

  buildDom: () ->
    @$el.html($(".#{@modelName}_view_example form").clone()) if @$el.children().length == 0

  render: () ->
    @buildDom()
    @inputsCache = @$(':input')
    @readonlyInputsCache = @$('.read-only-field')
    @inputsCache.filter('input.datepicker').datepicker(
      dateFormat: AppsConfig.datePickerDateFormat
    )
    @inputsCache.filter('input.datetimepicker').datetimepicker(
      dateFormat: AppsConfig.datePickerDateFormat,
      timeFormat: AppsConfig.datetimePickerTimeFormat
    )
    @copyModelToForm()
    @decorateDirty()
    @renderErrors(@model.validationError) if @model.validationError?
    @

class window.SingleModelAppView extends WithChildrenView
  focusTopModelView: () ->
    @$('.models-show-container .model-view:visible').find(':input:visible').not('.datetimepicker, .datepicker').first().focus()

  rebindGlobalHotKeys: (container) ->


#
# Override modelName, modelNamePlural, spawnListItemType
#
# Optional override render.
#
class window.CollectionAppView extends WithChildrenView
  initialize: (options) ->
    WithChildrenView.prototype.initialize.apply(@, arguments)
    @events =
      'click .add-model': 'create'
      'click button.back': 'back'
      'click .collection-filter': 'filtersChanged'
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
    if @collection.any( (model) -> model.isDirty() )
      e.stopPropagation()
      new Ballooner().show('This page has pending edits. Resolve them before changing filters.')
      return false

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
    if @collection.any( (model) -> model.isDirty() )
      e.stopPropagation()
      new Ballooner().show('This page has pending edits. Resolve them before changing sort order.')
      return false

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
    @modelsListCache.append(listItemView.render().el)

  create: () ->
    @collection.create({},
      wait: false,
      success: (model, response, options) => @afterSave(model, response, options)
    )

  modelListItemLink: (model) ->
    @modelsListCache.find("#list-item-#{model.get('id')} a")

  afterSave: (model, response, options) ->
    @modelListItemLink(model).trigger('click')

  remove: () ->
    @$el.remove()

  back: () ->
    @parent.childViewPulled(@)

  move: (listItem) ->
    listItem.find('a').trigger('click') if listItem.length > 0

  next: () ->
    @move(@modelsListCache.find(".list-item a.active").parent().next())

  previous: () ->
    @move(@modelsListCache.find(".list-item a.active").parent().prev())

  focusTopModelView: () ->
    @$('.models-show-container .model-view:visible').find(':input:visible').not('.datetimepicker, .datepicker').first().focus()

  show: (view) ->
    @$('.errors').hide()
    @modelsListCache.find(".list-item a").removeClass('active')
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
    @clearHighlightedModelErrors()

  clearHighlightedModelErrors: () ->
    @$('.errors').hide()

  buildDom: () ->
    @$el.html($(".templates .#{@modelNamePlural}_view_example").children().clone()) if @$el.children().length == 0

  cacheInitialDom: () ->
    @modelsListCache = @$('.models-list').first()

  render: () ->
    @buildDom()
    @cacheInitialDom()
    @$('.section-title').text(@title())
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
    @dirtyModels = []
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
      if ((e.keyCode == 27) && @children.length > 1)
        return @childViewPulled(@children[ @children.length - 1])

      if (e.ctrlKey)
        return @children[ @children.length - 1].previous() if( e.keyCode == 38)
        return @children[ @children.length - 1].next() if( e.keyCode == 40)
        @eventHotKeys.handleKeyUp(e)
    )

    $(window).on('beforeunload', () =>
      if _.any(@dirtyModels, (frame) -> frame.length > 0)
        return 'You have unsaved changes on this page. Are you sure you want to leave?';
    )

  registerDirty: (model) ->
    i = _.indexOf(@dirtyModels[ @dirtyModels.length - 1 ], model)
    @dirtyModels[ @dirtyModels.length - 1 ].push(model) if i == -1

  unregisterDirty: (model) ->
    i = _.indexOf(@dirtyModels[ @dirtyModels.length - 1 ], model)
    @dirtyModels[ @dirtyModels.length - 1 ].splice(i, 1) if i != -1

  noDirtyModels: () ->
    @dirtyModels[ @dirtyModels.length - 1 ].length == 0

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
      @children[ @children.length - 1].disableWithShield()
      @children[ @children.length - 1].$el
        .css(@transforms['in'])
        .animate(@transforms['out'], @delay, 'easeOutCirc', () ->
        )

    @$el.append(view.el) if @$(view.id).length == 0
    @children.push( view )
    @dirtyModels.push([])
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

    if !@noDirtyModels()
      new Ballooner().show('This page has pending edits. Resolve them before leaving this page.')
      return

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

        while @dirtyModels[ @dirtyModels.length - 1 ].length > 0
          @dirtyModels[ @dirtyModels.length - 1 ].pop()
        @dirtyModels.pop()

        @children[ @children.length - 1].removeShield()
        @children[ @children.length - 1].focusTopModelView()
        @rebindGlobalHotKeys()
      )

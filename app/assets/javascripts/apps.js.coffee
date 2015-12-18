

#
# When making practically any app, you have to have this nest:
#
# .container-fluid.gui-container  # 1
#   .container-app.app-gui        # 2
#
# The outer div (1) provides absolute styling frame of reference, and is usually
# the StackAppView, and the inner (2) app-gui provides something the user
# can actually see, the box that represents a slice of the app.
#
#
#
# Inside of this there can be as many views as you want.
#
#


Dropzone.autoDiscover = false;

window.AppsConfig =
  dateJsRubyDatetimeFormat: 'yyyy-MM-ddTHH:mm:ss'
  dateJsReadableDatetimeFormat: 'ddd yyyy-MM-dd h:mmtt'
  dateJsReadableDateFormat: 'ddd yyyy-MM-dd'
  dateJsReadonlyDateTime: 'dddd, MMMM dd, h:mmtt'
  datePickerDateFormat: 'D yy-mm-dd'
  datetimePickerTimeFormat: 'h:mmTT'
  fadeDuration: 1000
  balloonDuration: 2000
  refreshFrequency: 3000

class window.TextRenderer
  toFixed: (value, precision) ->
    precision = precision || 0
    power = Math.pow(10, precision)
    absValue = Math.abs(Math.round(value * power))
    result = (if value < 0 then '-' else '') + String(Math.floor(absValue / power))

    if precision > 0
      fraction = String(absValue % power)
      padding = new Array(Math.max(precision - fraction.length, 0) + 1).join('0')
      result += '.' + padding + fraction

    result

class window.AppsLog
  log: (s) ->
    console.log("apps: #{s}")

window.AppsLogger = new AppsLog()

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
    @_refreshTimeout = null
    @ignoredAttributes = {}

    @listenTo(@, 'invalid', @onInvalid)
    @listenTo(@, 'change', @onChange)
    @listenTo(@, 'request', @onRequest)
    @listenTo(@, 'sync', @onSync)
    @listenTo(@, 'error', @onError)
    @listenTo(@, 'destroy', @onDestroy)

    # This should be replacable with onChange
    # but onChange is not working for pollIfNeeded
    # for some reason.
    @listenTo(@, 'bootstrapped', @onBootstrapped)

    @dumpOnChange = false

  #
  # Override in subclass that is persistent requestable.
  #
  isPersistentRequestingAvailable: () ->
    true

  isPersistentRequesting: () ->
    !@isPersistentRequestingAvailable() && !@isNew()

  url: () ->
    if typeof(@urlFragment) != "undefined"
      gUrlManager.url(@urlFragment)
    else
      Backbone.Model.prototype.url.apply(@, arguments)

  isDirty: () ->
    return @_isDirty

  isInvalid: () ->
    return @_isInvalid

  isRequesting: () ->
    @_isRequesting || @isPersistentRequesting()

  onInvalid: () ->
    @_isInvalid = true

  onChange: () ->
    attrs = @changedAttributes()

    # todo: should check if we are out of date
    delete attrs['updated_at']

    # ignore any attrs we're told to...
    _.each(attrs, (v, k) =>
      if _.has(@ignoredAttributes, k)
        delete attrs[k]
    )

    _.each(attrs, (value, attribute_name) =>
      if not _.has(@_attributesSinceSync, attribute_name)
        @_attributesSinceSync[attribute_name] = @previous(attribute_name)
      else if _.isEqual(@_attributesSinceSync[attribute_name], @get(attribute_name))
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

    if @dumpOnChange
      AppsLogger.log(@attributes)

  # hook for subclasses to adjust the set attrs
  adjustSetAttrs: (attrs) ->
    attrs


  #
  # Originally overridden to handle hasrelation relations from checkboxes.
  #
  # There are so many nested loops here. This may need
  # to be performance improved with some hashes.
  #
  set: (attrs) ->
    _.each(attrs, (v, attributeName) =>
      if typeof(@hasManyRelations) != "undefined" && attributeName of @hasManyRelations
        idField = @hasManyRelations[attributeName]
        cur_related_set = @get(attributeName)
        orig_related_set = if attributeName of @_attributesSinceSync then @_attributesSinceSync[attributeName] else cur_related_set

        # if relation is already in cur relation set, preserve all current existing keys
        # and not just the foreign key.
        # (n * m) where n == size(v array) and m == size(current array value of this attribute)
        _.each(v, (relation, i) ->
          relation_before = _.find(cur_related_set, (r) -> r[idField] == relation[idField])

          if typeof(relation_before) != "undefined"
            relation = _.extend({}, relation_before, relation)

          # if key '_destroy' is present, this relation was present originally,
          # then was removed (added _destroy), then has been returned as of this set operation.
          # cancel the destroy by removing the '_destroy' key.
          if _.has(relation, '_destroy')
            delete relation['_destroy']

          v[i] = relation
        )


        # originally present. removed. mark with '_destroy'.
        # (o * n) where o == size(original value of this attribute) and n == size(v array)
        _.each(orig_related_set, (orig_relation) ->
          if not _.some(v, (relation) -> relation[idField] == orig_relation[idField])
            v.push(_.extend({}, orig_relation, {'_destroy': '1'}))
        )
    )

    @adjustSetAttrs(attrs)

    Backbone.Model.prototype.set.apply(@, [attrs])

  deepSet: (attrsArray) ->
    attrs = {}
    _.each(attrsArray, (packedAssignment, l) =>
      if !_.isArray(packedAssignment[0])
        attrs[packedAssignment[0]] = packedAssignment[1]
      else
        # need to traverse deeper into contained hash and make one
        # with the proper value set.
        curHash = @get(packedAssignment[0][0])

        _.each(packedAssignment[0].slice(1,-1), (hashIndex, i) =>
          curHash = curHash[hashIndex]
        )

        if curHash[packedAssignment[0][packedAssignment[0].length - 1]] != packedAssignment[1]

          if !_.has(attrs, packedAssignment[0][0])
            # this is tricky. don't modify the nested hash that's
            # already in the backbone model object. you have to make an
            # assignment to a new hash object, or you'll modify the
            # attributes of the backbone object directly here, even
            # though 'set' has yet to be called.
            curHash = _.clone(curHash)
          else
            # if we already constructed a new hash, there will be an
            # assignment in attrs. you can make changes to it freely.
            curHash = attrs[packedAssignment[0][0]]

          # invariant: curHash no longer points to anything associated with the original
          # backbone model object.

          curHash[packedAssignment[0][packedAssignment[0].length - 1]] = packedAssignment[1]

          attrs[packedAssignment[0][0]] = curHash

    )

    @set(attrs)

  deepGet: (attrs) ->
    return @get(attrs) if !_.isArray(attrs)

    fetched = null
    _.each(attrs, (v, i) =>
      if fetched?
        fetched = fetched[v]
      else
        fetched = @get(v)
    )
    fetched

  changedAttributesSinceSync: () ->
    _.clone(@_attributesSinceSync)

  onRequest: () ->
    @_isRequesting = true

  #
  # Use this if we're certain that a change brings this model into
  # sync with the database, even though we're not going to do a
  # sync(...)  or fetch to verify that.
  #
  # Can be used if one is confident that a change elsewhere on a view
  # has forced a change to this model in the database (rare).
  #
  setAndAssumeSync: (attrs) ->
    @set(attrs)
    @trigger('sync', @, null, {})

  pollIfNeeded: () ->
    if !@_refreshTimeout? && @isPersistentRequesting()
      @_refreshTimeout = setTimeout( () =>
        @_refreshTimeout = null
        @fetch()
      , AppsConfig.refreshFrequency)

  onSync: () ->
    # purge any destroyed attrs, before deleting history.
    retainedHasRelations = {}
    destroyingRelations = {}
    _.each(@hasManyRelations, (idField, attributeName, l) =>
      retainable = _.partition(@get(attributeName), (r) -> not _.has(r, '_destroy'))
      retainedHasRelations[attributeName] = retainable[0]
      destroyingRelations[attributeName] = retainable[1]
    )

    # purge history of destroyed to prevent _destroy additions in set(...).
    _.each(destroyingRelations, (destroyed, attributeName, l) =>
      # delete orig_set history, to prevent _destroy markings
      @unset(attributeName, silent: true)
      delete @_attributesSinceSync[attributeName]
    )

    if _.size(retainedHasRelations) > 0
      @set(retainedHasRelations) # remove those elements.

    @_attributesSinceSync = {}
    @_isRequesting = false
    @_isInvalid = false
    @_isDirty = false

    @pollIfNeeded()

  onError: (model, xhr, options) ->
    @_isRequesting = false
    @_isInvalid = true
    @_lastRequestError = jQuery.parseJSON( xhr.responseText )

  onDestroy: () ->
    clearTimeout(@_refreshTimeout) if @_refreshTimeout?
    @_isRequesting = false

  onBootstrapped: () ->
    @pollIfNeeded()

class window.BaseView extends Backbone.View
  initialize: (options) ->
    @useDirty = true

    @events =
      'click a,button': 'checkDisabled'

    @parent = options.parent if options

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

  toHumanReadableDateFormat: (dateString) ->
    date = Date.parse(dateString)
    date.toString(AppsConfig.dateJsReadableDateFormat)

  toHumanReadableDateTimeFormat: (dateString, format) ->
    return "" if !dateString?
    date = Date.parse(dateString)
    date.toString(if typeof(format) != "undefined" then AppsConfig[format] else AppsConfig.dateJsReadableDatetimeFormat)

  checkDisabled: (e) ->
    if $(e.target).hasClass('disabled')
      e.stopPropagation()
      e.stopImmediatePropagation()
      return false
    return true

  notifyRequestStarted: (e) ->
    @parent.notifyRequestStarted() if @parent?

  notifyRequestCompleted: (e) ->
    @parent.notifyRequestCompleted() if @parent?

class window.ModelBaseView extends BaseView
  initialize: (options) ->
    BaseView.prototype.initialize.apply(@, arguments)

    @listenTo(@model, 'change', @onModelChanged)
    @listenTo(@model, 'request', @onRequest)
    @listenTo(@model, 'sync', @onSync)
    @listenTo(@model, 'error', @onError)
    @listenTo(@model, 'destroy', @onDestroy)

  detachFromModel: () ->
    @stopListening(@model)

  dirtyRegistration: () ->
    return if !@useDirty
    if @model.isDirty()
      @parent.registerDirty(@model)
    else
      @parent.unregisterDirty(@model)

  decorateDirty: () ->

  decorateError: () ->

  decorateRequesting: () ->

  copyModelToForm: () ->
    throw "Override in base class of ModelBaseView."

  repaintEditable: () ->
    @copyModelToForm()

  repaintNonEditable: () ->
    @decorateDirty()
    @decorateError()
    @decorateRequesting()
    @resolveButtonAvailability()

  onModelChanged: (e) ->
    @dirtyRegistration()
    @resolveButtonAvailability()

  onRequest: (model, xhr, options) ->
    if @model.isRequesting()
      @notifyRequestStarted()
    @resolveButtonAvailability()

  onDestroy: (model, resp, options) ->
    if !@model.isRequesting() && !@model.isNew() # isNew() => a request just finished to delete this on the server
      @notifyRequestCompleted()

  onSync: (model, resp, options) ->
    if !@model.isRequesting()
      @notifyRequestCompleted()
    @resolveButtonAvailability()
    @dirtyRegistration()

  onError: (model, resp, options) ->
    if !@model.isRequesting()
      @notifyRequestCompleted()
    @resolveButtonAvailability()

  resolveButtonAvailability: () ->
    if @model.isRequesting() || !@model.isDirty()
      @$('.save, .revert').addClass('disabled')
    else
      @$('.save, .revert').removeClass('disabled')


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

    @listenTo(@, 'reset', @onReset)

  url: () ->
    if typeof(@urlFragment) != "undefined"
      gUrlManager.url(@urlFragment)
    else
      Backbone.Collection.prototype.url.apply(@, arguments)

  onReset: () ->
    @each((model) -> model.trigger('bootstrapped'))

class window.WithChildrenView extends BaseView
  initialize: (options) ->
    BaseView.prototype.initialize.apply(@, arguments)

    $(window).resize( () => @resizeView() )
    @resizeView()

  resizeView: () ->
    h = Math.max(200, Math.round( $(window).height() * 0.8 ))
    w = Math.max(200, Math.round( $(window).width() * 0.8 ))
    @$el.css(
      'height': h + "px"
      'width': w + "px"
      'margin-left': -(w / 2) + "px"
      'margin-top': -(h / 2) + "px"
    )

    multiplier = if @$('.app-top .btn-group').length > 0 then 0.8 else 0.95
    interiorHeight = Math.round(h * multiplier) + 'px'
    @$('.models-list').css(
      'height': interiorHeight
    )

    @$('.model-show-container').css(
      'height': interiorHeight
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

  focusTopModelView: () ->
    throw "Must implement in child class."

#
# Override modelName, spawnViewType and className.
#
# Implement title.
#
class window.ListItemView extends ModelBaseView
  modelName: 'some_type'
  tagName: 'li'
  className: 'list-item'

  initialize: (options) ->
    ModelBaseView.prototype.initialize.apply(@, arguments)
    @events = $.extend(@events,
      'click a': 'show'
    )

    @parent = options.parent
    # 'sync', 'change', 'request', 'destroy', and 'error' are in ModelBaseView
    @listenTo(@model, 'remove', @onRemove)
    @listenTo(@model, 'invalid', @onInvalid)
    @listenTo(@model, 'resorted', @onResorted)

  onRemove: () ->
    @removeDom()

  onDestroy: () ->
    ModelBaseView.prototype.onDestroy.apply(@, arguments)
    @removeDom()

  onResorted: () ->
    @removeDom()

  isDirtyForThisView: () ->
    @model.isDirty()

  setTitle: () ->
    s = @title()
    @$('a .titleText').text(if s? && s.trim() != "" then s else "-")

  repaintNonEditable: () ->
    ModelBaseView.prototype.repaintNonEditable.apply(@, arguments)
    @setTitle()

  onModelChanged: (e) ->
    ModelBaseView.prototype.onModelChanged.apply(@, arguments)
    @repaintNonEditable()

  decorateDirty: () ->
    if @model.isDirty()
      @$el.addClass('dirty')
    else
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
    @detachFromModel()
    if @modelView?
      @modelView.remove()
    @$el.remove() # remove DOM element

  show: (e) ->
    e.stopPropagation()
    if !@modelView?
      @modelView = @spawnView()
      @modelView.render()
    @parent.show(@, @modelView)
    false

  render: () ->
    @$el.html($('.list-item-view-title-template a').clone()) if @$('a').length == 0
    @repaintNonEditable()
    @

  clearHighlightedModelErrors: () ->
    @$el.removeClass('error')
    @parent.clearHighlightedModelErrors() if @parent?

  onRequest: () ->
    ModelBaseView.prototype.onRequest.apply(@, arguments)
    @repaintNonEditable()

  onInvalid: () ->
    @repaintNonEditable()

  onSync: (model, resp, options) ->
    ModelBaseView.prototype.onSync.apply(@, arguments)
    @render()

  onError: (model, resp, options) ->
    ModelBaseView.prototype.onError.apply(@, arguments)
    @decorateError()
    @decorateRequesting()

  title: () ->
    @model.get('id')

  spawnView: () ->
    new @spawnViewType({model:@model, className: "#{@modelName}-view model-view", parent: @})

  activate: () ->
    @$('a').addClass('active')
    @modelView.delegateEvents()

  deactivate: () ->
    @modelView.undelegateEvents()
    @$('a').removeClass('active')


#
# Define className, modelName, and probably events and render
#
# implement render
#
# set useDirty = false if you don't want dirty records support.
#
class window.CrmModelView extends ModelBaseView
  className: 'model-view'

  initialize: (options) ->
    ModelBaseView.prototype.initialize.apply(@, arguments)
    @events = $.extend(@events,
      'keyup :input': 'onInputChange'
      'change :input': 'onInputChange'
      'ajax:beforeSend form': 'noSubmit'
      'click .btn.save': 'save'
      'click button[type=button][data-confirm]': 'startConfirmation'
      'confirm:complete .btn.revert': 'revert'
      'confirm:complete .btn.destroy': 'destroy'
      'confirm:complete .btn.put_action': 'putActionConfirmed'
      'click .btn.put_action:not([data-confirm])': 'putAction'
      'click .refresh': 'refresh'
    )

    @parent = options.parent
    # 'sync', 'change', 'error', 'destroy', and 'request' are in ModelBaseView
    @listenTo(@model, 'remove', @onRemove)
    @listenTo(@model, 'invalid', @onInvalid)

    @attributeMatcher = new RegExp("^" + @modelName + "\\[(\\w+)\\]")
    @subAttributeMatcher = new RegExp("\\[(\\w+)\\]")
    @textRenderer = new TextRenderer()

    @inputsCache = $([])
    @readonlyInputsCache = $([])

  childViewPulled: (view) ->
    @options.parent.childViewPulled(view)

  rebindGlobalHotKeys: () ->
    @parent.rebindGlobalHotKeys()

  inputFor$: (attributeName, readOnly) ->
    readOnly = readOnly || true
    toSearch = if readOnly then @readonlyInputsCache else @inputsCache.add(@readonlyInputsCache)
    input =_.find(toSearch, (el) => @nameFromInput($(el)) == attributeName)
    if typeof(input) == "undefined"
      AppsLogger.log("CrmModelView.inputFor failed to find input for attribute named #{attributeName}")
      return input
    else
      return $(input)

  putAction: (e) ->
    return false if @buttonsCache.filter(e.target).length == 0
    @model.save(@fromForm(), url: "#{@model.url()}/#{$(e.target).data('action')}", wait: true)

  putActionConfirmed: (e, answer) ->
    return false if @buttonsCache.filter(e.target).length == 0
    @putAction(e) if answer

  refresh: () ->
    @model.fetch()

  onDestroy: () ->
    ModelBaseView.prototype.onDestroy.apply(@, arguments)
    @removeDom()

  onRemove: () ->
    @removeDom()

  removeDom: () ->
    @detachFromModel()
    @parent = null # remove pointer to parent.
    @$el.remove() if @$el? # isn't this event redundant? review with onDestroy event. http://backbonejs.org/#View-remove

  destroy: (e, answer) ->
    return false if @buttonsCache.filter(e.target).length == 0
    e.preventDefault()
    e.stopPropagation()
    @model.destroy({wait: true}) if answer
    return false

  decorateDirty: () ->
    return if !@useDirty

    if !@model.isDirty()
      @inputsCache.each((i, domEl)  =>
        $(domEl).closest('.control-group,.inline-control-group').removeClass('warning')
      )
    else
      current = @model.attributes
      changed = @model.changedAttributesSinceSync()
      @inputsCache.each((i, domEl)  =>
        el$ = $(domEl)
        attributeName = @nameFromInput( el$ )
        if attributeName?
          markChanged = false
          if _.isArray(attributeName)
            changedO = changed[attributeName[0]]
            currentO = current[attributeName[0]]
            if typeof(changedO) != "undefined"
              _.each(attributeName.slice(1,-1), (el, i) =>
                currentO = currentO[el]
                changedO = changedO[el]
              )
              if changedO[attributeName[attributeName.length - 1]] != currentO[attributeName[attributeName.length - 1]]
                markChanged = true
          else if _.has(changed, attributeName)
            markChanged = true

          if markChanged
            el$.closest('.control-group,.inline-control-group').addClass('warning')
          else
            el$.closest('.control-group,.inline-control-group').removeClass('warning')
        else
          # this may not be an input related to our model
      )

    @readonlyInputsCache.each((i, domEl) =>
      el$ = $(domEl)
      attributeName = @nameFromInput(el$, true)
      # todo: this is dirty code. You're using changed which is only coincidentally
      # defined above when @model.isDirty() is true.
      if attributeName? and @model.isDirty() and _.has(changed, attributeName)
        el$.closest('.control-group').addClass('warning')
      else
        el$.closest('.control-group').removeClass('warning')
    )

  onModelChanged: (e) ->
    # since this is the primary editing area of this model,
    # we don't update it when the model changes.
    # in the event another editing area updates this,
    # more code needs to be written here.
    #
    # we assume that 1 view will update the model,
    # and other views will really utilize the validate
    # method of this.
    #
    # we do recorate the form, though.
    #
    ModelBaseView.prototype.onModelChanged.apply(@, arguments)
    @copyReadOnlyFieldsToForm()
    @decorateDirty()
    if @model.validationError?
      @decorateError()
    else
      @clearErrors(@model.changedAttributes())

  onInputChange: (e) ->
    # prevent inputs from a different contained model from modifying this one
    return true if @inputsCache.filter(e.target).length == 0


    if e.keyCode == 13
      if $(e.target).is('button')
        return false # ignore 'enter' on a button key. it will be triggered elsewhere.

      if(e.ctrlKey == false && !$(e.target).is('textarea'))
        e.stopPropagation()
        e.preventDefault()
        @save()
        return false

    nameAndValue = @nameAndValueFromInput($(e.target))
    @model.deepSet([nameAndValue]) if nameAndValue?

    return true

  nameFromInput: (elSelection, readOnly) ->
    attributeName = null
    readOnly = readOnly || elSelection.hasClass('read-only-field')

    n = ""
    if readOnly && elSelection.data('name')?
      n = elSelection.data('name')
    else
      n = elSelection.prop('name')

    cumulativeMatchedLength = 0
    matched = @attributeMatcher.exec(n)

    while matched? && matched.length == 2 && cumulativeMatchedLength != n.length
      if !attributeName?
        attributeName = matched[1]
      else if _.isArray(attributeName)
        attributeName.push(matched[1])
      else
        attributeName = [attributeName, matched[1]]

      cumulativeMatchedLength += matched[0].length
      matched = @subAttributeMatcher.exec(n.substring(cumulativeMatchedLength, n.length))

    attributeName

  #
  # returns null if it can't get the attribute name and value
  #
  # returns [attributeName, value] otherwise.
  #
  # e.g. ['company', 'Smith and Son']
  #
  nameAndValueFromInput: (elSelection) ->
    attributeName = @nameFromInput(elSelection)
    if attributeName?
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
        else if elSelection.hasClass('has-many-relation') && typeof(@model.hasManyRelations) != "undefined"
          id_field = @model.hasManyRelations[attributeName]
          val = @$('input[type=checkbox][name="' + elSelection.attr('name') + '"]:checked').map(() ->
            h = {}
            h[id_field] = parseInt($(this).val())
            h
          ).toArray()

        else
          val = @$('input[type=checkbox][name="' + elSelection.attr('name') + '"]:checked').map(() -> $(this).val()).toArray()
      else
        val = elSelection.val()
      return [attributeName, val]
    else
      return null

  fromForm: () ->
    updated = {}
    _.each(@inputsCache, (el) =>
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

  copyReadOnlyFieldsToForm: () ->
    @readonlyInputsCache.each((i, el) =>
      el$ = $(el)
      attributeName = @nameFromInput(el$, true)
      if attributeName? && @model.deepGet(attributeName)?
        v = @model.deepGet(attributeName)
        if el$.hasClass('datetime')
          v = @toHumanReadableDateTimeFormat(v, 'dateJsReadonlyDateTime')
        else if el$.hasClass('date')
          v = @toHumanReadableDateFormat(v)
        else if el$.hasClass('currency')
          v = "$#{@textRenderer.toFixed(v, 2)}"
        el$.text(v)
    )

  copyModelToForm: () ->
    @inputsCache.each((i, el) =>
      el$ = $(el)
      attributeName = @nameFromInput(el$, false)
      if attributeName? && @model.deepGet(attributeName)?
        v = @model.deepGet(attributeName)
        if el$.is('[type=checkbox]') && el$.hasClass('boolean')
          el$.prop('checked', (v != "false" && v != false))
        else if el$.is('[type=checkbox]') && el$.hasClass('has-many-relation')
          idField = if (typeof(@model.hasManyRelations) != "undefined" and (attributeName of @model.hasManyRelations)) then @model.hasManyRelations[attributeName] else 'id'
          valAsInt = parseInt(el$.val())
          if Object.prototype.toString.call( v ) == '[object Array]'
            el$.prop('checked', _.some(v, (related) -> related[idField] == valAsInt && not _.has(related, '_destroy')))
          else
            el$.prop('checked', v[idField] == valAsInt)
        else
          if el$.hasClass('datetimepicker')
            v = @toHumanReadableDateTimeFormat(v)
          else if el$.hasClass('hasDatepicker')
            v = @toHumanReadableDateFormat(v)
          else if el$.hasClass('currency')
            v = "$#{@textRenderer.toFixed(v, 2)}"
          el$.val(v)
    )

    @copyReadOnlyFieldsToForm()

    _.each( @$('.put_action, .destroy'), (el) =>
      el$ = $(el)
      enablerValue = @model.deepGet(el$.data('attribute_enabler'))
      enabledWhenValue = el$.data('enabled_when')
      if enablerValue?
        if (_.isString(enabledWhenValue) && _.any( enabledWhenValue.split(/,/), (val) -> val == enablerValue)) || (typeof(enabledWhenValue) != "undefined" && enablerValue == enabledWhenValue) || (typeof(enabledWhenValue) == "undefined" && enablerValue != false)
          el$.removeClass('disabled')
        else
          el$.addClass('disabled')
    )

  startConfirmation: (e) ->
    # we do this because type => button on the %button tag disables
    # the rails UJS handling of the confirm event.
    element = $(e.target)
    message = element.data('confirm')

    if !message?
      return true

    if ($.rails.fire(element, 'confirm'))
      answer = $.rails.confirm(message);
      callback = $.rails.fire(element, 'confirm:complete', [answer]);

    return answer && callback

  revert: (e, answer) ->
    return false if @buttonsCache.filter(e.target).length == 0

    return if !@model.isDirty()
    if answer
      @model.set(@model.changedAttributesSinceSync())
      @copyModelToForm()
      @clearErrors()
      @clearHighlightedModelErrors()

  save: () ->
    # todo: This should be compressed if useDirty
    # can be use to determine that fromForm should be called,
    # and that isDirty must make use of it.
    if @useDirty
      return if !@model.isDirty()
      @clearErrors()
      @model.save()
    else
      @clearErrors()
      @model.save(@fromForm)

  decorateError: (errors) ->
    renderErrors(@model.validationError) if @model.validationError?

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
    @repaintNonEditable()

  clearErrors: (changedAttributesw) ->

    @$('.errors').hide() # full messages

    toFix = @inputsCache

    if arguments.length > 0 and changedAttributes?
      toFix = toFix.filter((el) => _.has(changedAttributes, @nameFromInput($(el))))

    toFix
      .closest('.control-group')
        .removeClass('error')
        .find('span.help-inline').remove()


  renderFullMessages: (response) ->
    s = ""
    _.chain(response.full_messages).filter((m) ->
      /\w/.test(m)
    ).each((m) ->
      s = "#{s} #{m}"
      s += "." if (!_.contains(['.', '!', '?'], m[ m.length - 1]) )
    )
    @$('.errors').text(s).show()

  onError: (model, xhr, options) ->
    ModelBaseView.prototype.onError.apply(@, arguments)
    response = jQuery.parseJSON( xhr.responseText )
    @clearErrors()
    @renderFullMessages(response)
    @renderErrors(response.errors)

  noSubmit: (e) ->
    false

  onRequest: (model, xhr, options) ->
    ModelBaseView.prototype.onRequest.apply(@, arguments)

  resetInputDevice: () ->
    @inputsCache.filter(':visible').not('.datetimepicker, .datepicker').first().focus() if @$el.is(':visible')

  onSync: (model, resp, options) ->
    ModelBaseView.prototype.onSync.apply(@, arguments)
    @clearErrors()
    @repaintEditable()
    @repaintNonEditable()
    @resetInputDevice()
    @parent.rebindGlobalHotKeys()

  buildDom: () ->
    @$el.html($(".#{@modelName}_view_example form").clone()) if @$el.children().length == 0

  render: () ->
    @buildDom()
    @buttonsCache = @$('.btn')
    @inputsCache = @$(':input')
    @readonlyInputsCache = @$('.read-only-field')
    @inputsCache.filter('input.datepicker').datepicker(
      dateFormat: AppsConfig.datePickerDateFormat
    )
    @inputsCache.filter('input.datetimepicker').datetimepicker(
      dateFormat: AppsConfig.datePickerDateFormat,
      timeFormat: AppsConfig.datetimePickerTimeFormat
    )
    @repaintEditable()
    @repaintNonEditable()
    @resetInputDevice()
    @

class window.SingleModelAppView extends WithChildrenView

  initialize: (options) ->
    WithChildrenView.prototype.initialize.apply(@, arguments)
    @modelView = null
    @modelShowContainer = null

  resizeView: () ->
    # Override to prevent drastic resizing
    h = Math.max( 200, parseInt( $(window).height() * 0.8 ))
    w = Math.max(200, parseInt( $(window).width() * 0.8 ))
    @$el.css(
      'height': h + "px"
      'width': w + "px"
    )

  focusTopModelView: () ->
    @modelShowContainer.find('.model-view:visible :input:visible').not('.datetimepicker, .datepicker').first().focus()

  rebindGlobalHotKeys: (container) ->

  showModelView: () ->
    @modelShowContainer.append(@modelView.render().el) if @modelShowContainer? && @modelShowContainer.length > 0 && !$.contains( @modelShowContainer.get(0), @modelView.el)

  #
  # Become the parent of a view.
  #
  husband: (view) ->
    if !@modelView?
      @modelView = view
      @modelView.parent = @
    else if @modelView != view
      @modelView.remove()
      @modelView = view
      @modelView.parent = @

  #
  # Become the parent of the view and show it.
  #
  # It's possible to show a view before this view has been rendered.
  #
  show: (view) ->
    @husband(view)
    @showModelView()

  render: () ->
    WithChildrenView.prototype.render.apply(@, arguments)
    @modelShowContainer = @$('.model-show-container').first()
    @showModelView()
    @

#
# Needs to have its behavior refactored
#
class window.SearchAndListView extends BaseView
  initialize: (options) ->
    BaseView.prototype.initialize.apply(@, arguments)

    @events = $.extend(@events,
      'click .collection-filter': 'filtersChanged'
      'click .collection-sorts': 'sortsChanged'
    )

    @listenTo(@collection, 'reset', @addAll)
    @listenTo(@collection, 'add', @addOne)
    @listenTo(@collection, 'sync', @onSync)
    @listenTo(@collection, 'error', @onError)

  detachFromCollection: () ->
    @stopListening(@collection)

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

  addOne: (model) ->
    itemView = new @searchResultItemViewType({'model':model, 'parent': @})
    @$listItems.append(itemView.render().el)
    itemView.$('a').trigger('click') if !@$listItems.children().length == 1

  remove: () ->
    @detachFromCollection()
    @$el.remove()

  next: () ->
    # noop
  previous: () ->
    # noop

  focusTopModelView: () ->
    # noop

  buildDom: () ->
    @$el.html($(".templates .#{@modelNamePlural}_view_example").children().clone()) if @$el.children().length == 0

  cacheInitialDom: () ->
    @$listItems = @$('.models-list').first()

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
      'keyup input.quickfilter': 'quickfilterAdjust'

    @listenTo(@collection, 'reset', @addAll)
    @listenTo(@collection, 'add', @addOne)
    @listenTo(@collection, 'sync', @onSync)
    @listenTo(@collection, 'error', @onError)
    @currentModelListItem = null

  quickfilterAdjust: (e) ->
    s = $(e.target).val().toLowerCase()
    rtext = ""
    _.each(s, (c) ->
      rtext += c + ".*"
    )
    tester = new RegExp(rtext)
    @$listItems.find(".list-item").each((i, el) ->
      if tester.test($(el).text().toLowerCase())
        $(el).show()
      else
        $(el).hide()
    )

  detachFromCollection: () ->
    @stopListening(@collection)

  resizeView: () ->
    h = Math.max(200, Math.round( $(window).height() * 0.8 ))
    w = Math.max(200, Math.round( $(window).width() * 0.8 ))
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
    @$listItems.find(".list-item").first().find('a').trigger('click')

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

  addOne: (model) ->
    listItemView = new @spawnListItemType({'model':model, 'parent': @})
    @$listItems.append(listItemView.render().el)
    listItemView.$('a').trigger('click') if @$('.model-show-container').children().length == 0

  create: () ->
    @collection.create({},
      wait: false
      success: (model, response, options) => @afterCreate(model, response, options)
    )

  afterCreate: (model, response, options) ->
    @$listItems.find('.list-item').last().find('a').trigger('click')

  remove: () ->
    @detachFromCollection
    @$el.remove()

  back: () ->
    @parent.childViewPulled(@)

  move: (listItem) ->
    listItem.find('a').trigger('click') if listItem.length > 0

  next: () ->
    @move(@$listItems.find(".list-item a.active").parent().nextAll('.list-item').filter(':visible').first())

  previous: () ->
    @move(@$listItems.find(".list-item a.active").parent().prevAll('.list-item').filter(':visible').first())

  focusTopModelView: () ->
    @$('.model-show-container .model-view').first().find(':input:visible').not('.datetimepicker, .datepicker').first().focus()

  show: (listItem, view) ->
    @$('.errors').hide()

    if not @currentModelListItem? || @currentModelListItem != listItem
      @currentModelListItem.deactivate() if @currentModelListItem?
      @currentModelListItem = listItem
      @currentModelListItem.activate()
      @$('.model-show-container').empty()
      @$('.model-show-container').append(view.el)

    # raise curtain and focus
    @focusTopModelView()
    @parent.rebindGlobalHotKeys()

  onSync: (model, resp, options) ->
    @clearHighlightedModelErrors()

  clearHighlightedModelErrors: () ->
    @$('.errors').hide()

  buildDom: () ->
    @$el.html($(".templates .#{@modelNamePlural}_view_example").children().clone()) if @$el.children().length == 0

  cacheInitialDom: () ->
    @$listItems = @$('.models-list').first()

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

  notifyRequestStarted: () ->
    @toBusy()

  toNotBusy: () ->
    return if @children.length == 0
    @children[ @children.length - 1].$('.spinner-container').hide()

  notifyRequestCompleted: () ->
    @toNotBusy()

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

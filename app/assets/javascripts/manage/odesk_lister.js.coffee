
class window.ODeskLister extends BaseModel
  defaults:
    'runnable?': false

  isPersistentRequestingAvailable: () ->
    @deepGet('available_for_request?')

class window.ODeskListerView extends CrmModelView
  modelName: 'odesk_lister'

  initialize: (options) ->
    CrmModelView.prototype.initialize.apply(@, arguments)
    @listenTo(@model, 'change', @showHideSensitive)

  render: () ->
    CrmModelView.prototype.render.apply(@, arguments)
    @showHideSensitive()

  showHideSensitive: () ->
    lastError$ = @inputFor$('last_error')
    if @model.get('last_error') == ""
      lastError$.closest('.control-group').hide()
    else
      lastError$.closest('.control-group').show()

class window.ODeskListers extends BaseCollection
  model: ODeskLister
  urlFragment: '/manage/odesk_listers'

class window.ODeskListerListItemView extends ListItemView
  modelName: 'odesk_lister'
  spawnViewType: ODeskLister
  className: 'odesk-lister-list-item list-item'

  title: () ->
    @model.get('name')

class window.ODeskListerAppView extends CollectionAppView
  modelNamePlural: 'odesk_listers'
  modelName: 'odesk_lister'
  spawnListItemType: ODeskListerListItemView
  title: () ->
    'ODesk Listers'

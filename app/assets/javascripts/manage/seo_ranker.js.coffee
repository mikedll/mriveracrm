
class window.SEORanker extends BaseModel
  defaults:
    'runnable?': false

  isRequesting: () ->
    @_isRequesting || (!@get('available_for_request?') && !@isNew())

class window.SEORankerView extends CrmModelView
  modelName: 'seo_ranker'

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

class window.SEORankers extends BaseCollection
  model: SEORanker
  urlFragment: '/manage/seo_rankers'

class window.SEORankerListItemView extends ListItemView
  modelName: 'seo_ranker'
  spawnViewType: SEORankerView
  className: 'seo-ranker-list-item list-item'

  title: () ->
    @model.get('name')

class window.SEORankerAppView extends CollectionAppView
  modelNamePlural: 'seo_rankers'
  modelName: 'seo_ranker'
  spawnListItemType: SEORankerListItemView
  title: () ->
    'SEO Rankers'

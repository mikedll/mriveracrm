
class window.SEORanker extends BaseModel
  defaults:
    'runnable?': false

class window.SEORankerView extends CrmModelView
  modelName: 'seo_ranker'

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


class window.SeoRanker extends BaseModel

class window.SeoRankerView extends CrmModelView
  modelName: 'seo_ranker'

class window.SeoRankers extends BaseCollection
  model: SeoRanker
  urlFragment: '/manage/seo_rankers'

class window.SeoRankerListItemView extends ListItemView
  modelName: 'seo_ranker'
  spawnViewType: SeoRankerView
  className: 'seo-ranker-list-item list-item'

  title: () ->
    @model.get('name')

class window.SeoRankerAppView extends CollectionAppView
  modelNamePlural: 'seo_rankers'
  modelName: 'seo_ranker'
  spawnListItemType: SeoRankerListItemView
  title: () ->
    'SEO Rankers'


class window.Page extends BaseModel

class window.PageView extends CrmModelView
  modelName: "page"

class window.Pages extends BaseCollection
  model: Page
  urlFragment: '/manage/pages'

class window.PageListItemView extends ListItemView
  modelName: "page"
  spawnViewType: PageView
  className: 'list-item page'

  title: () ->
    @model.get("title")

class window.PageCollectionAppView extends CollectionAppView
  modelName: "page"
  modelNamePlural: "pages"
  spawnListItemType: PageListItemView
  title: ->
    "Pages"

class window.StubbedPage extends BaseModel

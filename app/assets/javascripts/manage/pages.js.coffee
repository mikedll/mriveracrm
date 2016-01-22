
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

class window.StubbedPage extends BaseModel

class window.StubbedPages extends BaseCollection
  model: StubbedPage
  urlFragment: '/manage/link_orderings'

class window.StubbedPageView extends CrmModelView
  modelName: "stubbed_page"

class window.StubbedPageListItemView extends ListItemView
  modelName: 'stubbed_page'
  spawnViewType: StubbedPageView
  className: 'list-item stubbed-page'

  title: () ->
    @model.get('referenced_link')

class window.PageCollectionAppView extends HeterogeneousCollectionAppView
  modelName: "page"
  modelNamePlural: "pages"
  spawnListItemType: PageListItemView
  spawnListItemType2: StubbedPageListItemView
  title: ->
    "Pages"

  initialize: (options) ->
    HeterogeneousCollectionAppView.prototype.initialize.apply(@, arguments)
    @collection2 = new StubbedPages()
    @listenTo(@collection2, 'reset', @addAll2)
    @listenTo(@collection2, 'add', @addOne2)
    @listenTo(@collection2, 'sync', @onSync)
    @listenTo(@collection2, 'error', @onError)

  addOne: (model) ->
    @addOneWithKlass(model, @spawnListItemType)

  addOne2: (model) ->
    @addOneWithKlass(model, @spawnListItemType2)

  addAll2: () ->
    @collection2.each(@addOne2, @)

  customSetup: () ->
    @collection2.reset(__link_orderings)

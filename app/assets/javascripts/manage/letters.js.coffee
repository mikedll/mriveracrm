
class window.Letter extends BaseModel

class window.LetterView extends CrmModelView
  modelName: 'letter'
  initialize: () ->
    CrmModelView.prototype.initialize.apply(@, arguments)
    @events = $.extend(@events,
      'click a.preview': 'showPreview'
    )

  showPreview: () ->
    @showNestedModelApp('letter_preview', LetterPreview, LetterPreviewView, SingleModelAppView)

class window.Letters extends BaseCollection
  model: Letter
  urlFragment: '/manage/letters'

class window.LetterListItemView extends ListItemView
  modelName: 'letter'
  spawnViewType: LetterView
  className: 'letter-list-item'

  title: () ->
    @model.deepGet('title')

class window.LetterAppView extends CollectionAppView
  modelName: 'letter'
  modelNamePlural: 'letters'
  spawnListItemType: LetterListItemView

  title: () ->
    "Letters"

class window.LetterPreview extends BaseModel
  initialize: () ->
    BaseModel.prototype.initialize.apply(this, arguments)
    @url = () =>
      "#{@parent.url()}/preview"

class window.LetterPreviewView extends CrmModelView
  modelName: 'letter_preview'

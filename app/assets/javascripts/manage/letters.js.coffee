
class window.Letter extends BaseModel

class window.LetterView extends CrmModelView
  modelName: 'letter'

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

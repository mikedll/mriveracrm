
class window.Business extends BaseModel
  url: () ->
    gUrlManager.url('/manage/business')

  validate: (attrs, options) ->
    if !attrs.name? || attrs.name.trim() == ""
      return {name: 'cannot be blank'}
    return

  isNew: () ->
    false

class window.BusinessView extends CrmModelView
  modelName: 'business'

  onDestroy: () ->
    CrmModelView.prototype.onDestroy.apply(@, arguments)
    window.location = '/'

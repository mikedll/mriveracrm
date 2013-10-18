
class window.Business extends BaseModel
  url: () ->
    '/manage/business'

  validate: (attrs, options) ->
    if !attrs.name? || attrs.name.trim() == ""
      return {name: 'cannot be blank'}
    return


class window.BusinessView extends CrmModelView
  modelName: 'business'


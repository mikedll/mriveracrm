
class window.BillingSettings extends BaseModel
  url: () ->
    gUrlManager.url('/manage/billing_settings')

  validate: (attrs, options) ->
    if !attrs.name? || attrs.name.trim() == ""
      return {name: 'cannot be blank'}
    return


class window.BillingSettingsView extends CrmModelView
  modelName: 'billing_settings'

  onDestroy: () ->
    CrmModelView.prototype.onDestroy.apply(@, arguments)
    window.location = '/'

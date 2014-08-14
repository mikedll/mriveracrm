
class window.BillingSettings extends BaseModel
  url: () ->
    gUrlManager.url('/manage/billing_settings')

  isNew: () ->
    false

class window.BillingSettingsView extends CrmModelView
  modelName: 'billing_settings'

  initialize: (options) ->
    CrmModelView.prototype.initialize.apply(@, arguments)
    @useDirty = false
    @features = new Features()


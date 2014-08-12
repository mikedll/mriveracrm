
class window.BillingSettings extends BaseModel
  url: () ->
    gUrlManager.url('/manage/billing_settings')


class window.BillingSettingsView extends CrmModelView
  modelName: 'billing_settings'

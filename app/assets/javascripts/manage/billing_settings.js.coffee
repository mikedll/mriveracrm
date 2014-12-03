
class window.BillingSettings extends BaseModel

  initialize: () ->
    BaseModel.prototype.initialize.apply(@, arguments)
    @hasManyRelations =
      'feature_selections_attributes': 'feature_id'

  url: () ->
    gUrlManager.url('/manage/billing_settings')

  isNew: () ->
    false

class window.BillingSettingsView extends CrmModelView
  modelName: 'billing_settings'

  initialize: (options) ->
    CrmModelView.prototype.initialize.apply(@, arguments)
    @features = new Features()
    @textRenderer = new TextRenderer()

  onModelChanged: (e) ->
    CrmModelView.prototype.onModelChanged.apply(@, arguments)
    priceField = @readonlyInputsCache.filter('[data-name="price"]').first()

    price = 0.0
    _.each(@model.get('feature_selections_attributes'), (feature_selection, i) =>
      if !_.has(feature_selection, '_destroy')
        pricing = _.find(@model.get('feature_prices'), (el) -> el.id == feature_selection.feature_id)
        if typeof(pricing) != "undefined"
          price += parseFloat(pricing.price)
    )
    priceField.text("$" + (@textRenderer.toFixed(price, 2)) + " per month")

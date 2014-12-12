
class window.BillingSettings extends BaseModel

  initialize: () ->
    BaseModel.prototype.initialize.apply(@, arguments)
    @hasManyRelations =
      'feature_selections_attributes': 'feature_id'

    @ignoredAttributes['feature_prices'] = true
    @ignoredAttributes['payment_gateway_profile'] = true

  url: () ->
    gUrlManager.url('/manage/billing_settings')

  adjustSetAttrs: (attrs) ->
    attrs = BaseModel.prototype.adjustSetAttrs.apply(@, arguments)

    # we could probably do this better with a smarter listener...
    if _.has(attrs, 'feature_selections_attributes') and !_.has(attrs, 'price')
      price = 0.0
      fps = @get('feature_prices')
      _.each(attrs['feature_selections_attributes'], (feature_selection, i) =>
        if !_.has(feature_selection, '_destroy')
          pricing = _.find(fps, (el) -> el.id == feature_selection.feature_id)
          if typeof(pricing) != "undefined"
            price += parseFloat(pricing.price)
      )

      attrs['price'] = price

    attrs

  isNew: () ->
    false

class window.BillingSettingsView extends CrmModelView
  modelName: 'billing_settings'

  initialize: (options) ->
    CrmModelView.prototype.initialize.apply(@, arguments)
    @features = new Features()

  copyModelToForm: () ->
    CrmModelView.prototype.copyModelToForm.apply(@, arguments)
    @inputsCache.each((i, el) =>
      el$ = $(el)
      attributeName = @nameFromInput(el$)
      if attributeName == 'feature_selections_attributes'
        valAsInt = parseInt(el$.val())
        featurePrice = _.find(@model.get('feature_prices'), (fp) -> fp.id == valAsInt)
        if featurePrice
          el$.closest('.feature-display').find('.price').text("$#{@textRenderer.toFixed(featurePrice.price, 2)}")
      else if _.isEqual(attributeName, ['payment_gateway_profile_attributes', 'card_number'])
        el$.prop('placeholder', @deepGet(['payment_gateway_profile', 'card_prompt']))
      else if attributeName == "trial_ends_at"
        if Date.parse(@get('trial_ends_at')) < Date.parse('now')
          el$.closest('control-group')# .hide()
        else
          el$.closest('control-group')# .show()
    )


class window.PaymentGatewayProfile extends BaseModel
  url: () ->
    gUrlManager.url('/client/payment_gateway_profile')

class window.PaymentGatewayProfileView extends CrmModelView
  modelName: 'payment_gateway_profile'
  className: 'payment-gateway-profile model-view'

  initialize: (options) ->
    CrmModelView.prototype.initialize.apply(this, arguments)
    @useDirty = false
    @events =
      'ajax:beforeSend form': 'noSubmit'
      'click .save': 'save'
    @listenTo(@model, 'sync', @onSync)
    @listenTo(@model, 'error', @onError)

  save: () ->
    @clearErrors()
    @model.save(@fromForm())

  onSync: () ->
    CrmModelView.prototype.onSync.apply(this, arguments)
    @$(':input').val('')

  copyModelToForm: () ->
    @$('input[name="authorize_net_payment_gateway_profile[card_number]"]').prop('placeholder', @model.get('card_prompt'))

  buildDom: () ->
    @$el.html($('.templates .payment-gateway-profile-view-example').children().clone()) if @$el.children().length == 0


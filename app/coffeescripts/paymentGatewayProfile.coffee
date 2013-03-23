
class PaymentGatewayProfile extends Backbone.Model
  url: '/client/payment_gateway_profile'

class PaymentGatewayProfileView extends CrmModelView
  modelName: 'payment_gateway_profile'
  className: 'payment-gateway-profile model-view'

  initialize: (options) ->
    CrmModelView.prototype.initialize.apply(this, arguments)
    @events =
      'ajax:beforeSend form': 'noSubmit'
      'click a.save': 'save'
    @listenTo(@model, 'sync', @onSync)

  onSync: () ->
    @copyModelToForm()
    @$('input[name="payment_gateway_profile[card_number]"]').prop('placeholder', @model.get('card_last_4'))

  render: () ->
    @$el.html($('.templates .payment-gateway-profile-view-example').children().clone()) if @$el.children().length == 0
    @$('input[name="payment_gateway_profile[card_number]"]').prop('placeholder', @model.get('card_last_4'))
    @


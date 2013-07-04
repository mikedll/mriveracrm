
class window.PaymentGatewayProfile extends BaseModel
  url: '/client/payment_gateway_profile'

class window.PaymentGatewayProfileView extends CrmModelView
  modelName: 'payment_gateway_profile'
  className: 'payment-gateway-profile model-view'

  initialize: (options) ->
    CrmModelView.prototype.initialize.apply(this, arguments)
    @events =
      'ajax:beforeSend form': 'noSubmit'
      'click a.save': 'save'
    @listenTo(@model, 'sync', @onSync)
    @listenTo(@model, 'error', @onError)

  onSync: () ->
    CrmModelView.prototype.onSync.apply(this, arguments)
    @$('.errors').hide()
    @$(':input').val('')
    @$('input[name="authorize_net_payment_gateway_profile[card_number]"]').prop('placeholder', @model.get('card_prompt'))

  render: () ->
    @$el.html($('.templates .payment-gateway-profile-view-example').children().clone()) if @$el.children().length == 0
    @$('input[name="authorize_net_payment_gateway_profile[card_number]"]').prop('placeholder', @model.get('card_prompt'))
    @renderErrors(@model.validationError) if @model.validationError?
    @

  onError: (model, xhr, options) ->
    response = jQuery.parseJSON( xhr.responseText )
    s = ""
    _.chain(response.full_messages).filter((m) ->
      /\w/.test(m)
    ).each((m) ->
      s = "#{s} #{m}"
      s += "." if (!_.contains(['.', '!', '?'], m[ m.length - 1]) )
    )
    @$('.errors').text(s).show()

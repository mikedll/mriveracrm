
class window.PaymentGatewayProfile extends BaseModel
  initialize: (attrs, options) ->
    BaseModel.prototype.initialize.apply(@, arguments)
    # this should probably be done elsewhere. assumeBootstrapped
    # is a param specific to the knowledge that this
    # model is being used in the client section of the app
    # and bootstrapped (code-wise) by the Invoices.js
    # script.
    @trigger('bootstrapped') if options.assumeBootstrapped

  url: () ->
    gUrlManager.url('/client/payment_gateway_profile')

  isPersistentRequestingAvailable: () ->
    @deepGet('available_for_request?')

class window.PaymentGatewayProfileView extends CrmModelView
  modelName: 'payment_gateway_profile'
  className: 'payment-gateway-profile model-view'

  initialize: (options) ->
    CrmModelView.prototype.initialize.apply(this, arguments)
    @useDirty = false

  decorateRequesting: () ->
    CrmModelView.prototype.decorateRequesting.apply(@, arguments)
    if @model.isRequesting()
      @$('.btn.save').text('Saving...')
    else
      @$('.btn.save').text('Save')

  save: () ->
    @clearErrors()
    @model.save(@fromForm())

  onSync: () ->
    CrmModelView.prototype.onSync.apply(@, arguments)
    @$(':input').val('')

  copyModelToForm: () ->
    @$('input[name="payment_gateway_profile[card_number]"]').prop('placeholder', @model.get('card_prompt'))

  buildDom: () ->
    @$el.html($('.templates .payment-gateway-profile-view-example').children().clone()) if @$el.children().length == 0


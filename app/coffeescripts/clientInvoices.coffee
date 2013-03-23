
class Invoice extends Backbone.Model

class Invoices extends Backbone.Collection
  model: Invoice
  comparator: (invoice) ->
    invoice.get('id')
  url: () ->
    "/client/invoices"

class ClientInvoiceView extends CrmModelView
  modelName: 'invoice'

  render: () ->
    @$el.html($('.invoice_view_example').children().clone()) if @$el.children().length == 0
    @copyModelToForm()
    if @model.get('can_pay')
      @$('.put_action[data-action="charge"]').removeClass('disabled')
    else
      @$('.put_action[data-action="charge"]').addClass('disabled')
    @

class InvoiceListItemView extends ListItemView
  modelName: 'invoice'
  spawnViewType: ClientInvoiceView
  className: 'invoice-list-item list-item'

  title: () ->
    "#{@model.get('title')}"

class ClientInvoiceAppView extends AppView
  modelName: 'invoice'
  spawnListItemType: InvoiceListItemView
  className: 'invoices-gui app-gui'

  initialize: () ->
    AppView.prototype.initialize.apply(@, arguments)
    @paymentGatewayProfile = new PaymentGatewayProfile(__payment_gateway_profile, url: '/client/payment_gateway_profile')
    @paymentGatewayProfileView = new PaymentGatewayProfileView(model: @paymentGatewayProfile, parent: @)

  title: () ->
    "Your Invoices"

  render: () ->
    @$el.html($('.templates .invoices-app-example').children().clone())
    @$('.payment-gateway-profile-view-container').html(@paymentGatewayProfileView.render().el)
    @$('h1').text(@title())
    @

$(() ->
  guiContaner = $('.gui-container')
  appStack = new AppStack(el: guiContaner)

  collection = new Invoices()
  appView = new ClientInvoiceAppView(collection: collection, parent: appStack)
  appView.render()
  appStack.childViewPushed(appView)
  collection.reset(__invoices)
  )

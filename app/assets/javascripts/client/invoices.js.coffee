
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
    @renderErrors(@model.validationError) if @model.validationError?
    @

class InvoiceListItemView extends ListItemView
  modelName: 'invoice'
  spawnViewType: ClientInvoiceView
  className: 'invoice-list-item list-item'

  title: () ->
    title = @model.get('title')
    title += ' <span class="label label-important">Pending</span>' if @model.get('status') == 'pending'
    title

class InvoicesAppView extends CollectionAppView
  modelName: 'invoice'
  spawnListItemType: InvoiceListItemView
  className: 'invoices-gui'

  initialize: () ->
    CollectionAppView.prototype.initialize.apply(@, arguments)

  title: () ->
    "Invoices"

  render: () ->
    @$el.html($('.templates .invoices-app-example').children().clone())
    @addAll()
    @$('.section-title').text(@title())
    @

class PartitionedChildrenView extends WithChildrenView
  className: 'container-app app-gui'

  initialize: (options) ->
    WithChildrenView.prototype.initialize.apply(@, arguments)
    @invoicesAppView = new InvoicesAppView(collection: (new Invoices(__invoices)), parent: @)
    @paymentGatewayProfileView = new PaymentGatewayProfileView(model: new PaymentGatewayProfile(__payment_gateway_profile, url: '/client/payment_gateway_profile'), parent: @)

  resizeView: () ->
    # override so that we dont shift the content of this box way wrong to the left/top
    h = Math.max( 200, parseInt( $(window).height() * 0.8 ))
    w = Math.max(200, parseInt( $(window).width() * 0.8 ))
    @$el.css(
      'height': h + "px"
      'width': w + "px"
    )

  focusTopModelView: () ->
    @invoicesAppView.focusTopModelView()

  next: () -> @invoicesAppView.next()
  previous: () -> @invoicesAppView.previous()

  render: () ->
    @$el.html($('.templates .container-app-example').children().clone()) if @$el.children().length == 0
    @$('.payment-gateway-profile-view-container').html(@paymentGatewayProfileView.render().el)
    @$('.invoices-app-view-container').html(@invoicesAppView.render().el)
    @

$(() ->
  guiContaner = $('.gui-container')
  stack = new StackedChildrenView(el: guiContaner)
  stack.childViewPushed((new PartitionedChildrenView(parent: stack)).render())
  )

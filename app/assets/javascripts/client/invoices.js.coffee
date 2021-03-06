
class window.Invoice extends BaseModel
  isPersistentRequestingAvailable: () ->
    @deepGet('available_for_request?')

class window.Invoices extends BaseCollection
  model: Invoice
  comparator: (invoice) ->
    invoice.get('id')
  url: () ->
    gUrlManager.url("/client/invoices")

class window.ClientInvoiceView extends CrmModelView
  modelName: 'invoice'

class window.InvoiceListItemView extends ListItemView
  modelName: 'invoice'
  spawnViewType: ClientInvoiceView
  className: 'invoice-list-item list-item'

  title: () ->
    @model.get('title')

  onModelChanged: () ->
    ListItemView.prototype.onModelChanged.apply(this, arguments)
    @decoratePending()

  decoratePending: () ->
    if @model.get('can_pay?')
      @$el.addClass('labelled')
    else
      @$el.removeClass('labelled')

  render: () ->
    ListItemView.prototype.render.apply(this, arguments)
    @$('span.label-important').text('Pending')
    @decoratePending()
    @


class window.InvoicesAppView extends CollectionAppView
  modelNamePlural: 'invoices'
  modelName: 'invoice'
  spawnListItemType: InvoiceListItemView
  className: 'invoices-gui'

  initialize: () ->
    CollectionAppView.prototype.initialize.apply(@, arguments)

  title: () ->
    "Invoices"

  render: () ->
    CollectionAppView.prototype.render.apply(@, arguments)
    @addAll()
    @

class window.PartitionedChildrenView extends WithChildrenView
  className: 'container-app app-gui'

  initialize: (options) ->
    WithChildrenView.prototype.initialize.apply(@, arguments)
    @invoicesAppView = new InvoicesAppView(collection: (new Invoices(__invoices, silent: false)), parent: @)
    @paymentGatewayProfileView = new PaymentGatewayProfileView(model: new PaymentGatewayProfile(__payment_gateway_profile,
      assumeBootstrapped: true,
      url: '/client/payment_gateway_profile'
    ), parent: @)

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

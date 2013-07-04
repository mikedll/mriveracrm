
class window.Invoice extends BaseModel
  defaults: () ->
    total: 10.00
    description: 'Latest invoice'
  title: () ->
    @get('title')

class window.Invoices extends BaseCollection
  model: Invoice
  initialize: () ->
    BaseCollection.prototype.initialize.apply(this, arguments)
    @url = () =>
      "#{@parent.url()}/invoices"

class window.InvoiceView extends CrmModelView
  modelName: 'invoice'

  initialize: () ->
    CrmModelView.prototype.initialize.apply(this, arguments)
    @events = $.extend(@events,
      'click a.transactions': 'showTransactions'
    )
  showTransactions: () ->
    @showNestedCollectionApp('transactions', Transactions, TransactionAppView)

class window.InvoiceListItemView extends ListItemView
  modelName: 'invoice'
  spawnViewType: InvoiceView
  className: 'invoice-list-item list-item'

  title: () ->
    @model.get('title')

class window.InvoiceAppView extends CollectionAppView
  modelName: 'invoice'
  spawnListItemType: InvoiceListItemView
  className: 'invoices-gui app-gui'

  title: () ->
    "Invoices for #{@collection.parent.fullName()}"

  render: () ->
    node = $('.templates .invoices_view_example').children().clone()
    @$el.html(node)
    @$('h2').text(@title())
    @


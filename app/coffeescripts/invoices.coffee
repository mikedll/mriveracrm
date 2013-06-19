
class Invoice extends Backbone.Model
  defaults: () ->
    total: 10.00
    description: 'Latest invoice'

class Invoices extends BaseCollection
  model: Invoice
  initialize: () ->
    BaseCollection.prototype.initialize.apply(this, arguments)
    @url = () =>
      "#{@parent.url()}/invoices"

class InvoiceView extends CrmModelView
  modelName: 'invoice'

class InvoiceListItemView extends ListItemView
  modelName: 'invoice'
  spawnViewType: InvoiceView
  className: 'invoice-list-item list-item'

  title: () ->
    @model.get('title')

class InvoiceAppView extends CollectionAppView
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


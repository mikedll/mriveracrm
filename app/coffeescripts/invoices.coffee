
class Invoice extends Backbone.Model
  defaults: () ->
    total: 10.00
    description: 'Latest invoice'

class Invoices extends Backbone.Collection
  model: Invoice
  comparator: (invoice) ->
    invoice.get('id')
  url: () ->
    "#{@client.url()}/invoices"

class InvoiceView extends CrmModelView
  modelName: 'invoice'

  render: () ->
    @$el.html($('.invoice_view_example form').clone())
    @$('input[name="invoice[date]"]').datepicker(
      dateFormat: 'D yy-mm-dd'
    )
    @copyModelToForm()
    @

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
    "Invoices for #{@collection.client.fullName()}"

  render: () ->
    node = $('.templates .invoices_view_example').children().clone()
    @$el.html(node)
    @$('h2').text(@title())
    @


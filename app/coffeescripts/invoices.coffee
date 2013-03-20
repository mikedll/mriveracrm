
class Invoice extends Backbone.Model
  defaults: () ->
    total: 10.00
    description: 'Latest invoice'

class Invoices extends Backbone.Collection
  model: Invoice
  comparator: (invoice) ->
    invoice.get('id')

class InvoiceView extends Backbone.View
  modelName: 'invoice'
  className: 'invoice-view'
  render: () ->
    @$el.html($('.invoice_view_example form').clone())
    @$('input[name="invoice[description]"]').val(@model.get('first_name'))
    @$('input[name="invoice[total]"]').val(@model.get('last_name'))
    @$('input[name="invoice[date]"]').datepicker();
    @

class InvoiceListItemView extends ListItemView
  modelName: 'invoice'
  spawnViewType: InvoiceView
  className: 'invoice-list-item list-item'

  title: () ->
    @model.get('description')

class InvoiceAppView extends AppView
  modelName: 'invoice'
  spawnListItemType: InvoiceListItemView
  className: 'invoices-gui app-gui'

  render: () ->
    node = $('.templates .invoices_view_example').children().clone()
    @$el.html(node)
    @


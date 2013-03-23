
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
    @$('textarea[name="invoice[description]"]').val(@model.get('description'))
    @$('input[name="invoice[total]"]').val(@model.get('total'))
    @$('input[name="invoice[title]"]').val(@model.get('title'))
    @$('input[name="invoice[date]"]').val(@model.get('date'))
    @$('input[name="invoice[date]"]').datepicker(dateFormat: 'yy-mm-dd');
    @$('input[name="invoice[status]"]').val( @model.get('status'))

    if @model.get('status') == 'open'
      @$('.put_action[data-action="mark_pending"]').removeClass('disabled')
    else
      @$('.put_action[data-action="mark_pending"]').addClass('disabled')
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
    @$('h1').text(@title())
    @


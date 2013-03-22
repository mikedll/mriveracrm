
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
    @$el.html($('.invoice_view_example form').clone())
    @$('textarea[name="invoice[description]"]').val(@model.get('description'))
    @$('input[name="invoice[total]"]').val(@model.get('total'))
    @$('input[name="invoice[title]"]').val(@model.get('title'))
    @$('input[name="invoice[date]"]').val(@model.get('date'))
    @$('input[name="invoice[status]"]').val( @model.get('status'))

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

  title: () ->
    "Your Invoices"

  render: () ->
    node = $('.templates .invoices_view_example').children().clone()
    @$el.html(node)
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

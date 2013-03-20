
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
  className: 'invoice-list-item'

  spawnView: () ->
    new InvoiceView

  title: () ->
    @model.get('description')

class InvoiceAppView extends Backbone.View
  className: 'invoices-gui app-gui'
  events:
    'click button.back': 'back'

  create: () ->
    @collection.create()

  initialize: (options) ->
    @parent = options.parent
    @listenTo(@collection, 'reset', @addAll)
    @listenTo(@collection, 'add', @addOne)
    @listenTo(@collection, 'sync', @onSync)
    @listenTo(@collection, 'error', @onError)

  addAll: () ->
    @collection.each(@addOne, @)
  addOne: (client) ->
    clientListView = new InvoiceListItemView({'model':client, 'parent': @})
    @$('.models-list').append(clientListView.render().el)

  remove: () ->
    @$el.remove()

  back: () ->
    @parent.childViewPulled(@)

  render: () ->
    node = $('.templates .invoices_view_example').children().clone()
    @$el.html(node)
    @

  show: (invoiceView) ->
    @$('.models-show-container').hide()
    @$('.models-show-container .invoice-view').hide()
    @$('.models-show-container').append(invoiceView.el) if @invoiceView(invoiceView.id).length == 0
    @$('#' + invoiceView.id).show()
    @$('.models-show-container').show()
    invoiceView.$(':input:visible').first().focus()

  onSync: () ->
    @$(".invoice-view:visible .control-group")
      .removeClass('error')
      .find('span.help-inline').remove()
    @$('.errors').hide()

  invoiceView: (id) ->
    @$('#invoice-view-' + id)

  onError: (model, xhr, options) ->
    response = jQuery.parseJSON( xhr.responseText )
    s = ""
    _.each(response.full_messages, (m) ->
      s = "#{s} #{m}."
    )
    @$('.errors').text(s).show()

    if @invoiceView(response.object.id).length != 0
      @invoiceView(response.object.id)
        .removeClass('error')
        .find('span.help-inline').remove()
      _.each(response.errors, (value, key, list) =>
        @invoiceView(response.object.id).find(".control-group.client_#{key}")
          .addClass('error')
          .find('.controls').append('<span class="help-inline">' + value + '</span>').end()
      )

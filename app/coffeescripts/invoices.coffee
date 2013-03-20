
class Invoice extends Backbone.Model
  defaults: () ->

class Invoices extends Backbone.Collection
  model: Invoice
  comparator: (invoice) ->
    invoice.get('id')

class InvoiceView extends Backbone.View
  initialize: () ->

class InvoiceAppView extends Backbone.View
  className: 'invoices-gui app-gui'
  events:
    'click button.back': 'back'

  initialize: (options) ->
    @parent = options.parent

  remove: () ->
    @$el.remove()

  back: () ->
    @parent.childViewPulled(@)

  render: () ->
    node = $('.templates .invoices_view_example').children().clone()
    @$el.html(node)
    @

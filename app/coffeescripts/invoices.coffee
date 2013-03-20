
class Invoice extends Backbone.Model
  defaults: () ->

class Invoices extends Backbone.Collection
  model: Invoice
  comparator: (invoice) ->
    invoice.get('id')

class InvoiceView extends Backbone.View
  initialize: () ->

class InvoiceAppView extends Backbone.View
  events:
    'click button.back': 'back'

  remove: () ->
    @$el.remove()

  back: () ->
    @parent.childViewPulled(@)

  render: () ->
    node = $('.templates .invoices_view_example').clone()
    @$el.html(node)
    @

$(() ->
    app = new InvoiceAppView(
      'el': $('.invoices-gui')
    )
    app.render()
  )
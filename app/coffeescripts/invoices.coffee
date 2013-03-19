
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
  back: () ->
    $('.clients-gui')
      .css('left': '-1200px')
      .animate('left': '0px', 400, 'swing', () ->
      )
    $('.invoices-gui')
      .show()
      .css('left': '0px')
      .animate('left': '1200px', 400, 'swing', () ->
      )


$(() ->
    app = new InvoiceAppView(
      'el': $('.invoices-gui')
    )
    app.render()
  )
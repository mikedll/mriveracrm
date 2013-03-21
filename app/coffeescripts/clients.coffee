
class Client extends Backbone.Model
  defaults: () ->
    first_name: 'John'
    last_name: 'Doe'
    email: 'noone@example.com'

class Clients extends Backbone.Collection
  model: Client
  url: '/manage/clients'
  comparator: (client) ->
    client.get('id')

class ClientView extends CrmModelView
  modelName: 'client'
  events:
    'keypress input': 'onKeypress'
    'submit form': 'noSubmit'
    'click button.invoices': 'showInvoices'
    'click button.save': 'save'
    'confirm:complete button.destroy': 'destroy'

  showInvoices: () ->
    if !@invoices?
      @invoices = new Invoices()
      @invoices.client = @model

    @invoicesAppView = new InvoiceAppView({id: "client-#{@model.get('id')}-invoices", parent: @, collection: @invoices})
    @invoicesAppView.render()
    @parent.childViewPushed(@invoicesAppView)
    @invoices.fetch()

  render: () ->
    node = $('.client_view_example form').clone()
    node.find('input[name="client[first_name]"]').val(@model.get('first_name'))
    node.find('input[name="client[last_name]"]').val(@model.get('last_name'))
    node.find('input[name="client[email]"]').val(@model.get('email'))
    @$el.html(node)
    @

class ClientListItemView extends ListItemView
  modelName: 'client'
  spawnViewType: ClientView
  className: 'client-list-item list-item'

  title: () ->
    "#{@model.get('first_name')} #{@model.get('last_name')}"

class ClientAppView extends AppView
  modelName: 'client'
  spawnListItemType: ClientListItemView
  render: () ->


$(() ->
  guiContaner = $('.gui-container')
  appStack = new AppStack(el: guiContaner)

  clients = new Clients()
  clientApp = new ClientAppView(el: guiContaner.find('.clients-gui'), collection: clients, parent: appStack)
  clients.reset(__clients)

  appStack.childViewPushed(clientApp)

  )
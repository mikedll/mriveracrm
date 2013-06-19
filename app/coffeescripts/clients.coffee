
class Client extends Backbone.Model
  defaults: () ->
    first_name: 'New'
    last_name: 'Client'
  fullName: () ->
    "#{@get('first_name')} #{@get('last_name')}"

  validate: (attrs, options) ->
    if (!EmailRegex.test(attrs.email))
      return {email: "is invalid"}
    return

class Clients extends Backbone.Collection
  model: Client
  url: '/manage/clients'
  initialize: () ->
    Backbone.Collection.prototype.initialize.apply(this, arguments)
    @events = $.extend(@events, 'click a.invoices': 'showInvoices')
    @comparator = (client) ->
      client.get('id')

class ClientView extends CrmModelView
  modelName: 'client'

  initialize: () ->
    CrmModelView.prototype.initialize.apply(this, arguments)
    @events = $.extend(@events,
      'click a.invoices': 'showInvoices'
      'click a.notes': 'showNotes'
    )

  showInvoices: () ->
    if !@invoices?
      @invoices = new Invoices()
      @invoices.client = @model

    @invoicesAppView = new InvoiceAppView({id: "client-#{@model.get('id')}-invoices", parent: @, collection: @invoices})
    @invoicesAppView.render()
    @parent.childViewPushed(@invoicesAppView)
    @invoices.fetch()

  showNotes: () ->
    if !@notes?
      @notes = new Notes()
      @notes.client = @model

    @notesAppView = new NoteAppView({id: "client-#{@model.get('id')}-notes", parent: @, collection: @notes})
    @notesAppView.render()
    @parent.childViewPushed(@notesAppView)
    @notes.fetch()

  render: () ->
    node = $('.client_view_example form').clone()
    @$el.html(node)
    console.log(AppsConfig.datepickerDateformat)
    console.log(AppsConfig.datetimePickerTimeFormat)
    @$('input.datetimepicker').datetimepicker(
      dateFormat: AppsConfig.datepickerDateformat,
      timeFormat: AppsConfig.datetimePickerTimeFormat
    )
    @copyModelToForm()
    @renderErrors(@model.validationError) if @model.validationError?
    @

class ClientListItemView extends ListItemView
  modelName: 'client'
  spawnViewType: ClientView
  className: 'client-list-item list-item'

  title: () ->
    "#{@model.get('first_name')} #{@model.get('last_name')}"

class ClientAppView extends CollectionAppView
  modelName: 'client'
  spawnListItemType: ClientListItemView
  title: () ->
    'Clients'


$(() ->
  guiContaner = $('.gui-container')
  stack = new StackedChildrenView(el: guiContaner)

  clients = new Clients()
  clientApp = new ClientAppView(el: guiContaner.find('.clients-gui'), collection: clients, parent: stack)
  clientApp.render()
  stack.childViewPushed(clientApp)
  clients.reset(__clients)
  )
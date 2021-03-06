
class window.Client extends BaseModel
  defaults: () ->
    first_name: 'New'
    last_name: 'Client'
  fullName: () ->
    "#{@get('first_name')} #{@get('last_name')}"

  validate: (attrs, options) ->
    if (attrs.email? && attrs.email.trim() != "" && !EmailRegex.test(attrs.email.trim()))
      return {email: "is invalid"}
    return

class window.Clients extends BaseCollection
  model: Client
  urlFragment: '/manage/clients'

class window.ClientView extends CrmModelView
  modelName: 'client'

  initialize: () ->
    CrmModelView.prototype.initialize.apply(this, arguments)
    @events = $.extend(@events,
      'click a.invoices': 'showInvoices'
      'click a.notes': 'showNotes'
      'click a.invitations': 'showInvitations'
      'click a.users': 'showUsers'
      'click a.expand_address': 'toggleAddress'
    )

  toggleAddress: (e) ->
    if $(e.target).hasClass('active')
      @$('.address_info').hide()
    else
      @$('.address_info').show()

  showInvoices: () ->
    @showNestedCollectionApp('invoices', Invoices, InvoiceAppView)

  showNotes: () ->
    @showNestedCollectionApp('notes', Notes, NoteAppView)

  showInvitations: () ->
    @showNestedCollectionApp('invitations', Invitations, InvitationAppView)

  showUsers: () ->
    @showNestedCollectionApp('users', Users, UserAppView)

class window.ClientListItemView extends ListItemView
  modelName: 'client'
  spawnViewType: ClientView
  className: 'client-list-item list-item'

  display_name: () ->
    "#{@model.get('first_name')} #{@model.get('last_name')}"

  title: () ->
    if @model.get('company')? && @model.get('company').trim() != ""
      @model.get('company')
    else
      "#{@model.get('first_name')} #{@model.get('last_name')}"

class window.ClientAppView extends CollectionAppView
  modelNamePlural: 'clients'
  modelName: 'client'
  spawnListItemType: ClientListItemView
  title: () ->
    'Clients'


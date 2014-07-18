
class window.Employee extends BaseModel
  defaults: () ->
    first_name: 'New'
    last_name: 'Employee'
  fullName: () ->
    "#{@get('first_name')} #{@get('last_name')}"

  validate: (attrs, options) ->
    if (attrs.email? && attrs.email.trim() != "" && !EmailRegex.test(attrs.email.trim()))
      return {email: "is invalid"}
    return

class window.Employees extends Backbone.Collection
  model: Employee
  url: () ->
    gUrlManager.url('/manage/employees')

  initialize: () ->
    Backbone.Collection.prototype.initialize.apply(this, arguments)
    @comparator = (employee) ->
      employee.get('id')

class window.EmployeeView extends CrmModelView
  modelName: 'employee'

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

class window.EmployeeListItemView extends ListItemView
  modelName: 'employee'
  spawnViewType: EmployeeView
  className: 'employee-list-item list-item'

  display_name: () ->
    "#{@model.get('first_name')} #{@model.get('last_name')}"

  title: () ->
    if @model.get('company')? && @model.get('company').trim() != ""
      @model.get('company')
    else
      "#{@model.get('first_name')} #{@model.get('last_name')}"

class window.EmployeeAppView extends CollectionAppView
  modelNamePlural: 'employees'
  modelName: 'employee'
  spawnListItemType: EmployeeListItemView
  title: () ->
    'Employees'



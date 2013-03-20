
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
  className: 'client-view'
  events:
    'keypress input': 'onKeypress'
    'submit form': 'noSubmit'
    'click button.invoices': 'invoices'
    'click button.save': 'save'
    'click button.destroy': 'destroy'

  invoices: () ->
    @invoices = new Invoices({url: @model.get('id') + '/invoices'})
    @invoicesAppView = new InvoiceAppView({parent: @, collection: @invoices})
    @invoicesAppView.render()
    @parent.childViewPushed(@invoicesAppView)

  render: () ->
    node = $('.client_view_example form').clone()
    node.find('input[name="client[first_name]"]').val(@model.get('first_name'))
    node.find('input[name="client[last_name]"]').val(@model.get('last_name'))
    node.find('input[name="client[email]"]').val(@model.get('email'))
    @$el.html(node)
    @

class ClientListItemView extends ListItemView
  className: 'client-list-item list-item'

  spawnView: (model) ->
    new ClientView({model:@model, className: 'client-view', id: "client-view-#{@model.get('id')}", parent: @})

  title: () ->
    "#{@model.get('first_name')} #{@model.get('last_name')}"

class ClientAppView extends Backbone.View
  delay: 300
  events:
    'click .add-client': 'create'
  create: () ->
    @collection.create()
  initialize: () ->
    @children = [@$('.clients-gui')] # this is jquery-wrapped dom elements, not backbone views
    @listenTo(@collection, 'reset', @addAll)
    @listenTo(@collection, 'add', @addOne)
    @listenTo(@collection, 'sync', @onSync)
    @listenTo(@collection, 'error', @onError)

    $(document).ajaxStart(() =>
      @$('.spinner-container').show()
    )
    $(document).ajaxStop(() =>
      @$('.spinner-container').hide()
    )

    @transforms =
      out:
        left: '-50px'
        top: '-50px'
        opacity: '0.5'
      in:
        left: '0px'
        top: '0px'
        opacity: '1.0'
      incoming:
        left: '150px'
        top: '150px'
        opacity: '0.0'

  childViewPushed: (view) ->
    if @children.length > 0
      @children[ @children.length - 1]
        .css(@transforms['in'])
        .animate(@transforms['out'], @delay, 'easeOutCirc', () ->
        )

    @$el.append(view.el)
    @children.push( view.$el )
    @children[ @children.length - 1 ]
      .css(@transforms['incoming'])
      .animate(@transforms['in'], @delay, 'easeOutCirc', () =>
      )

  #
  # view param is used to do backbone removal.
  # it is asssmed that view.$el == @children[ @children.length - 1 ]
  #
  childViewPulled: (view) ->
    return if @children.length == 0

    if @children.length > 1
      @children[ @children.length - 2 ]
        .css(@transforms['out'])
        .animate(@transforms['in'], @delay, 'easeOutCirc', () ->
       )

    lastChild = @children[ @children.length - 1 ]
    lastChild
      .css(@transforms['in'])
      .animate(@transforms['incoming'], @delay, 'easeOutCirc', () =>
        view.remove()
        @children.pop()
      )

  addAll: () ->
    @collection.each(@addOne, @)
  addOne: (client) ->
    clientListView = new ClientListItemView({'model':client, 'parent': @})
    @$('.models-list').append(clientListView.render().el)
  render: () ->
  show: (clientView) ->
    @$('.models-show-container').hide()
    @$('.models-show-container .client-view').hide()
    @$('.models-show-container').append(clientView.el) if @clientView(clientView.id).length == 0
    @$('#' + clientView.id).show()
    @$('.models-show-container').show()
    clientView.$(':input:visible').first().focus()

  onSync: () ->
    @$(".client-view:visible .control-group")
      .removeClass('error')
      .find('span.help-inline').remove()
    @$('.errors').hide()

  clientView: (id) ->
    @$('#client-view-' + id)

  onError: (model, xhr, options) ->
    response = jQuery.parseJSON( xhr.responseText )
    s = ""
    _.each(response.full_messages, (m) ->
      s = "#{s} #{m}."
    )
    @$('.errors').text(s).show()

    if @clientView(response.object.id).length != 0
      @clientView(response.object.id)
        .removeClass('error')
        .find('span.help-inline').remove()
      _.each(response.errors, (value, key, list) =>
        @clientView(response.object.id).find(".control-group.client_#{key}")
          .addClass('error')
          .find('.controls').append('<span class="help-inline">' + value + '</span>').end()
      )

$(() ->
  clients = new Clients()
  app = new ClientAppView(
    el: $('.gui-container')
    collection: clients
  )
  clients.reset(__clients)
  )
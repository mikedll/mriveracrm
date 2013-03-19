
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

class ClientView extends Backbone.View
  className: 'client-view'
  events:
    'keypress input': 'onKeypress'

  initialize: () ->
    @listenTo(@model, 'sync', @render)

  onKeypress: (e) ->
    if(e.keyCode == 13)
      e.stopPropagation()
      updated = {}
      _.each(@$('input'), (el) ->
        attribute_keys = /client\[(\w+)\]/.exec($(el).prop('name'))
        if attribute_keys? && attribute_keys.length == 2
          updated[ attribute_keys[1] ] = $(el).val()
      )
      @model.set()
      @model.save(updated, {wait: true})
      return false

  render: () ->
    node = $('.client_view_example form').clone()
    node.find('input[name="client[first_name]"]').val(@model.get('first_name'))
    node.find('input[name="client[last_name]"]').val(@model.get('last_name'))
    node.find('input[name="client[email]"]').val(@model.get('email'))
    @$el.html(node)
    @

class ClientListItemView extends Backbone.View
  tagName: 'li'
  className: 'client-list-item'
  events:
    'click span': 'show'

  initialize: () ->
    @listenTo(@model, 'sync', @render)

  show: () ->
    if !@showview?
      @showview = new ClientView({model:@model, className: 'client-view', id: "client-view-#{@model.get('id')}"})
      @showview.render()
    @options.clientApp.show(@showview)

  render: () ->
    @$el.html("<span>#{@model.get('id')} #{@model.get('first_name')} #{@model.get('last_name')}</span>")
    @


class ClientAppView extends Backbone.View
  events:
    'click .add-client': 'create'
  create: () ->
    @collection.create()
  initialize: () ->
    @listenTo(@collection, 'reset', @addAll)
    @listenTo(@collection, 'add', @addOne)

    $(document).ajaxStart(() =>
      @$('.spinner-container').show()
    )
    $(document).ajaxStop(() =>
      @$('.spinner-container').hide()
    )
  addAll: () ->
    @collection.each(@addOne, @)
  addOne: (client) ->
    clientListView = new ClientListItemView({'model':client, 'clientApp': @})
    @$('.clients-list').append(clientListView.render().el)
    @collection.on('sync', @onSync, @)
    @collection.on('error', @onError, @)
  render: () ->
  show: (clientView) ->
    @$('.clients-show-container').hide()
    @$('.clients-show-container .client-view').hide()
    @$('.clients-show-container').append(clientView.el) if @$('#' + clientView.id).length == 0
    @$('#' + clientView.id).show()
    @$('.clients-show-container').show()
    clientView.$(':input:visible').first().focus()

  onSync: () ->
    @$('.errors').hide()
  onError: (model, xhr, options) ->
    @$('.errors').text('An error occured while saving.').show()



$(() ->
  clients = new Clients()
  app = new ClientAppView(
    'el': $('.clients-gui').get(0)
    'collection': clients
  )
  clients.reset(__clients)
  )
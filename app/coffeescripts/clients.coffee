
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

  show: () ->
    @options.clientApp.$('.clients-show-container').hide()

    if !@showview?
      @showview = new ClientView({'model':@model})
      @showview.render()

    @options.clientApp.$('.clients-show-container').html(@showview.el)
    @options.clientApp.$('.clients-show-container').show()
    @showview.$(':input:visible').first().focus()

  render: () ->
    @$el.html("<span>#{@model.get('id')} #{@model.get('first_name')} #{@model.get('last_name')}</span>")
    @showview.render() if @showview?
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
    client.on('sync', clientListView.render, clientListView)
  render: () ->



$(() ->
  clients = new Clients()
  app = new ClientAppView(
    'el': $('.clients-gui').get(0)
    'collection': clients
  )
  clients.reset(__clients)
  )
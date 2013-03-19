
class Client extends Backbone.Model
  defaults: () ->
    first_name: 'John'
    last_name: 'Doe'
    email: 'noone@example.com'

class Clients extends Backbone.Collection
  model: Client
  url: '/manage/clients'

class ClientView extends Backbone.View
  render: () ->
    node = $('.client_view_example form').clone()
    node.find('input[name="client[first_name]"]').val(@model.get('first_name'))
    node.find('input[name="client[last_name]"]').val(@model.get('last_name'))
    node.find('input[name="client[email]"]').val(@model.get('email'))
    @$el.html(node)
    @

class ClientAppView extends Backbone.View
  events:
    'click .add-client': 'create'
  create: () ->
    @collection.create()
  initialize: () ->
    console.log(@collection)
    @listenTo(@collection, 'reset', @addAll)
    @listenTo(@collection, 'add', @addOne)
  addAll: () ->
    console.log('help')
    @collection.each(@addOne, @)
  addOne: (client) ->
    console.log(client)
    console.log(@$el)
    cview = new ClientView({'model':client})
    @$el.append(cview.render().el)
  render: () ->
    @$el.html('')


$(() ->
  clients = new Clients()
  app = new ClientAppView(
    'el': $('.clients-root').get(0)
    'collection': clients
  )
  clients.reset(__clients)
  )
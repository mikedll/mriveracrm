
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
    console.log('help')
    console.log(@$el)
    console.log(@el)
    node = $('.client_view_example form').clone()
    node.find('input[name="client[first_name]"]').val(@model.get('first_name'))
    node.find('input[name="client[last_name]"]').val(@model.get('last_name'))
    node.find('input[name="client[email]"]').val(@model.get('email'))
    @$el.html(node)
    console.log(@el)
    @

$(() ->
  clients = new Clients()
  clients.reset(__clients)
  clients.forEach((c) ->
    console.log(c)
    cview = new ClientView({'model':c})
    $('.clients-root').append(cview.render().el)
  )
  $('.add-client').bind('click', () ->
    c = clients.create()
    cview = new ClientView({'model':c})
    $('.clients-root').append(cview.render().el)
  )
  )
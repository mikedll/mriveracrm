
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
    'submit form': 'noSubmit'
    'click button.invoices': 'invoices'
    'click button.save': 'save'
    'click button.destroy': 'destroy'

  initialize: (options) ->
    @parent = options.parent
    @listenTo(@model, 'sync', @render)
    @listenTo(@model, 'destroy', @remove)

  remove: () ->
    @$el.remove()

  destroy: (e) ->
    @model.destroy({wait: true})

  invoices: () ->
    @invoicesAppView = new InvoiceAppView({parent: @})
    @invoicesAppView.render()
    @parent.childViewPushed(@invoicesAppView)

  onKeypress: (e) ->
    if(e.keyCode == 13)
      @model.save()
      return false
    return true

  save: () ->
    updated = {}
    _.each(@$('input'), (el) ->
      attribute_keys = /client\[(\w+)\]/.exec($(el).prop('name'))
      if attribute_keys? && attribute_keys.length == 2
        updated[ attribute_keys[1] ] = $(el).val()
    )
    @model.set()
    @model.save(updated, {wait: true})

  noSubmit: (e) ->
    e.stopPropagation()
    false

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
    'click a': 'show'

  initialize: (options) ->
    @parent = options.parent
    @listenTo(@model, 'sync', @render)
    @listenTo(@model, 'destroy', @remove)

  childViewPushed: (view) ->
    @options.parent.childViewPushed(view)

  childViewPulled: (view) ->
    @options.parent.childViewPulled(view)

  remove: () ->
    @$el.remove()

  show: (e) ->
    e.stopPropagation()
    if !@showview?
      @showview = new ClientView({model:@model, className: 'client-view', id: "client-view-#{@model.get('id')}", parent: @})
      @showview.render()
    @options.parent.show(@showview)
    false

  render: () ->
    @$el.html("<a href='#'>#{@model.get('first_name')} #{@model.get('last_name')}</a>")
    @


class ClientAppView extends Backbone.View
  events:
    'click .add-client': 'create'
  create: () ->
    @collection.create()
  initialize: () ->
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
        left: '50px'
        top: '50px'
        opacity: '0.0'

  childViewPushed: (view) ->
    @$el
      .css(@transforms['in'])
      .animate(@transforms['out'], 200, 'easeOutCirc', () ->
      )
    @$el.append(view.el)
    view.$el
      .css(@transforms['incoming'])
      .animate(@transforms['in'], 200, 'easeOutCirc', () ->
      )

  childViewPulled: (view) ->
    view.$el
      .css(@transforms['in'])
      .animate(@transforms['incoming'], 200, 'easeOutCirc', () ->
      )
    @$el
      .css(@transforms['out'])
      .animate(@transforms['in'], 200, 'easeOutCirc', () ->
       )
    view.remove()

  addAll: () ->
    @collection.each(@addOne, @)
  addOne: (client) ->
    clientListView = new ClientListItemView({'model':client, 'parent': @})
    @$('.clients-list').append(clientListView.render().el)
  render: () ->
  show: (clientView) ->
    @$('.clients-show-container').hide()
    @$('.clients-show-container .client-view').hide()
    @$('.clients-show-container').append(clientView.el) if @clientView(clientView.id).length == 0
    @$('#' + clientView.id).show()
    @$('.clients-show-container').show()
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
    el: $('.clients-gui').get(0)
    parent: $('.gui-container')
    collection: clients
  )
  clients.reset(__clients)
  )
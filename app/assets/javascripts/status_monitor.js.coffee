
class window.StatusMonitor extends Backbone.Model
  defaults:
    status: ''
  initialize: () ->
    Backbone.Model.prototype.initialize.apply(this, arguments)
    @url = '/manage/status_monitor'

class window.StatusMonitorView extends CrmModelView
  initialize: () ->
    CrmModelView.prototype.initialize.apply(this, arguments)
    @modelName = 'status_monitor'
    @listenTo(@model, 'request', @onRequest)
    @listenTo(@model, 'error', @onError)
    @events = $.extend(@events,
      'click .check-status': @refresh
    )

  refresh: () ->
    @model.fetch()

  onRequest: () ->
    $('.spinner-container').show()

  onComplete: () ->
    $('.spinner-container').hide()

  onSync: () ->
    @onComplete()
    CrmModelView.prototype.onSync.apply(this, arguments)

  onError: () ->
    @onComplete()

  render: () ->
    CrmModelView.prototype.render.apply(this, arguments)
    @

$(() ->
  guiContaner = $('.gui-container')

  appView = new SingleModelAppView(el: guiContaner.find('.status-monitor-gui')).render()

  modelView = new StatusMonitorView(el: guiContaner.find('.models-show-container'), model: new StatusMonitor(), parent: appView).render()
  )


class window.StatusMonitor extends BaseModel
  defaults:
    status: ''
  initialize: () ->
    BaseModel.prototype.initialize.apply(this, arguments)
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

$(() ->
  guiContaner = $('.gui-container')

  appView = new SingleModelAppView(el: guiContaner.find('.status-monitor-gui')).render()

  modelView = new StatusMonitorView(el: guiContaner.find('.models-show-container'), model: new StatusMonitor(), parent: appView).render()
  )

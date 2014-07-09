
class window.StatusMonitor extends BaseModel
  defaults:
    status: ''
  url: () ->
    gUrlManager.url('/manage/status_monitor')

class window.StatusMonitorView extends CrmModelView
  initialize: () ->
    CrmModelView.prototype.initialize.apply(this, arguments)
    @useDirty = false
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


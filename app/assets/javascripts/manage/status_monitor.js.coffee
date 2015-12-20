
class window.StatusMonitor extends BaseModel
  defaults:
    status: ''
  url: () ->
    gUrlManager.url('/manage/status_monitor')

class window.StatusMonitorView extends CrmModelView
  modelName: 'status_monitor'

  initialize: () ->
    CrmModelView.prototype.initialize.apply(@, arguments)
    @useDirty = false
    @events = $.extend(@events,
      'click .check-status': @refresh
    )

  refresh: () ->
    @model.fetch()


class window.ComputerMonitor extends BaseModel
  defaults:
    'runnable?': false

  isPersistentRequestingAvailable: () ->
    @deepGet('available_for_request?')

class window.ComputerMonitorView extends CrmModelView
  modelName: 'computer_monitor'

  initialize: (options) ->
    CrmModelView.prototype.initialize.apply(@, arguments)
    @listenTo(@model, 'change', @showHideSensitive)

  render: () ->
    CrmModelView.prototype.render.apply(@, arguments)
    @showHideSensitive()

  showHideSensitive: () ->
    lastError$ = @inputFor$('last_error')
    if @model.get('last_error') == ""
      lastError$.closest('.control-group').hide()
    else
      lastError$.closest('.control-group').show()

class window.ComputerMonitors extends BaseCollection
  model: ComputerMonitor
  urlFragment: '/manage/computer_monitors'

class window.ComputerMonitorListItemView extends ListItemView
  modelName: 'computer_monitor'
  spawnViewType: ComputerMonitorView
  className: 'computer-monitor-list-item list-item'

  title: () ->
    @model.get('name')

class window.ComputerMonitorAppView extends CollectionAppView
  modelNamePlural: 'computer_monitors'
  modelName: 'computer_monitor'
  spawnListItemType: ComputerMonitorListItemView
  title: () ->
    'Computer Monitor'

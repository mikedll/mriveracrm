
class window.ItComputerMonitor extends BaseModel
  defaults:
    'runnable?': false

  isPersistentRequestingAvailable: () ->
    @deepGet('available_for_request?')

class window.ItComputerMonitorView extends CrmModelView
  modelName: 'it_computer_monitor'

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

class window.ItComputerMonitors extends BaseCollection
  model: ItComputerMonitor
  urlFragment: '/manage/computer_monitors'

class window.ItComputerMonitorListItemView extends ListItemView
  modelName: 'it_computer_monitor'
  spawnViewType: ItComputerMonitorView
  className: 'it-computer-monitor-list-item list-item'

  title: () ->
    @model.get('name')

class window.ItComputerMonitorAppView extends CollectionAppView
  modelNamePlural: 'it_computer_monitors'
  modelName: 'it_computer_monitor'
  spawnListItemType: ItComputerMonitorListItemView
  title: () ->
    'Computer Monitors'

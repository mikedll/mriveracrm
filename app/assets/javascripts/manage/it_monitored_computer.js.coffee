
class window.ItMonitoredComputer extends BaseModel
  defaults:
    'runnable?': false

  isPersistentRequestingAvailable: () ->
    @deepGet('available_for_request?')

class window.ItMonitoredComputerView extends CrmModelView
  modelName: 'it_monitored_computer'

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

class window.ItMonitoredComputers extends BaseCollection
  model: ItMonitoredComputer
  urlFragment: '/manage/monitored_computers'

class window.ItMonitoredComputerListItemView extends ListItemView
  modelName: 'it_monitored_computer'
  spawnViewType: ItMonitoredComputerView
  className: 'it-monitored-computer-list-item list-item'

  title: () ->
    @model.get('name')

class window.ItMonitoredComputerAppView extends CollectionAppView
  modelNamePlural: 'it_monitored_computers'
  modelName: 'it_monitored_computer'
  spawnListItemType: ItMonitoredComputerListItemView
  title: () ->
    'Monitored Computer'

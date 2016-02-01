
class window.ITMonitoredComputer extends BaseModel

class window.ITMonitoredComputerView extends CrmModelView
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

class window.ITMonitoredComputers extends BaseCollection
  model: ITMonitoredComputer
  urlFragment: '/manage/monitored_computers'

class window.ITMonitoredComputerListItemView extends ListItemView
  modelName: 'it_monitored_computer'
  spawnViewType: ITMonitoredComputerView
  className: 'it-monitored-computer-list-item list-item'

  title: () ->
    @model.get('name')

class window.ITMonitoredComputerAppView extends CollectionAppView
  modelNamePlural: 'it_monitored_computers'
  modelName: 'it_monitored_computer'
  spawnListItemType: ITMonitoredComputerListItemView
  title: () ->
    'Monitored Computers'

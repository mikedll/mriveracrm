
class window.Report extends BaseModel

class window.Reports extends BaseCollection
  model: Report
  urlFragment: '/manage/reports'

class window.ReportView extends CrmModelView
  modelName: 'report'

class window.ReportListItemView extends ListItemView
  modelName: 'report'
  spawnViewType: ReportView
  className: 'report-list-item list-item'

  title: () ->
    @model.get('name')

class window.ReportAppView extends CollectionAppView
  modelName: 'report'
  modelNamePlural: 'reports'
  spawnListItemType: ReportListItemView

  title: () ->
    "Reports"


class window.Report extends BaseModel

class window.Reports extends BaseCollection
  model: Report
  urlFragment: '/manage/reports'

class window.ReportView extends CrmModelView

class window.ReportListItemView extends ListItemView
  modelName: 'report'
  spawnViewType: ReportView
  className: 'report-list-item list-item'

class window.ReportAppView extends CollectionAppView
  modelName: 'report'
  modelNamePlural: 'reports'
  spawnListItemType: ReportListItemView

  title: () ->
    "Reports"


class window.Note extends BaseModel
  defaults: () ->
    recorded_at: Date.parse('now').toString(AppsConfig.dateJsReadableDatetimeFormat)

class window.Notes extends BaseCollection
  model: Note
  initialize: () ->
    BaseCollection.prototype.initialize.apply(this, arguments)
    @url = () =>
      "#{@parent.url()}/notes"
    @comparator = (a, b) ->
      aaval = Date.parse(a.get('recorded_at'))
      bbval = Date.parse(b.get('recorded_at'))
      return -1 if bbval < aaval
      return 1 if bbval > aaval
      return 0

class window.NoteView extends CrmModelView
  modelName: 'note'

  render: () ->
    @$el.html($('.note_view_example form').clone())
    @$('input.datetimepicker').datetimepicker(
      dateFormat: 'D yy-mm-dd',
      timeFormat: 'h:mmTT'
    )
    @copyModelToForm()
    @

class window.NoteListItemView extends ListItemView
  modelName: 'note'
  spawnViewType: NoteView
  className: 'note-list-item list-item'

  title: () ->
    @toHumanReadableDateTimeFormat('recorded_at')

class window.NoteAppView extends CollectionAppView
  modelName: 'note'
  spawnListItemType: NoteListItemView
  className: 'notes-gui app-gui'

  title: () ->
    "Notes for #{@collection.parent.fullName()}"

  render: () ->
    node = $('.templates .notes_view_example').children().clone()
    @$el.html(node)
    @$('h2').text(@title())
    @



class Note extends Backbone.Model
  defaults: () ->
    datetime: Date.parse('today').toString()

class Notes extends BaseCollection
  model: Note
  url: () ->
    "#{@client.url()}/notes"

class NoteView extends CrmModelView
  modelName: 'note'

  render: () ->
    @$el.html($('.note_view_example form').clone())
    @$('input.datetimepicker').datetimepicker(
      dateFormat: 'D yy-mm-dd',
      timeFormat: 'h:mmTT'
    )
    @copyModelToForm()
    @

class NoteListItemView extends ListItemView
  modelName: 'note'
  spawnViewType: NoteView
  className: 'note-list-item list-item'

  title: () ->
    @model.get('recorded_at')

class NoteAppView extends CollectionAppView
  modelName: 'note'
  spawnListItemType: NoteListItemView
  className: 'notes-gui app-gui'

  title: () ->
    "Notes for #{@collection.client.fullName()}"

  render: () ->
    node = $('.templates .notes_view_example').children().clone()
    @$el.html(node)
    @$('h2').text(@title())
    @


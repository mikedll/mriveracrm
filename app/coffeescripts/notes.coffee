
class Note extends Backbone.Model
  defaults: () ->

class Notes extends BaseCollection
  model: Note
  url: () ->
    "#{@client.url()}/notes"
  initialize: () ->
    BaseCollection.prototype.initialize.apply(this, arguments)
    @comparator = (model) ->
      model.get('datetime')

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
    @parseDatetime('recorded_at')

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


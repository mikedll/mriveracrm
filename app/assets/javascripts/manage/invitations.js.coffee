
class Invitation extends Backbone.Model
  defaults: () ->

class Invitations extends BaseCollection
  model: Invitation
  initialize: () ->
    BaseCollection.prototype.initialize.apply(this, arguments)
    @url = () =>
      "#{@parent.url()}/invitations"

class InvitationView extends CrmModelView
  modelName: 'invitation'

class InvitationListItemView extends ListItemView
  modelName: 'invitation'
  spawnViewType: InvitationView
  className: 'invitation-list-item list-item'

  title: () ->
    @model.get('email')

class InvitationAppView extends CollectionAppView
  modelName: 'invitation'
  spawnListItemType: InvitationListItemView
  className: 'invitations-gui app-gui'

  title: () ->
    "User Invitations for #{@collection.parent.fullName()}"

  render: () ->
    node = $('.templates .invitations_view_example').children().clone()
    @$el.html(node)
    @$('h2').text(@title())
    @


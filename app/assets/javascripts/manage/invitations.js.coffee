
class window.Invitation extends BaseModel
  defaults: () ->

class window.Invitations extends BaseCollection
  model: Invitation
  initialize: () ->
    BaseCollection.prototype.initialize.apply(this, arguments)
    @url = () =>
      "#{@parent.url()}/invitations"

class window.InvitationView extends CrmModelView
  modelName: 'invitation'

class window.InvitationListItemView extends ListItemView
  modelName: 'invitation'
  spawnViewType: InvitationView
  className: 'invitation-list-item list-item'

  title: () ->
    @model.get('email')

class window.InvitationAppView extends CollectionAppView
  modelNamePlural: 'invitations'
  modelName: 'invitation'
  spawnListItemType: InvitationListItemView
  className: 'invitations-gui app-gui'

  title: () ->
    "User Invitations for #{@collection.parent.fullName()}"


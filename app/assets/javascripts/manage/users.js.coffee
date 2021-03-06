
class window.User extends BaseModel
  fullName: () ->
    "#{@get('first_name')} #{@get('last_name')}"

class window.Users extends BaseCollection
  model: User
  initialize: () ->
    BaseCollection.prototype.initialize.apply(this, arguments)
    @url = () =>
      "#{@parent.url()}/users"

class window.UserView extends CrmModelView
  modelName: 'user'

class window.UserListItemView extends ListItemView
  modelName: 'user'
  spawnViewType: UserView
  className: 'user-list-item list-item'

  title: () ->
    @model.fullName()

class window.UserAppView extends CollectionAppView
  modelNamePlural: 'users'
  modelName: 'user'
  spawnListItemType: UserListItemView
  className: 'users-gui app-gui'

  title: () ->
    "Users for #{@collection.parent.fullName()}"


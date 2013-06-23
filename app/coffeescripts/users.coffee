
class User extends Backbone.Model
  fullName: () ->
    "#{@get('first_name')} #{@get('last_name')}"

class Users extends BaseCollection
  model: User
  initialize: () ->
    BaseCollection.prototype.initialize.apply(this, arguments)
    @url = () =>
      "#{@parent.url()}/users"

class UserView extends CrmModelView
  modelName: 'user'

class UserListItemView extends ListItemView
  modelName: 'user'
  spawnViewType: UserView
  className: 'user-list-item list-item'

  title: () ->
    @model.fullName()

class UserAppView extends CollectionAppView
  modelName: 'user'
  spawnListItemType: UserListItemView
  className: 'users-gui app-gui'

  title: () ->
    "Users for #{@collection.parent.fullName()}"

  render: () ->
    node = $('.templates .users_view_example').children().clone()
    @$el.html(node)
    @$('h2').text(@title())
    @

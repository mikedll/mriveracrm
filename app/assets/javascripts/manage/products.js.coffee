
class window.Product extends BaseModel
  defaults: () ->
    name: 'New Product'
  fullName: () ->
    @get('name')

  validate: (attrs, options) ->
    if (attrs.email? && attrs.email.trim() != "" && !EmailRegex.test(attrs.email.trim()))
      return {email: "is invalid"}
    return

class window.Products extends Backbone.Collection
  model: Product
  url: '/manage/products'
  initialize: () ->
    Backbone.Collection.prototype.initialize.apply(this, arguments)
    @comparator = (product) ->
      product.get('id')

class window.ProductView extends CrmModelView
  modelName: 'product'

  initialize: () ->
    CrmModelView.prototype.initialize.apply(this, arguments)

class window.ProductListItemView extends ListItemView
  modelName: 'product'
  spawnViewType: ProductView
  className: 'product-list-item list-item'

  display_name: () ->
    @model.get('name')

  title: () ->
    @model.get('name')

class window.ProductAppView extends CollectionAppView
  modelName: 'product'
  spawnListItemType: ProductListItemView
  title: () ->
    'Products'


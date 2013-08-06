
class window.Product extends BaseModel
  defaults: () ->
    name: 'New Product'
  fullName: () ->
    @get('name')

  initialize: () ->
    BaseModel.prototype.initialize.apply(this, arguments)
    @images = new RelatedImages(@get('images'), parent: @)
    @unset('images', silent: true)

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

  copyModelToForm: () ->
    CrmModelView.prototype.copyModelToForm.apply(this, arguments)

  render: () ->
    CrmModelView.prototype.render.apply(this, arguments)

    # should i do something different if render has already been called,
    # and imagesView already exists? what if this render() call did not
    # delete the existing .image-collection-container dom element?
    # why start from scratch?

    @imagesView = new RelatedImagesCollectionView(el: @$('.image-collection-container'), collection: @model.images, parent: @)
    @imagesView.render()
    @


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


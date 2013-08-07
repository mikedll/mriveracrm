
class window.Product extends BaseModel
  defaults: () ->
    name: 'New Product'
    description: ""
    price: null
    weight: null
    weight_units: ""
    active: false
  fullName: () ->
    @get('name')

  initialize: () ->
    BaseModel.prototype.initialize.apply(this, arguments)
    @images = new RelatedImages(@get('product_images'), parent: @)
    @unset('product_images', silent: true)

  onSync: () ->
    BaseModel.prototype.onSync.apply(this, arguments)
    # @images.reset(@get('product_images')) # need to fix reset event on collection
    @unset('product_images', silent: true)

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
    @events = $.extend(@events,
      'click a.expand_more': 'expandMore'
    )

  expandMore: (e) ->
    if $(e.target).hasClass('active')
      @$('.more_info').hide()
    else
      @$('.more_info').show()

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


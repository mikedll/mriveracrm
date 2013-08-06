
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

  render: () ->
    $this = this
    CrmModelView.prototype.render.apply(this, arguments)

    dropzone = new Dropzone(@$('.images_drag_and_drop').get(0),
      url: '/manage/images'
      paramName: 'data',
      parallelUploads: 3,
      uploadMultiple: '' # should enable this at some point, but appends [] to param name
    )
    dropzone.on('sending', (file, xhr, formData) =>
      formData.append('authenticity_token', @$('input[name=authenticity_token]').val())
    )
    dropzone.on('uploadprogress', (file, progress, bytesSent) =>
    )
    dropzone.on('success', (file) =>
      @$('.images_existing').append($('<span>' + file + '</span>'))
    )

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


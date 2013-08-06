
class window.Product extends BaseModel
  defaults: () ->
    name: 'New Product'
  fullName: () ->
    @get('name')

  validate: (attrs, options) ->
    if (attrs.email? && attrs.email.trim() != "" && !EmailRegex.test(attrs.email.trim()))
      return {email: "is invalid"}
    return

  addImageIfNotSynched: (image) ->
    existing = _.find(@get('images'), (i) -> i.id == image.id)
    if existing?
      return false
    @get('images').push(image)

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
    @$('.images_existing').empty()
    _.each(@model.get('images'), (image) =>
      node = $(".image_view_example .image").clone()
      node.find('img').attr('src', image.data.thumb.url)
      @$('.images_existing').append(node)
    )

  render: () ->
    $this = this
    CrmModelView.prototype.render.apply(this, arguments)

    dropzone = new Dropzone(@$('.images_drag_and_drop').get(0),
      url: "/manage/products/#{@model.get('id')}/images"
      paramName: 'data',
      parallelUploads: 3,
      uploadMultiple: '' # should enable this at some point, but appends [] to param name
    )
    dropzone.on('sending', (file, xhr, formData) =>
      formData.append('authenticity_token', @$('input[name=authenticity_token]').val())
    )
    dropzone.on('uploadprogress', (file, progress, bytesSent) =>
    )
    dropzone.on('success', (file, data, xhrProgressEvent) =>
      @model.addImageIfNotSynched(data)
      @copyModelToForm()
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


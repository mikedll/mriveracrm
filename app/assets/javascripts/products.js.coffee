

class window.Product extends BaseModel

class window.SearchableProducts extends Backbone.Collection
  model: Product
  url: '/products'
  initialize: () ->
    Backbone.Collection.prototype.initialize.apply(this, arguments)
    @comparator = (product) ->
      product.get('id')

class window.SearchableProductView extends CrmModelView
  modelName: 'product'

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

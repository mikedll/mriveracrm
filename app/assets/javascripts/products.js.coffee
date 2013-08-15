

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

  copyModelToForm: () ->
    CrmModelView.prototype.copyModelToForm.apply(@, arguments)
    @$('.name').text(@model.get('name'))

  buildDom: () ->
    @$el.html($(".#{@modelName}_view_example").children().clone()) if @$el.children().length == 0

class SearchableProductsView extends SearchAndListView
  searchResultItemViewType: SearchableProductView
  modelNamePlural: 'products'
  modelName: 'product'

  initialize: () ->
    SearchAndListView.prototype.initialize.apply(@, arguments)
    @events = $.extend(@events,
      'change input[name=query]': 'search'
    )

  search: () ->
    _.each( @collection.toArray(), (model) => @collection.remove(model) )
    @collection.fetch(
      data:
        query: @$('input[name=query]').val()
    )

  title: () ->
    "Products"

class window.PartitionedChildrenView extends WithChildrenView
  className: 'container-app app-gui'

  initialize: (options) ->
    WithChildrenView.prototype.initialize.apply(@, arguments)
    @searchableProductsView = new SearchableProductsView(collection: (new SearchableProducts()), parent: @)

  resizeView: () ->
    # override so that we dont shift the content of this box way wrong to the left/top
    h = Math.max( 200, parseInt( $(window).height() * 0.8 ))
    w = Math.max(200, parseInt( $(window).width() * 0.8 ))
    @$el.css(
      'height': h + "px"
      'width': w + "px"
    )

  focusTopModelView: () ->
    @searchableProductsView.focusTopModelView()

  next: () ->
    # don't change user selection in search results
  previous: () ->
    # don't change user selection in search results

  render: () ->
    WithChildrenView.prototype.render.apply(@, arguments)
    @$el.html(@searchableProductsView.render().el) if @$el.children().length == 0
    @


$(() ->
  guiContaner = $('.gui-container')
  stack = new StackedChildrenView(el: guiContaner)
  stack.childViewPushed((new PartitionedChildrenView(parent: stack)).render())
  )


class window.ProductImage extends BaseModel

class window.RelatedImages extends BaseCollection
  model: ProductImage
  url: '/manage/images'
  initialize: () ->
    BaseCollection.prototype.initialize.apply(this, arguments)
    @url = () =>
      "#{@parent.url()}/images"

class ImageView extends CrmModelView
  modelName: 'product_image'
  tagName: 'div'
  className: 'image'

  initialize: () ->
    CrmModelView.prototype.initialize.apply(@, arguments)
    @useDirty = false

    $.extend(@events,
      'change input.active': 'toggleActive'
    )

  toggleActive: (e) ->
    @model.set('active', $(e.target).is(':checked'))
    @save()

  decorateRequesting: () ->
    if @model.isRequesting()
      @$el.addClass('requesting')
    else
      @$el.removeClass('requesting')

  onRequest: (e) ->
    CrmModelView.prototype.onRequest.apply(@, arguments)
    @decorateRequesting()

  onSync: () ->
    CrmModelView.prototype.onSync.apply(@, arguments)
    @decorateRequesting()

  buildDom: () ->
    @$el.html($(".image_view_example .image").children().clone()) if @$el.children().length == 0

  copyModelToForm: () ->
    CrmModelView.prototype.copyModelToForm.apply(@, arguments)
    @$('img.product-image').attr('src', @model.get('image').data.thumb.url)

    if @model.get('primary')
      @$el.addClass('primary')
      @$('.btn[data-action=toggle_primary]').addClass('btn-success')
    else
      @$el.removeClass('primary')
      @$('.btn[data-action=toggle_primary]').removeClass('btn-success')


class window.RelatedImagesCollectionView extends BaseView
  initialize: () ->
    BaseView.prototype.initialize.apply(this, arguments)

    @listenTo(@collection, 'reset', @onReset)
    @listenTo(@collection, 'add', @addOne)
    @listenTo(@collection, 'sync', @onSync)
    @listenTo(@collection, 'error', @onError)
    @childViews = []

  copyModelsToForm: () ->
    # todo: make this more intelligent to not double-render views?
    @$('.images_existing').empty()
    @addAll()

  onSync: (model, resp, options) ->
    BaseView.prototype.onSync.apply(@, arguments)
    @clearHighlightedModelErrors()

    # understands that only 1 of these images can be primary.
    if model.get('primary')
      _.each(@childViews, (view) =>
        if model != view.model && view.model.get('primary')
          view.model.setButIgnoreHistory({'primary': false})
          view.copyModelToForm()
      )

  clearHighlightedModelErrors: () ->
    @$('.errors').hide()

  onReset: () ->
    _.each( @collection.toArray(), (model) => @collection.remove(model) )
    @childViews = []
    @addAll()

  addAll: () ->
    @collection.each(@addOne, @)

  onError: (model, xhr, options) ->
    response = jQuery.parseJSON( xhr.responseText )
    s = ""
    _.chain(response.full_messages).filter((m) ->
      /\w/.test(m)
    ).each((m) ->
      s = "#{s} #{m}"
      s += "." if (!_.contains(['.', '!', '?'], m[ m.length - 1]) )
    )
    @$('.errors').text(s).show()

  addOne: (model) ->
    imageView = new ImageView(model: model, parent: @)
    @childViews.push(imageView)
    @$('.images_existing').append(imageView.render().el)

  render: () ->
    $this = @
    @copyModelsToForm()

    dropzone = new Dropzone(@$('.images_drag_and_drop').get(0),
      url: @collection.url(),
      paramName: 'image[data]',
      parallelUploads: 3,
      uploadMultiple: false # should enable this at some point, but appends [] to param name
    )
    dropzone.on('sending', (file, xhr, formData) =>
      formData.append('authenticity_token', @$el.closest('form').find('input[name=authenticity_token]').val())
    )
    dropzone.on('uploadprogress', (file, progress, bytesSent) =>
    )
    dropzone.on('success', (file, data, xhrProgressEvent) =>
      file.previewElement.remove()
      @collection.add(new ProductImage(data))
    )

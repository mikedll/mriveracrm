
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

    $.extend(@events,
      'change input.active': 'toggleActive'
    )

  toggleActive: (e) ->
    @model.set('active', $(e.target).is(':checked'))
    @save()

  buildDom: () ->
    @$el.html($(".image_view_example .image").children().clone()) if @$el.children().length == 0

  copyModelToForm: () ->
    CrmModelView.prototype.copyModelToForm.apply(@, arguments)
    @$('img').attr('src', @model.get('image').data.thumb.url)
    @$el.parent().children().removeClass('primary')
    if @model.get('primary')
      @$el.addClass('primary')
    else
      @$el.removeClass('primary')

class window.RelatedImagesCollectionView extends BaseView
  initialize: () ->
    BaseView.prototype.initialize.apply(this, arguments)

    @listenTo(@collection, 'reset', @onReset)
    @listenTo(@collection, 'add', @addOne)
    @listenTo(@collection, 'sync', @onSync)
    @listenTo(@collection, 'error', @onError)

  copyModelsToForm: () ->
    # todo: make this more intelligent to not double-render views?
    @$('.images_existing').empty()
    @addAll()

  onSync: (model, resp, options) ->
    @clearHighlightedModelErrors()

  clearHighlightedModelErrors: () ->
    @$('.errors').hide()

  onReset: () ->
    _.each( @collection.toArray(), (model) => @collection.remove(model) )
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

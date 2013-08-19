
#
# The fileUpload attribute on this model is not
# a part of the attributes.
#
class window.ProductImage extends BaseModel
  defaults: () ->
    primary: false
    active: false

  initialize: (attrs, options) ->
    BaseModel.prototype.initialize.apply(@, arguments)
    @fileUpload = if ('fileUpload' of options) then options.fileUpload else null

  onChange: () ->
    BaseModel.prototype.onChange.apply(@, arguments)
    if @fileUpload? && (typeof(@get('image')) != "undefined" && @get('image')?)
      @fileUpload = null

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
    if @model.get('image')
      @$('img.product-image').attr('src', @model.get('image').data.thumb.url)
    else if (@model.fileUpload? && ('dataUrl' of @model.fileUpload))
      @$('img.product-image').attr('src', @model.fileUpload.dataUrl)

    if @model.fileUpload? && @model.fileUpload.upload.progress < 100
      @$el.addClass('uploading')
      @$('.progress .bar').css('width', @model.fileUpload.upload.progress + '%')
    else
      @$el.removeClass('uploading')

    if @model.get('primary')
      @$el.addClass('primary')
      @$('.btn[data-action=toggle_primary]').addClass('btn-success')
    else
      @$el.removeClass('primary')
      @$('.btn[data-action=toggle_primary]').removeClass('btn-success')

  onModelChanged: () ->
    CrmModelView.prototype.onModelChanged.apply(@, arguments)
    @copyModelToForm()
    @decorateRequesting()



class window.RelatedImagesCollectionView extends BaseView
  initialize: () ->
    BaseView.prototype.initialize.apply(this, arguments)

    @listenTo(@collection, 'reset', @onReset)
    @listenTo(@collection, 'add', @addOne)
    @listenTo(@collection, 'sync', @onSync)
    @listenTo(@collection, 'error', @onError)
    @childViews = []
    @filesToModels = {}
    @uploadedFilesIds = 0

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
          # we have to not emit sync if this model isn't in an errorneous
          # state, or we risk infinite recursion, since this sync
          # will be triggered.
          view.model.setAndAssumeSync({'primary': false})
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
      thumbnailWidth: 160,
      thumbnailHeight: 133,
      previewsContainer: @$('.discarded_dropzone_previews').get(0),
      uploadMultiple: false # should enable this at some point, but appends [] to param name
    )
    dropzone.on('addedfile', (file) =>
      file._relatedImageCollectionViewId = @uploadedFilesIds++
      file.previewElement.remove() # we're not going to use dropzone's preview. remove from dom.

      if ! (file._relatedImageCollectionViewId of @filesToModels)
        @filesToModels[file._relatedImageCollectionViewId] = new ProductImage({}, {fileUpload: file}) # we'll use this in the 'success' event
        @filesToModels[file._relatedImageCollectionViewId].trigger('request')
      @collection.add(@filesToModels[file._relatedImageCollectionViewId])
    )
    dropzone.on('thumbnail', (file, dataUrl) =>
      file.dataUrl = dataUrl
      @filesToModels[file._relatedImageCollectionViewId].trigger('change')
    )
    dropzone.on('sending', (file, xhr, formData) =>
      formData.append('authenticity_token', @$el.closest('form').find('input[name=authenticity_token]').val())
    )
    dropzone.on('uploadprogress', (file, progress, bytesSent) =>
      @filesToModels[file._relatedImageCollectionViewId].trigger('change')
    )
    dropzone.on('success', (file, data, xhrProgressEvent) =>
      if @filesToModels[file._relatedImageCollectionViewId]?
        @filesToModels[file._relatedImageCollectionViewId].setAndAssumeSync(data)
      else
        # where did our image go? scary. this is probably a bug.
        @collection.add(new ProductImage(data))

      delete @filesToModels[file._relatedImageCollectionViewId] # we dont need a ref to this file anymore.
    )

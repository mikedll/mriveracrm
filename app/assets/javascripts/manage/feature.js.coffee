
class window.Feature extends BaseModel

class window.Features extends Backbone.Collection
  model: Feature

  initialize: () ->
    Backbone.Collection.prototype.initialize.apply(this, arguments)
    @all = () ->
      reset(__features)

  all: () ->
    @all

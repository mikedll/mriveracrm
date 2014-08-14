
class window.BillingSettings extends BaseModel
  hasrelations: ['features_selections_attributes']
  url: () ->
    gUrlManager.url('/manage/billing_settings')

  isNew: () ->
    false

  set: (attrs) ->
    _.each(attrs, (v, attribute_name) =>
      if _.contains(@hasrelations, attribute_name)
        orig_related_set = if attribute_name of @_attributesSinceSync then @_attributesSinceSync[attribute_name] else @get(attribute_name)

        # was there originally and now is gone (fading)
        _.each(orig_related_set, (some_orig_relation) ->
          if not _.some(v, (relation_to_set) -> some_orig_relation['id'] == relation_to_set['id'])
            v.push(
              'id': some_orig_relation['id']
              '_destroy': '1'
            )
        )

        # was there originally, was deleted, and has returned
        _.each(orig_related_set, (some_orig_relation) ->
          returned = _.find(v, (relation_to_set) -> relation_to_set['id'] == some_orig_relation['id'] && relation_to_set['_destroy'] == '1')
          delete relation_to_set['_destroy']
        )

        # not there originally. added. no action.

        # not there originally, added, removed.
    )
    BaseModel.prototype.set.apply(@, [attrs])

class window.BillingSettingsView extends CrmModelView
  modelName: 'billing_settings'

  initialize: (options) ->
    CrmModelView.prototype.initialize.apply(@, arguments)
    @useDirty = false
    @features = new Features()


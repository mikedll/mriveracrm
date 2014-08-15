
class window.BillingSettings extends BaseModel

  initialize: () ->
    BaseModel.prototype.initialize.apply(@, arguments)
    @hasrelations =
      'feature_selections_attributes': 'feature_id'

  url: () ->
    gUrlManager.url('/manage/billing_settings')

  isNew: () ->
    false

  #
  # There are so many nested loops here. This may need
  # to be performance improved with some hashes.
  #
  set: (attrs) ->
    _.each(attrs, (v, attribute_name) =>
      if attribute_name of @hasrelations
        idField = @hasrelations[attribute_name]
        cur_related_set = @get(attribute_name)
        orig_related_set = if attribute_name of @_attributesSinceSync then @_attributesSinceSync[attribute_name] else cur_related_set
        prev_related_set = @previous(attribute_name)

        # do a merge of attributes, usin the idField as a matcher.
        # if an intermediate table is being used in a many-to-many, this preserves the key
        # of the relation object.
        # (n * m) where n == size(v) and m == size(current value of this attribute)
        _.each(v, (relation, i) ->

          # retain existing keys if we are overriding one
          relation_before = _.find(cur_related_set, (r) -> r[idField] == relation[idField])
          if typeof(relation_before) != "undefined"
            relation = _.extend({}, relation_before, relation)

            # this relation was present originally, was deleted, and has returned. cancel _destroy.
            if _.has(relation, '_destroy')
              delete relation['_destroy']

          v[i] = relation # modifying relation for some reason doesn't modify v, the array.
        )

        # scan for relations that were there originally, and are now now gone, or fading. mark with _destroy.
        # (o * n) where o == size(original value of this attribute) and n == size(v)
        _.each(orig_related_set, (orig_relation) ->
          if not _.some(v, (relation) -> relation[idField] == orig_relation[idField])
            v.push(_.extend({}, orig_relation, {'_destroy': '1'}))
        )

        # not there originally. added. no action.

        # not there originally, added, removed. no action is needed for this.
    )
    BaseModel.prototype.set.apply(@, [attrs])


class window.BillingSettingsView extends CrmModelView
  modelName: 'billing_settings'

  initialize: (options) ->
    CrmModelView.prototype.initialize.apply(@, arguments)
    @useDirty = false
    @features = new Features()



class window.SeoRanker extends BaseModel
  urlFragment: '/manage/seo_ranker'
  isNew: () ->
    false

class window.SeoRankerView extends CrmModelView
  modelName: 'seo_ranker'

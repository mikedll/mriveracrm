
$(() ->
  guiContaner = $('.gui-container')
  stack = new StackedChildrenView(el: guiContaner)

  anchorSelectorsToAppConfigs =
    '.clients-gui':
      modelCollectionKlass: Clients
      rootAppViewKlass: ClientAppView
    '.products-gui':
      modelCollectionKlass: Products
      rootAppViewKlass: ProductAppView

  lazyGetBootstrap = (selector) ->
    # prevent undefined reference. can be removed if we make __XXX generic
    # instead of named by model.
    if selector == '.clients-gui'
      return __clients
    else if selector == '.products-gui'
      return __products
    else
      # something went wrong here.
      return []

  anchorSelector = _.find(_.keys(anchorSelectorsToAppConfigs), (selector) ->
    guiContaner.find(selector).length > 0
  )

  if typeof(anchorSelector) != "undefined"
    config = anchorSelectorsToAppConfigs[anchorSelector]
    console.log(anchorSelector)
    console.log(config)
    rootViewAnchor = guiContaner.find(anchorSelector)
    modelCollectionKlass = config.modelCollectionKlass
    rootAppViewKlass = config.rootAppViewKlass
    rootCollectionBootstrap = lazyGetBootstrap(anchorSelector)

    rootCollection = new modelCollectionKlass()
    rootApp = new rootAppViewKlass(el: rootViewAnchor, collection: rootCollection, parent: stack)
    rootApp.render()
    stack.childViewPushed(rootApp)
    rootCollection.reset(rootCollectionBootstrap)

  )

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
    '.business-gui':
      modelKlass: Business
      modelViewKlass: BusinessView
      rootAppViewKlass: SingleModelAppView
    '.billing-settings-gui':
      modelKlass: BillingSettings
      modelViewKlass: BillingSettingsView
      rootAppViewKlass: SingleModelAppView
    '.status-monitor-gui':
      modelKlass: StatusMonitor
      modelViewKlass: StatusMonitorView
      rootAppViewKlass: SingleModelAppView
    '.it-computer-monitors-gui':
      modelCollectionKlass: ItComputerMonitors
      rootAppViewKlass: ItComputerMonitorAppView

  lazyGetBootstrap = (selector) ->
    # prevent undefined reference. can be removed if we make __XXX generic
    # instead of named by model.
    if selector == '.clients-gui'
      return __clients
    else if selector == '.products-gui'
      return __products
    else if selector == '.business-gui'
      return __business
    else if selector == '.billing-settings-gui'
      return __billing_settings
    else if selector == '.it-computer-monitors-gui'
      return __it_computer_monitors
    else
      # something went wrong here.
      return []

  anchorSelector = _.find(_.keys(anchorSelectorsToAppConfigs), (selector) ->
    guiContaner.find(selector).length > 0
  )

  if typeof(anchorSelector) != "undefined"
    config = anchorSelectorsToAppConfigs[anchorSelector]
    rootViewAnchor = guiContaner.find(anchorSelector)
    rootAppViewKlass = config.rootAppViewKlass

    rootApp = null
    if config.modelCollectionKlass?
      # resources
      modelCollectionKlass = config.modelCollectionKlass
      rootCollectionBootstrap = lazyGetBootstrap(anchorSelector)
      rootCollection = new modelCollectionKlass()
      rootApp = new rootAppViewKlass(el: rootViewAnchor, collection: rootCollection, parent: stack)
    else if config.modelKlass?
      # resource
      modelBootstrap = lazyGetBootstrap(anchorSelector)
      model = new config.modelKlass()
      modelView = new config.modelViewKlass(model: model)
      rootApp = new rootAppViewKlass(el: rootViewAnchor, parent: stack)
      rootApp.husband(modelView)
    else
      AppsLogger.log("no model klass and no model collection class to load.")
      return

    if rootApp?
      rootApp.render()
      stack.childViewPushed(rootApp)
      if config.modelCollectionKlass?
        rootCollection.reset(rootCollectionBootstrap)
        rootCollection.trigger('bootstrapped')
      else if config.modelKlass?
        model.setAndAssumeSync(modelBootstrap) if modelBootstrap? && modelBootstrap != [] # some pages dont have one
      else
        # exception. handled above.

    else
      AppsLogger.log("No rootApp found.")

  )
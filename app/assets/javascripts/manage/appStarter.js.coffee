
window.Manage = {} if typeof(window.Manage) == "undefined"

class window.Manage.AppStarter

  constructor: (guiContainerSelector, @options) ->
    @stackKlass = @options.stackKlass if @options.stackKlass
    @guiContainer = $(guiContainerSelector)

  start: (config) ->
    rootViewAnchor = @guiContainer.find(config.selector).first()

    if rootViewAnchor.length == 0
      AppsLogger.log("No available dom for #{config.selector} app configuration.")
      return false

    @appStack = new @stackKlass(el: @guiContainer)

    rootAppViewKlass = config.rootAppViewKlass
    rootApp = null
    if config.modelCollectionKlass?
      # resources
      modelCollectionKlass = config.modelCollectionKlass
      rootCollectionBootstrap = config.lazyBootstrap()
      rootCollection = new modelCollectionKlass()
      rootApp = new rootAppViewKlass(el: rootViewAnchor, collection: rootCollection, parent: @appStack)
    else if config.modelKlass?
      # resource
      modelBootstrap = config.lazyBootstrap()
      model = new config.modelKlass()
      modelView = new config.modelViewKlass(model: model)
      rootApp = new rootAppViewKlass(el: rootViewAnchor, parent: @appStack)
      rootApp.husband(modelView)
    else
      AppsLogger.log("no model klass and no model collection class to load.")
      return

    if rootApp?
      rootApp.render()
      @appStack.childViewPushed(rootApp)
      if config.modelCollectionKlass?
        rootCollection.reset(rootCollectionBootstrap)
        rootApp.customSetup() if config.custom_setup # heterogeneous supplementary setup
      else if config.modelKlass?
        model.setAndAssumeSync(modelBootstrap) if modelBootstrap? && modelBootstrap != [] # some pages dont have one
      else
        # exception. handled above.

    else
      AppsLogger.log("No rootApp found.")

$(() ->
  window.gAppStarter = new Manage.AppStarter('.gui-container', stackKlass: StackedChildrenView)
  )

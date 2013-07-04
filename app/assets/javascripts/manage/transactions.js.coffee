
class window.Transaction extends BaseModel
  title: () ->
    "Transaction #{@get('id')}"

class window.Transactions extends BaseCollection
  model: Transaction
  initialize: () ->
    BaseCollection.prototype.initialize.apply(this, arguments)
    @url = () =>
      "#{@parent.url()}/transactions"

class window.TransactionView extends CrmModelView
  modelName: 'transaction'

  copyModelToForm: () ->
    CrmModelView.prototype.copyModelToForm.apply(this, arguments)
    if @model.get('type') == 'OutsideTransaction'
      @$('.outside_transaction_fields').show()
    else
      @$('.outside_transaction_fields').hide()

class window.TransactionListItemView extends ListItemView
  modelName: 'transaction'
  spawnViewType: TransactionView
  className: 'transaction-list-item list-item'

  title: () ->
    @model.title()

class window.TransactionAppView extends CollectionAppView
  modelName: 'transaction'
  spawnListItemType: TransactionListItemView
  className: 'transactions-gui app-gui'

  title: () ->
    "Transactions for #{@collection.parent.title()}"

  render: () ->
    node = $('.templates .transactions_view_example').children().clone()
    @$el.html(node)
    @$('h2').text(@title())
    @


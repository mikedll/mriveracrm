class Manage::ReportsController < Manage::BaseController

  configure_apps do
    actions :index, :show
    include_templates :report
  end

  def current_objects
    return @current_objects if @current_objects

    refyear = Time.zone.now.year
    years = 4.times.map { |i| refyear - i }
    @current_objects = years.map do |y|
      amount = current_business.clients.inject(BigDecimal.new("0")) do |acc, c|
        acc += c.invoices.transactable.inject(BigDecimal.new("0")) do |acc, i|
          acc += i.transactions.successful.last_changed_in_year(y).inject(BigDecimal.new("0")) do |acc, t|
            acc += t.amount
            acc
          end
          acc
        end
        acc
      end

      {
        :name => "#{y} Earnings",
        :amount => amount
      }
    end
  end

  def _require_business_support
    _bsupports?(Feature::Names::INVOICING)
  end

end

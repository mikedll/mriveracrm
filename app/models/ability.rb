class Ability
  include CanCan::Ability

  class RoutesAdminConstraint
    def matches?(request)
      current_user = request.env['warden'].user
      current_user.present? && current_user.is_admin?
    end
  end

  def initialize(user)
    user ||= User.new

    if user.is_admin?
      can :manage, :all
    else

      can :manage, Business do |business|
        user.employee && user.employee.business_id == business.id && user.employee.owner?
      end

      can :manage, UsageSubscription do |usage_subscription|
        user.employee && user.employee.business_id == usage_subscription.business_id && user.employee.owner?
      end
    end
  end

end

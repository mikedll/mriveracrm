class Ability
  include CanCan::Ability

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

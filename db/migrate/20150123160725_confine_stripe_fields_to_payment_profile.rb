class ConfineStripeFieldsToPaymentProfile < ActiveRecord::Migration

  def up
    add_column :payment_gateway_profiles, :stripe_trial_ends_at, :datetime, :default => nil
    add_column :payment_gateway_profiles, :stripe_current_period_ends_at, :datetime, :default => nil
    add_column :payment_gateway_profiles, :stripe_plan, :string, :default => ""
    add_column :payment_gateway_profiles, :stripe_status, :string, :default => ""

    execute "
UPDATE payment_gateway_profiles SET stripe_trial_ends_at = (select trial_ends_at from usage_subscriptions where id = payment_gateway_profiles.payment_gateway_profilable_id)
"

    execute "
UPDATE payment_gateway_profiles SET stripe_current_period_ends_at = (select current_period_ends_at from usage_subscriptions where id = payment_gateway_profiles.payment_gateway_profilable_id)
"

    execute "
UPDATE payment_gateway_profiles SET stripe_plan = (select plan from usage_subscriptions where id = payment_gateway_profiles.payment_gateway_profilable_id)
"

    execute "
UPDATE payment_gateway_profiles SET stripe_status = (select remote_status from usage_subscriptions where id = payment_gateway_profiles.payment_gateway_profilable_id)
"

    remove_column :usage_subscriptions, :trial_ends_at
    remove_column :usage_subscriptions, :current_period_ends_at
    remove_column :usage_subscriptions, :plan
    remove_column :usage_subscriptions, :remote_status
  end

  def down
    add_column :usage_subscriptions, :trial_ends_at, :datetime, :default => nil
    add_column :usage_subscriptions, :current_period_ends_at, :datetime, :default => nil
    add_column :usage_subscriptions, :plan, :string, :default => ""
    add_column :usage_subscriptions, :remote_status, :string, :default => ""

    execute "
UPDATE usage_subscriptions
SET trial_ends_at = (select stripe_trial_ends_at from payment_gateway_profiles where payment_gateway_profiles.payment_gateway_profilable_id = usage_subscriptions.id AND payment_gateway_profilable_type = 'UsageSubscription')
FROM payment_gateway_profiles
WHERE payment_gateway_profiles.payment_gateway_profilable_id = usage_subscriptions.id
"

    execute "
UPDATE usage_subscriptions SET current_period_ends_at = (select stripe_current_period_ends_at from payment_gateway_profiles where payment_gateway_profilable_id = usage_subscriptions.id AND payment_gateway_profilable_type = 'UsageSubscription')
FROM payment_gateway_profiles
WHERE payment_gateway_profiles.payment_gateway_profilable_id = usage_subscriptions.id
"

    execute "
UPDATE usage_subscriptions SET plan = (select stripe_plan from payment_gateway_profiles where payment_gateway_profilable_id = usage_subscriptions.id AND payment_gateway_profilable_type = 'UsageSubscription')
FROM payment_gateway_profiles
WHERE payment_gateway_profiles.payment_gateway_profilable_id = usage_subscriptions.id
"

    execute "
UPDATE usage_subscriptions SET remote_status = (select stripe_status from payment_gateway_profiles where payment_gateway_profilable_id = usage_subscriptions.id AND payment_gateway_profilable_type = 'UsageSubscription')
FROM payment_gateway_profiles
WHERE payment_gateway_profiles.payment_gateway_profilable_id = usage_subscriptions.id
"

    remove_column :payment_gateway_profiles, :stripe_trial_ends_at
    remove_column :payment_gateway_profiles, :stripe_current_period_ends_at
    remove_column :payment_gateway_profiles, :stripe_plan
    remove_column :payment_gateway_profiles, :stripe_status
  end

end

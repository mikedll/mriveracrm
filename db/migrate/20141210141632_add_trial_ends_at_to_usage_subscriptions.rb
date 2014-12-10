class AddTrialEndsAtToUsageSubscriptions < ActiveRecord::Migration
  def change

    add_column :usage_subscriptions, :trial_ends_at, :datetime, :default => nil
    add_column :usage_subscriptions, :current_period_ends_at, :datetime, :default => nil

  end
end

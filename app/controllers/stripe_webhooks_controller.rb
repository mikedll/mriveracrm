class StripeWebhooksController < ApplicationController

  skip_before_filter :verify_authenticity_token
  skip_before_filter :authenticate_user!
  skip_before_filter :require_business_and_current_user_belongs_to_it



  # This hackj is only for dev mode...normally this stuff will be filled in.
  # skip_before_filter :_require_business_or_mfe
  # before_filter do
  #   raise "should have been disabled" if Rails.env.production?
  #   MarketingFrontEnd.current = MarketingFrontEnd.first
  #   RequestSettings.host = MarketingFrontEnd.current.host
  # end

  def create
    if params[:type] == StripePaymentGatewayProfile::Events::SUBSCRIPTION_UPDATED

      # hackity mchacks a lot. use a singleton? hmm.
      event = StripePaymentGatewayProfile.new.webhook_event_with_stripe_key(AppConfiguration.get('stripe.secret_key'), params[:id])

      if event

        subscription = event.data.values[0]
        previous_values = event.data.values[1]
        if event.type == StripePaymentGatewayProfile::Events::SUBSCRIPTION_UPDATED
          profile = StripePaymentGatewayProfile.by_vendor_id(subscription['customer']).first
          if profile && profile.subscribable?
            profile.reload_remote
            if !previous_values['status'].blank? && previous_values['status'] != subscription['status'] && !profile.active_plan?
              profile.payment_gateway_profilable.notify_inactive!
            end
          else
            # Found event, but not the customer record. dismiss the event,
            # but remember in our system that we messed up.
            DetectedError.create("Received webhook for customer that we didn't handle: #{subscription.customer}")
          end
        end

        head :ok
      else
        # not existent event
        head :not_found
      end
    else

      # this is a trade off. on the one hand, lets attackers identify this end and DOS us. on the other hand,
      # we don't recognize this hook...we don't care.
      # todo: build this stripe key retrieval into the mfe.
      head :ok

    end
  end

end

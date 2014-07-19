class UsageSubscription < ActiveRecord::Base
  belongs_to :business

  attr_accessible :card_brand, :card_last_4, :plan, :remote_id

  #
  # A given business may registered with a package that enables or
  # disables certain features, based on that business’ request. Billing
  # will assign to that business a monthly subscription that associates
  # costs with different features.

  # A business that doesn’t leverage a given feature may avoid the cost
  # of it.

  # A given MFE will be able to package certain feature sets by default,
  # thereby simplifying, or even hiding, the feature set from the end
  # user.  Stripe can associate a plan, with a plan code, that will
  # assign the subscription of the business a given monthly cost. As
  # that cost lapses, we can make decisions on how to dun the user’s
  # subscription...for example, we may disable all users for the
  # business for a period of time, like say, 1 year.

  # A challenge is that we will be adding and removing features
  # constantly. Each feature will have a cost, likely per user. How do
  # we bill for this?

  # We could simply roll monthly invoices, though that would leverage
  # none of Stripe’s recurrent billing, dunning, and bounced credit card
  # functionality.

  # If a given customer, Charlemagne, signs up for Clients and Products
  # basic features, and a later customer signs up for Portfolio, and we
  # want to charge $5/month per user for clients, and $10/month per user
  # for products, and $3/month per user for a portfolio...what are the
  # plan names? Doesn’t it seem like we want a bit string for this?
  # Especially if we have re-releases of features for different pricing?
  # Can we do that? For example, feature 1, release 1? Where release 1
  # end users retain the benefits of their pricing?

  # This should work, and provide very nice bit strings.

  # All that remains is to have a list of releases, each of which
  # supports a list of features. Earlier releases will have nulls for
  # feature slots that were never used.

  # Then, we have a list of features that take up slots in the bit
  # string, indicating true or false.

  # The release part of the bit string should support a lot of
  # releases...If we released once a week for 20 years, we’d need 1040
  # values. In later generations, we can simply scrap old pricing and
  # raise pricing mechanisms...level the playing field and eliminate
  # certain generations.

  # Or even add to the bitstring. A release a week for 100 years. That’s
  # 5,000. Or, 2^15 bits to pass that up. Let’s say 16 bits, then.

  # That leaves 48 bits to complete the first digit of a base 64
  # encoding integer, for 48 features. Let’s add another eight sets of
  # 64 features. This makes 9 characters in the base-64 encoded string.

  # This is the Stripe ID of the plan, and the name can be simply “CRM
  # v24 32” with leading zeros. Bits representing features will be
  # populated from the rhs of the string.

  # This means we can look at a Stripe plan and calculate which release
  # and set of features went into it.

  # Stripe provides meta data for features but that would entail making
  # names for plan and there doesn’t seem to be a point to that.  This
  # is, obviously, a departure from Gold/Bronze/Silver pricing. Bulk
  # discounts are not being provided here. Those can be handled via
  # coupons, or something. Or just not handled.

  # We also add 4 bits to cover 16 pricing schemes, this scheme just
  # being one of them, so that the same stripe key can be used for
  # customly-named plans that dont use this scheme (note that this may
  # result in a wasted first base-64 character in those plan's names,
  # or ids). This takes away 4 bits from the 48 bits that were
  # remaining for the first base-64 encoded character.

  # The bit string is thus:

  # [ 4 bits for pricing scheme | 16 bits for release | 44 bits + 8 x 64 bits for features, starting at RHS ]

  # Which should result in 9 characters, base 64 encoded.

  # The cost of the plan can be determined from lookup tables in the
  # app.

  def _remote_create
    
  end


end

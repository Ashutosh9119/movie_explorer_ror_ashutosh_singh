class SubscriptionPaymentService
  def self.process_payment(user:, validity:)
    return { success: false, error: 'Invalid validity' } unless Subscription.validities.key?(validity)

    subscription = user.subscription || Subscription.new(user: user)

    # For now, we don't have a free plan, so all validities require payment
    customer = find_or_create_customer(user)
    return { success: false, error: 'Failed to create Stripe customer' } unless customer

    price_id = case validity
               when 'daily' then Rails.application.credentials.stripe[:price_daily]
               when 'weekly' then Rails.application.credentials.stripe[:price_weekly]
               when 'monthly' then Rails.application.credentials.stripe[:price_monthly]
               else return { success: false, error: "Unknown validity: #{validity}" }
               end

    duration = case validity
               when 'daily' then 1.day
               when 'weekly' then 7.days
               when 'monthly' then 30.days
               end

    amount = case validity
             when 'daily' then 199.00
             when 'weekly' then 499.00
             when 'monthly' then 999.00
             end

    base_url = Rails.env.development? ? "http://localhost:3000" : "https://movie-explorer-ror-ashutosh-singh.onrender.com"
    success_url = "#{base_url}/api/v1/subscription/success?session_id={CHECKOUT_SESSION_ID}&validity=#{validity}"
    cancel_url = "#{base_url}/api/v1/subscription/cancel?session_id={CHECKOUT_SESSION_ID}"

    session = Stripe::Checkout::Session.create(
      customer: customer.id,
      payment_method_types: ['card'],
      line_items: [{ price: price_id, quantity: 1 }],
      mode: 'payment',
      success_url: success_url,
      cancel_url: cancel_url
    )

    subscription.update!(
      validity: validity,
      status: 'pending',
      session_id: session.id,
      session_expires_at: Time.at(session.expires_at),
      start_date: Time.current,
      end_date: Time.current + duration,
      amount: amount
    )

    { success: true, session: session, subscription: subscription }
  rescue Stripe::StripeError => e
    { success: false, error: "Stripe session creation failed: #{e.message}" }
  rescue StandardError => e
    { success: false, error: "An unexpected error occurred: #{e.message}" }
  end

  def self.complete_payment(user:, session_id:)
    session = Stripe::Checkout::Session.retrieve(session_id)
    return { success: false, error: 'Payment not completed' } unless session.payment_status == 'paid'

    subscription = Subscription.find_by(user: user, session_id: session_id, status: 'pending')
    return { success: false, error: 'Pending subscription not found' } unless subscription

    subscription.activate!
    { success: true, subscription: subscription }
  rescue Stripe::StripeError => e
    { success: false, error: e.message }
  rescue StandardError => e
    { success: false, error: "An unexpected error occurred: #{e.message}" }
  end

  def self.find_or_create_customer(user)
    customer = if user.stripe_customer_id
                 Stripe::Customer.retrieve(user.stripe_customer_id)
               else
                 Stripe::Customer.create(email: user.email).tap do |c|
                   user.update!(stripe_customer_id: c.id)
                 end
               end
    customer
  rescue Stripe::InvalidRequestError
    user.update!(stripe_customer_id: nil) if user.stripe_customer_id
    nil
  end
end
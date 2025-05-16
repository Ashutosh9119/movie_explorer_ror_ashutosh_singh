class Api::V1::SubscriptionsController < ApplicationController
  before_action :authenticate_user!, except: [:success, :cancel]
  before_action :set_subscription, only: [:show]
  skip_before_action :verify_authenticity_token

  def create
    # Ensure a subscription exists for the user
    subscription = current_user.subscription || current_user.build_subscription(plan_type: 'basic', status: 'active')
    Rails.logger.info "Creating subscription for user #{current_user.id}"
    subscription.save! if subscription.new_record?

    begin
      # Create a Stripe customer if none exists
      if subscription.stripe_customer_id.nil?
        Rails.logger.info "Creating Stripe customer for user #{current_user.id}"
        customer = Stripe::Customer.create(email: current_user.email)
        subscription.update!(stripe_customer_id: customer.id)
      end

      # Validate plan_type
      plan_type = params[:plan_type]
      return render json: { error: 'Invalid plan type' }, status: :bad_request unless %w[1_day 7_days 1_month].include?(plan_type)

      # Map plan_type to Stripe price_id
      price_id = case plan_type
                 when '1_day'
                   'price_1RNpF0RsI4MF5d1JO1liYdI7'
                 when '7_days'
                   'price_1RNpGaRsI4MF5d1JNfg2L7S7'
                 when '1_month'
                   'price_1RNpIFRsI4MF5d1JHfAKIqrP'
                 end

      Rails.logger.info "Creating Stripe checkout session with price_id: #{price_id}"
      session = Stripe::Checkout::Session.create(
        customer: subscription.stripe_customer_id,
        payment_method_types: ['card'],
        line_items: [{ price: price_id, quantity: 1 }],
        mode: 'payment',
        metadata: {
          user_id: current_user.id,
          plan_type: plan_type
        },
        success_url: "https://movie-explorer-react-js-shruti.vercel.app/success?session_id={CHECKOUT_SESSION_ID}",
        cancel_url: "http://localhost:5173/cancel"
      )

      Rails.logger.info "Stripe session created: #{session.id}"
      render json: { session_id: session.id, url: session.url }, status: :ok
    rescue Stripe::StripeError => e
      Rails.logger.error "Stripe error: #{e.message}"
      render json: { error: "Stripe error: #{e.message}" }, status: :bad_request
    rescue StandardError => e
      Rails.logger.error "General error: #{e.message}"
      render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
    end
  end

  def success
    begin
      session = Stripe::Checkout::Session.retrieve(params[:session_id])
      subscription = Subscription.find_by(stripe_customer_id: session.customer)

      if subscription
        plan_type = session.metadata.plan_type
        expires_at = case plan_type
                     when '1_day'
                       1.day.from_now
                     when '7_days'
                       7.days.from_now
                     when '1_month'
                       1.month.from_now
                     end
        subscription.update(plan_type: 'premium', status: 'active', expires_at: expires_at)
        Rails.logger.info "Subscription updated to premium for user #{subscription.user_id}"
        render json: { message: 'Subscription updated successfully' }, status: :ok
      else
        Rails.logger.warn "Subscription not found for Stripe customer #{session.customer}"
        render json: { error: 'Subscription not found' }, status: :not_found
      end
    rescue Stripe::StripeError => e
      Rails.logger.error "Stripe error in success: #{e.message}"
      render json: { error: "Stripe error: #{e.message}" }, status: :bad_request
    rescue StandardError => e
      Rails.logger.error "General error in success: #{e.message}"
      render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
    end
  end

  def cancel
    Rails.logger.info "Payment cancelled for user #{current_user&.id || 'unknown'}"
    render json: { message: 'Payment cancelled' }, status: :ok
  end

  def status
    subscription = current_user.subscription

    if subscription.nil?
      Rails.logger.warn "No active subscription found for user #{current_user.id}"
      render json: { error: 'No active subscription found' }, status: :not_found
      return
    end

    if subscription.plan_type == 'premium' && subscription.expires_at.present? && subscription.expires_at < Time.current
      subscription.update(plan_type: 'basic', status: 'active', expires_at: nil)
      Rails.logger.info "Subscription downgraded to basic for user #{current_user.id}"
      render json: { plan_type: 'basic', message: 'Your subscription has expired. Downgrading to basic plan.' }, status: :ok
    else
      Rails.logger.info "Subscription status checked for user #{current_user.id}: #{subscription.plan_type}"
      render json: { plan_type: subscription.plan_type }, status: :ok
    end
  end

  def index
    subscription = current_user.subscription
    Rails.logger.info "Fetching subscription for user #{current_user.id}"
    render json: { subscription: subscription }, status: :ok
  end

  def show
    Rails.logger.info "Showing subscription for user #{current_user.id}"
    render json: { subscription: @subscription }, status: :ok
  end

  private

  def set_subscription
    @subscription = current_user.subscription
    if @subscription.nil?
      Rails.logger.warn "Subscription not found for user #{current_user.id}"
      render json: { error: 'Subscription not found' }, status: :not_found
    end
  end
end
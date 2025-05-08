module Api
  module V1
    class SubscriptionsController < ApplicationController
      skip_before_action :verify_authenticity_token # Skip CSRF token for API
      before_action :authenticate_user! # Require JWT for all actions
      before_action :set_subscription, only: [:show, :update, :destroy]

      # POST /api/v1/subscription
      def create
        if current_user.subscription.present?
          render json: { error: "User already has a subscription" }, status: :unprocessable_entity
          return
        end

        plan_type = subscription_params[:plan_type]
        plan_names = { 0 => 'Basic Plan', 1 => 'Premium Plan' }
        price_amounts = { 0 => 49900, 1 => 99900 } # INR in paise

        unless plan_names.key?(plan_type)
          render json: { error: "Invalid plan_type" }, status: :bad_request
          return
        end

        # Stripe Customer
        stripe_customer = Stripe::Customer.create(email: current_user.email)

        # Stripe Product and Price
        product = Stripe::Product.create(name: plan_names[plan_type])
        price = Stripe::Price.create({
          unit_amount: price_amounts[plan_type],
          currency: 'inr',
          recurring: { interval: 'month' },
          product: product.id
        })

        # Payment Method (for test/demo, hardcoded card)
        payment_method = Stripe::PaymentMethod.create({
          type: 'card',
          card: {
            number: '4242424242424242',
            exp_month: 12,
            exp_year: 2026,
            cvc: '123'
          }
        })

        Stripe::PaymentMethod.attach(payment_method.id, customer: stripe_customer.id)

        # Stripe Subscription
        stripe_subscription = Stripe::Subscription.create({
          customer: stripe_customer.id,
          items: [{ price: price.id }],
          default_payment_method: payment_method.id,
          expand: ['latest_invoice.payment_intent']
        })

        # Create Subscription in DB
        @subscription = Subscription.new(user: current_user)
        @subscription.assign_attributes(
          plan_type: plan_type,
          status: stripe_subscription.status,
          stripe_customer_id: stripe_customer.id,
          stripe_subscription_id: stripe_subscription.id
        )

        if @subscription.save
          render json: {
            subscription: @subscription,
            client_secret: stripe_subscription.latest_invoice.payment_intent.client_secret
          }, status: :created
        else
          render json: { errors: @subscription.errors.full_messages }, status: :unprocessable_entity
        end
      rescue StandardError => e
        Rails.logger.error "Error creating subscription: #{e.message}"
        render json: { errors: ["Error creating subscription: #{e.message}"] }, status: :internal_server_error
      end

      # GET /api/v1/subscription
      def show
        render json: @subscription, status: :ok
      end

      # PATCH /api/v1/subscription
      def update
        if @subscription.update(subscription_params)
          render json: @subscription, status: :ok
        else
          render json: { errors: @subscription.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/subscription
      def destroy
        @subscription.destroy
        head :no_content
      end

      private

      def set_subscription
        @subscription = current_user.subscription
        unless @subscription
          render json: { error: "Subscription not found" }, status: :not_found
        end
      end

      def subscription_params
        permitted_params = params.require(:subscription).permit(:plan_type, :status)
        if permitted_params[:plan_type].present?
          plan_type_mapping = { "basic" => 0, "premium" => 1 }
          permitted_params[:plan_type] = plan_type_mapping[permitted_params[:plan_type]] if permitted_params[:plan_type].is_a?(String)
        end
        permitted_params
      end
    end
  end
end

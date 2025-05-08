module Api
  module V1
    class MoviesController < ApplicationController
      skip_before_action :verify_authenticity_token # Skip CSRF token for API
      before_action :authenticate_user!, only: [:create, :update, :destroy] # Require JWT for CRUD
      before_action :authorize_action!, only: [:create, :update, :destroy] # Role-based authorization
      before_action :check_subscription_access, only: [:show] # Check subscription for show action

      def index
        movies = Movie.api_search_filter_paginate(index_params)
        render json: {
          movies: movies.as_json(methods: [:banner_url, :poster_url]),
          total_pages: movies.total_pages,
          current_page: movies.current_page,
          per_page: movies.limit_value,
          total_count: movies.total_count
        }, status: :ok
      end

      def show
        movie = Movie.find(params[:id])
        render json: movie.as_json(methods: [:banner_url, :poster_url]), status: :ok
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Movie not found" }, status: :not_found
      end

      def create
        movie = Movie.new(movie_params)
        if movie.save
          send_new_movie_notification(movie)
          # Attach banner and poster only if files are present and not already attached
          if params[:movie][:banner].present? && !movie.banner.attached?
            movie.banner.attach(params[:movie][:banner])
          end
          if params[:movie][:poster].present? && !movie.poster.attached?
            movie.poster.attach(params[:movie][:poster])
          end
          render json: movie.as_json(methods: [:banner_url, :poster_url]), status: :created
        else
          render json: { errors: movie.errors.full_messages }, status: :unprocessable_entity
        end
      rescue StandardError => e
        render json: { errors: ["Failed to process images: #{e.message}"] }, status: :unprocessable_entity
      end

      def update
        movie = Movie.find(params[:id])
        if movie.update(movie_params)
          # Attach or update banner and poster if new files are provided
          if params[:movie][:banner].present? && (!movie.banner.attached? || params[:movie][:banner].original_filename != movie.banner.filename)
            movie.banner.attach(params[:movie][:banner])
          end
          if params[:movie][:poster].present? && (!movie.poster.attached? || params[:movie][:poster].original_filename != movie.poster.filename)
            movie.poster.attach(params[:movie][:poster])
          end
          render json: movie.as_json(methods: [:banner_url, :poster_url]), status: :ok
        else
          render json: { errors: movie.errors.full_messages }, status: :unprocessable_entity
        end
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Movie not found" }, status: :not_found
      rescue StandardError => e
        render json: { errors: ["Failed to process images: #{e.message}"] }, status: :unprocessable_entity
      end

      def destroy
        movie = Movie.find(params[:id])
        movie.destroy
        head :no_content
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Movie not found" }, status: :not_found
      end

      private

      def index_params
        params.permit(:query, :genre, :director, :main_lead, :release_year, :plan, :page, :per_page)
      end

      def movie_params
        params.require(:movie).permit(
          :title, :description, :genre, :director, :main_lead,
          :rating, :duration, :release_year, :plan,
          :banner, :poster
        )
      end

      def authorize_action!
        action = action_name.to_sym
        unless current_user && authorized_for_action?(action)
          render json: { error: "Unauthorized: Only supervisors can #{action} movies" }, status: :forbidden
        end
      end

      def authorized_for_action?(action)
        case action
        when :create, :update, :destroy
          current_user.role == "supervisor"
        else
          true # Allow read actions for all users
        end
      end

      def check_subscription_access
        # Unauthenticated users cannot access movie details
        unless current_user
          render json: { error: "Unauthorized: Please log in to access movie details" }, status: :unauthorized
          return
        end

        # Find the movie
        movie = Movie.find(params[:id])

        # Check if the user has a subscription
        subscription = current_user.subscription
        unless subscription
          render json: { error: "Please create a subscription to access movie details" }, status: :forbidden
          return
        end

        # Check if the subscription is active
        unless subscription.status == 'active'
          render json: { error: "Unauthorized: Your subscription is inactive" }, status: :forbidden
          return
        end

        # Access control based on subscription plan
        case subscription.plan_type
        when 'basic'
          unless movie.plan == 'free'
            render json: { error: "Unauthorized: Upgrade to premium to access this movie" }, status: :forbidden
          end
        when 'premium'
          true
        else
          render json: { error: "Unauthorized: Invalid subscription plan" }, status: :forbidden
        end
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Movie not found" }, status: :not_found
      end

      def send_new_movie_notification(movie)
        users = User.where(notifications_enabled: true).where.not(device_token: nil)
        return if users.empty?
        device_tokens = users.pluck(:device_token)
        begin
          fcm_service = FcmService.new
          response = fcm_service.send_notification(device_tokens, "New Movie Added!", "#{movie.title} has been added to the Movie Explorer collection.", { movie_id: movie.id.to_s })
          Rails.logger.info("FCM Response: #{response}")
          if response[:status_code] == 200
            Rails.logger.info("FCM Response: #{response}")
          else
            Rails.logger.error("FCM Error: #{response[:body]}")
          end
        rescue StandardError => e
          Rails.logger.error("FCM Notification Failed: #{e.message}")
        end
      end
    end
  end
end
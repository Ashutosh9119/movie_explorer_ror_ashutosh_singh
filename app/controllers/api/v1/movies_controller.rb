module Api
  module V1
    class MoviesController < ApplicationController
      skip_before_action :verify_authenticity_token
      before_action :authenticate_user!, only: [:create, :update, :destroy]
      before_action :authorize_action!, only: [:create, :update, :destroy]

      def index
        movies = Movie.api_search_filter_paginate(index_params)

        # If the user is authenticated, check their subscription status
        if current_user
          subscription = current_user.subscription
          unless subscription&.active?
            movies = movies.where(is_premium: false)
          end
        else
          # Unauthenticated users can only see non-premium movies
          movies = movies.where(is_premium: false)
        end

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

        # If the movie is premium, enforce subscription check
        if movie.is_premium
          unless current_user
            render json: { error: "Unauthorized: Please log in to access this movie" }, status: :unauthorized
            return
          end

          subscription = current_user.subscription
          unless subscription&.active?
            render json: { error: "Please purchase an active subscription to access this movie" }, status: :forbidden
            return
          end
        end

        render json: movie.as_json(methods: [:banner_url, :poster_url]), status: :ok
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Movie not found" }, status: :not_found
      end

      def create
        movie = Movie.new(movie_params)
        if movie.save
          send_new_movie_notification(movie)
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
        params.permit(:query, :genre, :director, :main_lead, :release_year, :is_premium, :page, :per_page)
      end

      def movie_params
        params.require(:movie).permit(
          :title, :description, :genre, :director, :main_lead,
          :rating, :duration, :release_year, :is_premium,
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
          true
        end
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
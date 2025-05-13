module Api
  module V1
    class MoviesController < ApplicationController
      skip_before_action :verify_authenticity_token
      before_action :authenticate_user!
      before_action :authorize_action!, only: [:create, :update, :destroy]

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
        if movie.is_premium
          subscription = current_user.subscription
          render json: { error: "Please purchase a subscription to access this premium movie" }, status: :forbidden unless subscription&.status == "active"
          render json: { error: "Please purchase a premium subscription to access this movie" }, status: :forbidden unless has_active_premium_subscription?(subscription)
        end
        render json: movie.as_json(methods: [:banner_url, :poster_url]), status: :ok
      end

      def create
        movie = Movie.new(movie_params)
        movie.save
        send_new_movie_notification(movie)
        if params[:movie][:banner].present? && !movie.banner.attached?
          movie.banner.attach(params[:movie][:banner])
        end
        if params[:movie][:poster].present? && !movie.poster.attached?
          movie.poster.attach(params[:movie][:poster])
        end
        render json: movie.as_json(methods: [:banner_url, :poster_url]), status: :created
      end

      def update
        movie = Movie.find(params[:id])
        movie.update(movie_params)
        if params[:movie][:banner].present? && (!movie.banner.attached? || params[:movie][:banner].original_filename != movie.banner.filename)
          movie.banner.attach(params[:movie][:banner])
        end
        if params[:movie][:poster].present? && (!movie.poster.attached? || params[:movie][:poster].original_filename != movie.poster.filename)
          movie.poster.attach(params[:movie][:poster])
        end
        render json: movie.as_json(methods: [:banner_url, :poster_url]), status: :ok
      end

      def destroy
        movie = Movie.find(params[:id])
        movie.destroy
        head :no_content
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
        render json: { error: "Unauthorized: Only supervisors can #{action} movies" }, status: :forbidden unless current_user && authorized_for_action?(action)
      end

      def authorized_for_action?(action)
        case action
        when :create, :update, :destroy
          current_user.role == "supervisor"
        else
          true
        end
      end

      def has_active_premium_subscription?(subscription)
        return false unless subscription.plan_type == "premium"
        return true if subscription.expires_at.nil?
        subscription.expires_at > Time.current
      end

      def send_new_movie_notification(movie)
        users = User.where(notifications_enabled: true).where.not(device_token: nil)
        return if users.empty?
        device_tokens = users.pluck(:device_token)
        fcm_service = FcmService.new
        fcm_service.send_notification(device_tokens, "New Movie Added!", "#{movie.title} has been added to the Movie Explorer collection.", { movie_id: movie.id.to_s })
      end
    end
  end
end
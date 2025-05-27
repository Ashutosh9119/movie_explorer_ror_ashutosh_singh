module Api
  module V1
    class UsersController < ApplicationController
      before_action :authenticate_user!
      # Skip CSRF protection for all actions in this API controller
      skip_before_action :verify_authenticity_token

      def current
        render json: { 
          id: current_user.id, 
          email: current_user.email, 
          role: current_user.role,
          name: current_user.name,
          profile_picture_url: current_user.profile_picture_url,
          profile_picture_thumbnail: current_user.profile_picture_thumbnail
        }, status: :ok
      end

      def update_profile_picture
        if user_params[:profile_picture].present?
          current_user.profile_picture.attach(user_params[:profile_picture])
          if current_user.profile_picture.attached?
            render json: { 
              message: "Profile picture updated successfully",
              id: current_user.id, 
              email: current_user.email, 
              role: current_user.role,
              name: current_user.name,
              profile_picture_url: current_user.profile_picture_url,
              profile_picture_thumbnail: current_user.profile_picture_thumbnail
            }, status: :ok
          else
            render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
          end
        else
          render json: { errors: ["No profile picture provided"] }, status: :bad_request
        end
      end

      def remove_profile_picture
        if current_user.profile_picture.attached?
          current_user.profile_picture.purge
          render json: { message: "Profile picture removed successfully" }, status: :ok
        else
          render json: { errors: ["No profile picture to remove"] }, status: :bad_request
        end
      end

      def update_device_token
        if current_user.update(device_token: device_token_params[:device_token])
          render json: { message: "Device token updated successfully" }, status: :ok
        else
          render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def toggle_notifications
        new_status = params[:notifications_enabled] == "true" || params[:notifications_enabled] == true
        if current_user.update(notifications_enabled: new_status)
          render json: { message: "Notification preference updated", notifications_enabled: current_user.notifications_enabled }, status: :ok
        else
          render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def device_token_params
        params.permit(:device_token)
      end

      def user_params
        params.require(:user).permit(:profile_picture)
      end
    end
  end
end
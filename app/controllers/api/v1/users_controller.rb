module Api
  module V1
    class UsersController < ApplicationController
      before_action :authenticate_user!
      # Skip CSRF protection for all actions in this API controller
      skip_before_action :verify_authenticity_token

      def current
        render json: { id: current_user.id, email: current_user.email, role: current_user.role }
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
    end
  end
end
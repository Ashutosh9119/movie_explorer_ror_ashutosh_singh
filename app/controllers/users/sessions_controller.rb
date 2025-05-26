# app/controllers/users/sessions_controller.rb
class Users::SessionsController < Devise::SessionsController
  respond_to :json
  skip_before_action :verify_authenticity_token
  skip_before_action :require_no_authentication, only: [:create]

  def create
    warden.logout if warden.authenticated?(:user)
    self.resource = warden.authenticate!(auth_options)
    sign_in(resource_name, resource)
    yield resource if block_given?
    respond_with(resource)
  end

  def destroy
    token = request.headers['Authorization']&.split(' ')&.last

    if token.present?
      begin
        payload = Warden::JWTAuth::TokenDecoder.new.call(token)
        user = User.find(payload['sub'])

        # Revoke the token by rotating JTI
        user.update(jti: SecureRandom.uuid)

        render json: { message: "Signed out successfully" }, status: :ok
      rescue JWT::ExpiredSignature
        render json: { error: "Token has expired" }, status: :unauthorized
      rescue JWT::DecodeError
        render json: { error: "Invalid token" }, status: :unauthorized
      rescue ActiveRecord::RecordNotFound
        render json: { error: "User not found" }, status: :not_found
      end
    else
      render json: { error: "No token provided" }, status: :unprocessable_entity
    end
  end

  private

  def respond_with(resource, _opts = {})
    if resource.persisted? && request.env['warden-jwt_auth.token'].present?
      render json: {
        id: resource.id,
        name: resource.name,
        email: resource.email,
        role: resource.role,
        token: request.env['warden-jwt_auth.token']
      }, status: :ok
    else
      render json: { error: "Invalid email or password" }, status: :unauthorized
    end
  end

  def respond_to_on_destroy
    head :no_content
  end
end

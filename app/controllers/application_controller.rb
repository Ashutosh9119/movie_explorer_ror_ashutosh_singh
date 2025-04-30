class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  # Make Devise helpers available
  before_action :authenticate_admin_user!, if: :admin_controller?

  private

  def admin_controller?
    self.class.module_parents.include?(ActiveAdmin::BaseController)
  end
end
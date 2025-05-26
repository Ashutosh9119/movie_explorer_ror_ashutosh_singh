class Movie < ApplicationRecord
  has_one_attached :banner
  has_one_attached :poster

  validates :title, :description, :genre, :director, :main_lead, presence: true
  validates :rating, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 10 }
  validates :duration, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :release_year, presence: true, numericality: { only_integer: true, greater_than: 1888, less_than_or_equal_to: Time.current.year }
  validates :banner, content_type: ['image/png', 'image/jpeg'], allow_blank: true
  validates :poster, content_type: ['image/png', 'image/jpeg'], allow_blank: true

  # after_create :send_new_movie_notification

  scope :by_genre, ->(genre) { where("genre ILIKE ?", genre) if genre.present? }
  scope :by_director, ->(director) { where(director: director) if director.present? }
  scope :by_main_lead, ->(main_lead) { where(main_lead: main_lead) if main_lead.present? }
  scope :by_release_year, ->(year) { where(release_year: year) if year.present? }
  scope :by_is_premium, ->(is_premium) { where(is_premium: is_premium) if is_premium.present? }
  scope :search_by_title, ->(query) { where("title ILIKE ?", "%#{query}%") if query.present? }
  scope :search_by_description, ->(query) { where("description ILIKE ?", "%#{query}%") if query.present? }
  scope :paginated, ->(page, per_page) { page(page || 1).per(per_page || 10) }

  def banner_url
    banner.url if banner.attached?
  end

  def poster_url
    poster.url if poster.attached?
  end

  # Role-based authorization methods
  def self.can_create?(current_user)
    current_user&.role == "supervisor"
  end

  def self.can_update?(current_user)
    current_user&.role == "supervisor"
  end

  def self.can_destroy?(current_user)
    current_user&.role == "supervisor"
  end

  def self.can_read?(current_user)
    true
  end

  # Custom search method combining title and description
  def self.search(query)
    return all unless query.present?
    search_by_title(query).or(search_by_description(query))
  end

  # Custom filter method combining all filters
  def self.apply_filters(params = {})
    movies = all
    movies = movies.by_genre(params[:genre])
    movies = movies.by_director(params[:director])
    movies = movies.by_main_lead(params[:main_lead])
    movies = movies.by_release_year(params[:release_year])
    movies = movies.by_is_premium(params[:is_premium])
    movies
  end

  # Combined method for API use: search, filter, and paginate
  def self.api_search_filter_paginate(params = {})
    movies = search(params[:query])
    movies = movies.apply_filters(params)
    page = (params[:page] || 1).to_i
    per_page = (params[:per_page] || 10).to_i
    paginated_movies = movies.paginated(page, per_page)
    paginated_movies
  end

  # Ransackable attributes for ActiveAdmin filters
  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "description", "director", "duration", "genre", "id", "main_lead", "is_premium", "rating", "release_year", "title", "updated_at"]
  end

  private

  def send_new_movie_notification
    users = User.where(notifications_enabled: true).where.not(device_token: nil)
    return if users.empty?
    device_tokens = users.pluck(:device_token)
    fcm_service = FcmService.new
    fcm_service.send_notification(device_tokens, "New Movie Added!", "#{title} has been added to the Movie Explorer collection.", { movie_id: id.to_s })
  end
end
ActiveAdmin.register Movie do
  permit_params :title, :description, :genre, :director, :main_lead, :rating, :duration, :release_year, :is_premium, :banner, :poster, :trailer

  controller do
    before_action :authorize_admin!, only: [:create, :update, :destroy]

    def authorize_admin!
      unless current_admin_user
        flash[:error] = "You must be logged in as an admin to perform this action"
        redirect_to admin_movies_path
        return
      end
    end

    def scoped_collection
      Movie.all
    end
  end

  index do
    selectable_column
    id_column
    column :title
    column :genre
    column :director
    column :main_lead
    column :rating
    column :duration
    column :release_year
    column :is_premium
    column :banner do |movie|
      if movie.banner.attached?
        image_tag movie.banner_url, size: "100x50"
      else
        "No Banner"
      end
    end
    column :poster do |movie|
      if movie.poster.attached?
        image_tag movie.poster_url, size: "50x75"
      else
        "No Poster"
      end
    end
    column :trailer do |movie|
      if movie.trailer.present?
        link_to movie.trailer, movie.trailer, target: "_blank", rel: "noopener noreferrer"
      else
        "No Trailer"
      end
    end
    column :created_at
    column :updated_at
    actions
  end

  filter :title
  filter :description
  filter :genre
  filter :director
  filter :main_lead
  filter :rating
  filter :duration
  filter :release_year
  filter :is_premium
  filter :trailer
  filter :created_at
  filter :updated_at

  form do |f|
    f.inputs do
      f.input :title
      f.input :description
      f.input :genre
      f.input :director
      f.input :main_lead
      f.input :rating
      f.input :duration
      f.input :release_year
      f.input :is_premium
      f.input :banner, as: :file, hint: f.object.banner.attached? ? image_tag(f.object.banner_url, size: "100x50") : nil
      f.input :poster, as: :file, hint: f.object.poster.attached? ? image_tag(f.object.poster_url, size: "50x75") : nil
      f.input :trailer
    end
    f.actions
  end

  show do
    attributes_table do
      row :id
      row :title
      row :description
      row :genre
      row :director
      row :main_lead
      row :rating
      row :duration
      row :release_year
      row :is_premium
      row :banner do |movie|
        if movie.banner.attached?
          image_tag movie.banner_url, size: "200x100"
        else
          "No Banner"
        end
      end
      row :poster do |movie|
        if movie.poster.attached?
          image_tag movie.poster_url, size: "100x150"
        else
          "No Poster"
        end
      end
      row :trailer do |movie|
        if movie.trailer.present?
          link_to movie.trailer, movie.trailer, target: "_blank", rel: "noopener noreferrer"
        else
          "No Trailer"
        end
      end
      row :created_at
      row :updated_at
    end
  end
end
class UpdateMoviesTable < ActiveRecord::Migration[7.1]
  def change
    # Rename columns with typos
    rename_column :movies, :tittle, :title
    rename_column :movies, :discription, :description

    # Set default value for plan
    change_column :movies, :plan, :integer, default: 0

    # Add Active Storage attachments (this will create the necessary tables if not already present)
    # Note: Active Storage tables are created separately via `rails active_storage:install`
  end
end
class AddDeviseColumnsToAdminUsers < ActiveRecord::Migration[7.1]
  def change
    # Skip adding email since it already exists
    unless column_exists?(:admin_users, :email)
      add_column :admin_users, :email, :string, null: false, default: ""
    end

    # Check if password column exists (ActiveAdmin might have created it)
    if column_exists?(:admin_users, :password)
      # Rename password to encrypted_password if it exists
      rename_column :admin_users, :password, :encrypted_password
    else
      # Add encrypted_password if neither password nor encrypted_password exists
      unless column_exists?(:admin_users, :encrypted_password)
        add_column :admin_users, :encrypted_password, :string, null: false, default: ""
      end
    end

    # Recoverable
    unless column_exists?(:admin_users, :reset_password_token)
      add_column :admin_users, :reset_password_token, :string
    end
    unless column_exists?(:admin_users, :reset_password_sent_at)
      add_column :admin_users, :reset_password_sent_at, :datetime
    end

    # Rememberable
    unless column_exists?(:admin_users, :remember_created_at)
      add_column :admin_users, :remember_created_at, :datetime
    end

    # Trackable
    unless column_exists?(:admin_users, :sign_in_count)
      add_column :admin_users, :sign_in_count, :integer, default: 0, null: false
    end
    unless column_exists?(:admin_users, :current_sign_in_at)
      add_column :admin_users, :current_sign_in_at, :datetime
    end
    unless column_exists?(:admin_users, :last_sign_in_at)
      add_column :admin_users, :last_sign_in_at, :datetime
    end
    unless column_exists?(:admin_users, :current_sign_in_ip)
      add_column :admin_users, :current_sign_in_ip, :string
    end
    unless column_exists?(:admin_users, :last_sign_in_ip)
      add_column :admin_users, :last_sign_in_ip, :string
    end

    # Add indexes
    unless index_exists?(:admin_users, :email)
      add_index :admin_users, :email, unique: true
    end
    unless index_exists?(:admin_users, :reset_password_token)
      add_index :admin_users, :reset_password_token, unique: true
    end
  end
end
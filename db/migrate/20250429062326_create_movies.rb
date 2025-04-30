class CreateMovies < ActiveRecord::Migration[7.1]
  def change
    create_table :movies do |t|
      t.string :tittle
      t.string :discription
      t.string :genre
      t.string :director
      t.string :main_lead
      t.float :rating
      t.integer :duration
      t.integer :release_year
      t.integer :plan
      t.timestamps
    end
  end
end

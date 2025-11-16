class CreateReviewHelpfuls < ActiveRecord::Migration[8.1]
  def change
    create_table :review_helpfuls do |t|
      t.references :review, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    # Unique constraint: one helpful vote per user per review
    add_index :review_helpfuls, [:review_id, :user_id], unique: true
  end
end

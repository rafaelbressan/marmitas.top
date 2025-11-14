class ReviewHelpful < ApplicationRecord
  # Associations
  belongs_to :review
  belongs_to :user

  # Validations
  validates :user_id, uniqueness: { scope: :review_id, message: "Você já marcou esta avaliação como útil" }
  validate :cannot_mark_own_review_as_helpful

  private

  def cannot_mark_own_review_as_helpful
    if review && user && review.user_id == user.id
      errors.add(:base, "Você não pode marcar sua própria avaliação como útil")
    end
  end
end

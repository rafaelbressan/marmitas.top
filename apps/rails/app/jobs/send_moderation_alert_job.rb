class SendModerationAlertJob < ApplicationJob
  queue_as :default

  def perform(review_id)
    review = Review.find_by(id: review_id)
    return unless review

    # Log the flagged review for now
    # In production, this could send email/Slack notification to admins
    Rails.logger.info "🚩 Review flagged for moderation: Review ##{review.id} - #{review.flag_reason}"

    # TODO: Send email to admins
    # TODO: Send Slack notification
    # TODO: Create in-app notification for admin users
  end
end

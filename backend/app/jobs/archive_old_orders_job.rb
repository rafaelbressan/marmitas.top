class ArchiveOldOrdersJob < ApplicationJob
  queue_as :default

  # Archive orders older than 3 months (90 days)
  ARCHIVE_THRESHOLD = 90.days

  def perform
    cutoff_date = ARCHIVE_THRESHOLD.ago

    archived_count = Order.where('created_at < ?', cutoff_date)
                          .where(archived_at: nil)
                          .update_all(archived_at: Time.current)

    Rails.logger.info "📦 Archived #{archived_count} orders older than #{ARCHIVE_THRESHOLD.inspect}" if archived_count > 0
  end
end

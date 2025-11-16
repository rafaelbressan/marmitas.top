class Api::V1::Admin::ReviewsController < Api::V1::BaseController
  before_action :authenticate_user!
  before_action :require_admin!
  before_action :set_review, only: [:show, :approve, :remove]

  # GET /api/v1/admin/reviews
  def index
    @reviews = Review.includes(:user, :seller_profile)

    # Filter by moderation status
    case params[:status]
    when 'flagged'
      @reviews = @reviews.flagged_reviews
    when 'under_review'
      @reviews = @reviews.under_review
    when 'removed'
      @reviews = @reviews.removed
    else
      @reviews = @reviews.where(moderation_status: ['under_review', 'removed'])
                         .or(Review.where(flagged: true))
    end

    @reviews = @reviews.order(created_at: :desc)

    # Paginate
    page = params[:page] || 1
    per_page = params[:per_page] || 20
    @reviews = @reviews.page(page).per(per_page)

    render json: {
      reviews: @reviews.map { |review| admin_review_response(review) },
      stats: moderation_stats,
      pagination: pagination_meta(@reviews)
    }
  end

  # GET /api/v1/admin/reviews/:id
  def show
    # Get user's review history
    user_reviews = @review.user.reviews.order(created_at: :desc).limit(10)

    # Detect patterns
    recent_one_star = @review.user.reviews.where('created_at > ?', 7.days.ago).where(rating: 1).count
    recent_review_count = @review.user.reviews.where('created_at > ?', 7.days.ago).count

    patterns = []
    patterns << "Padrão suspeito: #{recent_one_star} avaliações 1-estrela nos últimos 7 dias" if recent_one_star >= 3
    patterns << "Padrão suspeito: #{recent_review_count} avaliações nos últimos 7 dias" if recent_review_count >= 10

    render json: {
      review: admin_review_response(@review, detailed: true),
      user_history: user_reviews.map { |r| review_history_item(r) },
      suspicious_patterns: patterns,
      seller_context: {
        id: @review.seller_profile.id,
        business_name: @review.seller_profile.business_name,
        average_rating: @review.seller_profile.average_rating,
        total_reviews: @review.seller_profile.reviews_count
      }
    }
  end

  # POST /api/v1/admin/reviews/:id/approve
  def approve
    note = params[:note].to_s.strip

    @review.approve!(current_user, note)

    render json: {
      message: 'Avaliação aprovada com sucesso',
      review: admin_review_response(@review)
    }
  end

  # POST /api/v1/admin/reviews/:id/remove
  def remove
    note = params[:note].to_s.strip

    if note.blank?
      return render json: { error: 'Nota é obrigatória ao remover avaliação' }, status: :unprocessable_entity
    end

    @review.remove!(current_user, note)

    render json: {
      message: 'Avaliação removida com sucesso',
      review: admin_review_response(@review)
    }
  end

  private

  def set_review
    @review = Review.find(params[:id])
  end

  def require_admin!
    unless current_user&.admin?
      render json: { error: 'Acesso não autorizado' }, status: :forbidden
    end
  end

  def moderation_stats
    {
      flagged_count: Review.flagged_reviews.count,
      under_review_count: Review.under_review.count,
      removed_count: Review.removed.count,
      total_pending: Review.where(moderation_status: ['under_review']).or(Review.where(flagged: true)).count
    }
  end

  def admin_review_response(review, detailed: false)
    response = {
      id: review.id,
      rating: review.rating,
      comment: review.comment,
      encounter_date: review.encounter_date,
      verified_encounter: review.verified_encounter,
      flagged: review.flagged,
      flag_reason: review.flag_reason,
      moderation_status: review.moderation_status,
      moderation_note: review.moderation_note,
      moderated_at: review.moderated_at,
      helpful_count: review.helpful_count,
      edit_count: review.edit_count,
      created_at: review.created_at,
      last_edited_at: review.last_edited_at,
      user: {
        id: review.user.id,
        name: review.user.name,
        email: review.user.email,
        total_reviews: review.user.reviews.count
      },
      seller: {
        id: review.seller_profile.id,
        business_name: review.seller_profile.business_name
      }
    }

    if detailed && review.moderated_by
      response[:moderated_by] = {
        id: review.moderated_by.id,
        name: review.moderated_by.name
      }
    end

    response
  end

  def review_history_item(review)
    {
      id: review.id,
      rating: review.rating,
      comment: review.comment&.truncate(100),
      seller: review.seller_profile.business_name,
      created_at: review.created_at,
      moderation_status: review.moderation_status
    }
  end

  def pagination_meta(collection)
    {
      current_page: collection.current_page,
      total_pages: collection.total_pages,
      total_count: collection.total_count,
      per_page: collection.limit_value
    }
  end
end

class Api::V1::ReviewsController < Api::V1::BaseController
  # `before_action :authenticate_user!, except: [...]` estava aqui embaixo e
  # substituia o callback incondicional do BaseController, jogando a
  # autenticacao para DEPOIS do `set_seller_profile`/`set_review`. Um POST sem
  # token com id inexistente respondia 404 em vez de 401. Com `skip_before_action`
  # a autenticacao volta a ser a primeira coisa que roda.
  skip_before_action :authenticate_user!, only: [:index, :show]
  before_action :set_seller_profile, only: [:index, :create]
  before_action :set_review, only: [:show, :update, :destroy, :flag, :helpful]

  # GET /api/v1/sellers/:seller_profile_id/reviews
  def index
    authorize Review, :index?

    @reviews = @seller_profile.reviews
                              .published
                              .includes(:user)
                              .order(created_at: :desc)

    # Apply filters
    @reviews = @reviews.by_rating(params[:rating]) if params[:rating].present?
    @reviews = @reviews.verified if params[:verified_only] == 'true'
    @reviews = @reviews.with_comments if params[:with_comments] == 'true'

    # Apply sorting
    case params[:sort]
    when 'helpful'
      @reviews = @reviews.order(helpful_count: :desc)
    when 'rating'
      @reviews = @reviews.order(rating: :desc)
    else
      @reviews = @reviews.order(created_at: :desc)
    end

    # Paginate
    page = params[:page] || 1
    per_page = params[:per_page] || 10
    @reviews = @reviews.page(page).per(per_page)

    # Calculate rating summary
    rating_summary = {
      average_rating: @seller_profile.average_rating,
      total_reviews: @seller_profile.reviews_count,
      rating_distribution: @seller_profile.rating_distribution,
      display_rating: @seller_profile.display_rating?,
      rating_trend: @seller_profile.rating_trend
    }

    render json: {
      reviews: @reviews.map { |review| review_response(review) },
      rating_summary: rating_summary,
      pagination: pagination_meta(@reviews)
    }
  end

  # GET /api/v1/reviews/:id
  def show
    authorize @review, :show?

    # As tres permissoes vem da policy, nao de uma copia da regra aqui. Antes
    # chamavam `@review.editable_by?(current_user)` direto, e como esta acao e
    # publica, um GET sem token estourava NoMethodError em `nil.id` (500).
    render json: {
      review: review_response(@review, detailed: true),
      permissions: {
        can_edit: policy(@review).update?,
        can_flag: policy(@review).flag?,
        can_mark_helpful: policy(@review).helpful?
      }
    }
  end

  # POST /api/v1/sellers/:seller_profile_id/reviews
  def create
    authorize Review, :create?

    @review = @seller_profile.reviews.new(review_params)
    @review.user = current_user

    if @review.save
      render json: {
        message: 'Avaliação criada com sucesso',
        review: review_response(@review)
      }, status: :created
    else
      render json: { errors: @review.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH /api/v1/reviews/:id
  def update
    authorize @review, :update?

    if @review.update(review_update_params)
      @review.increment!(:edit_count)
      @review.update_column(:last_edited_at, Time.current)

      render json: {
        message: 'Avaliação atualizada com sucesso',
        review: review_response(@review)
      }
    else
      render json: { errors: @review.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/reviews/:id
  def destroy
    authorize @review, :destroy?

    @review.destroy
    render json: { message: 'Avaliação removida com sucesso' }
  end

  # POST /api/v1/reviews/:id/flag
  def flag
    authorize @review, :flag?

    flag_reason = params[:reason].to_s.strip

    if flag_reason.blank?
      return render json: { error: 'Motivo da denúncia é obrigatório' }, status: :unprocessable_entity
    end

    if @review.flag!(flag_reason, current_user)
      render json: { message: 'Avaliação denunciada com sucesso. Nossa equipe irá analisá-la.' }
    else
      render json: { error: 'Não foi possível denunciar esta avaliação' }, status: :unprocessable_entity
    end
  end

  # POST /api/v1/reviews/:id/helpful
  def helpful
    authorize @review, :helpful?

    is_helpful = @review.toggle_helpful(current_user)

    render json: {
      message: is_helpful ? 'Marcado como útil' : 'Desmarcado como útil',
      helpful_count: @review.helpful_count,
      is_helpful: is_helpful
    }
  end

  private

  def set_seller_profile
    @seller_profile = SellerProfile.find(params[:seller_id] || params[:seller_profile_id])
  end

  def set_review
    @review = Review.find(params[:id])
  end

  def review_params
    params.require(:review).permit(
      :rating,
      :comment,
      :weekly_menu_id,
      :encounter_latitude,
      :encounter_longitude,
      :encounter_timestamp
    )
  end

  def review_update_params
    params.require(:review).permit(:rating, :comment)
  end

  def review_response(review, detailed: false)
    response = {
      id: review.id,
      rating: review.rating,
      comment: review.comment,
      encounter_date: review.encounter_date,
      verified_encounter: review.verified_encounter,
      helpful_count: review.helpful_count,
      edit_count: review.edit_count,
      created_at: review.created_at,
      last_edited_at: review.last_edited_at,
      user: {
        id: review.user.id,
        name: review.user.name
      }
    }

    if detailed
      response.merge!({
        dish_name: review.display_dish_name,
        weekly_menu_id: review.weekly_menu_id,
        is_helpful_by_current_user: current_user ? review.helpful_by?(current_user) : false
      })
    end

    response
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

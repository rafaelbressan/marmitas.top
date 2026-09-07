class ApplicationController < ActionController::API
  include Pundit::Authorization

  # Skip session storage for API
  before_action :configure_permitted_parameters, if: :devise_controller?

  # Nenhuma acao escapa da matriz de acesso: esquecer o `authorize` quebra a
  # requisicao em vez de liberar o dado. As unicas dispensas sao explicitas, com
  # `skip_after_action :verify_authorized`, e cada uma tem o motivo escrito ao
  # lado.
  after_action :verify_authorized

  rescue_from Pundit::NotAuthorizedError, with: :deny_access

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name, :phone ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name, :phone ])
  end

  private

  # Negacao dentro do proprio recurso e 403. Id de outro marmiteiro continua
  # respondendo 404, e esse 404 nasce da propria busca nos controllers de
  # `api/v1/seller/*` (`current_user.seller_profile.dishes.find`), nao daqui:
  # um 403 ali confirmaria que o prato do concorrente existe.
  def deny_access
    render json: { error: "Acesso nao autorizado" }, status: :forbidden
  end
end

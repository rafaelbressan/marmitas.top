# Base das policies do Pundit. O "usuario" aqui e o `current_user` do
# devise-jwt, e ele pode ser `nil`: metade da API e publica (mapa, cardapios,
# avaliacoes), entao "anonimo" e um papel de verdade na matriz, nao um erro.
#
# Uma acao que a matriz nao liberou nao e de ninguem: todo predicado nasce
# `false`. Policy que esquece de responder nega em vez de virar um "sim"
# silencioso.
class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index? = false
  def show? = false
  def create? = false
  def new? = create?
  def update? = false
  def edit? = update?
  def destroy? = false

  private
    def signed_in? = user.present?

    def admin? = signed_in? && user.admin?

    def seller_profile = user&.seller_profile

    def seller? = seller_profile.present?

    # Segunda linha de defesa da separacao entre marmiteiros. Os controllers de
    # `api/v1/seller/*` ja buscam pela associacao do dono
    # (`current_user.seller_profile.dishes.find`), o que devolve 404 para o id
    # alheio. Se um dia essa busca escapar para `Dish.find`, a policy continua
    # negando: prato, cardapio e ponto de venda respondem `seller_profile`, e o
    # perfil responde por si mesmo.
    #
    # Registro que nao sabe dizer de quem e nao passa — a parede fecha por falta
    # de resposta, nao por falta de checagem.
    def owns_record?
      return false unless seller?
      return false if record.is_a?(Class) || record.is_a?(Symbol)

      owner = record.is_a?(SellerProfile) ? record : (record.seller_profile if record.respond_to?(:seller_profile))
      owner.present? && owner.id == seller_profile.id
    end

    # Dono no sentido de autoria pessoal: avaliacao, favorito, token de
    # aparelho. Nada a ver com `owns_record?`, que fala do perfil de marmiteiro.
    def authored_record?
      return false unless signed_in?
      return false unless record.respond_to?(:user_id)

      record.user_id == user.id
    end
end

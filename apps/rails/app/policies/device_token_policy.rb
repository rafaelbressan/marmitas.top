# Token de aparelho e a chave que entrega push para o celular da pessoa. Listar,
# registrar e desativar valem para a propria conta; apagar, so o proprio token.
class DeviceTokenPolicy < ApplicationPolicy
  def index? = signed_in?
  def create? = signed_in?
  def deactivate_all? = signed_in?

  def destroy? = authored_record?
end

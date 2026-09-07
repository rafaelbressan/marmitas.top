# `auth/me` e `auth/logout` falam da propria sessao. `register` e `login`
# acontecem antes de existir usuario e por isso saem do `verify_authorized` no
# proprio controller — nao ha sujeito para autorizar.
class UserPolicy < ApplicationPolicy
  def me? = authored_session?
  def logout? = authored_session?

  private
    def authored_session? = signed_in? && record.is_a?(User) && record.id == user.id
end

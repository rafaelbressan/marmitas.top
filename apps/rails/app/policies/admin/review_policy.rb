# Moderacao de avaliacao. A resposta e a mesma para as quatro acoes, e e essa
# repeticao que a matriz de teste tem que cobrir: hoje a unica barreira e o
# `require_admin!` no controller, e basta esquecer um `before_action` para o
# painel de moderacao ficar aberto.
#
# `is_admin` nao e gravavel por endpoint nenhum: `auth#register` permite
# apenas email, senha, nome e telefone, e nao existe rota que atualize usuario.
module Admin
  class ReviewPolicy < ApplicationPolicy
    def index? = admin?
    def show? = admin?
    def approve? = admin?
    def remove? = admin?
  end
end

# A matriz de acesso da BRES-103 e uma tabela de cinco colunas, e e assim que
# ela vira teste: cada caso pergunta a mesma permissao aos cinco papeis de uma
# vez e compara o hash inteiro. Uma permissao que vazou para o papel errado
# aparece como diff de hash, nao como um assert solitario que ninguem escreveu.
#
#   assert_matrix Seller::DishPolicy, :update?, dishes(:feijoada),
#     anonimo: false, consumidor: false, vendedor_dono: true,
#     vendedor_outro: false, admin: false
#
# Os cinco papeis sao os do enunciado. `anonimo` e `nil` de proposito: metade da
# API responde sem token, entao "sem usuario" e uma coluna da tabela, nao um
# caso de erro.
module PermissionMatrix
  ROLES = {
    anonimo: nil,
    consumidor: :carla,
    vendedor_dono: :marli,
    vendedor_outro: :jorge,
    admin: :admin
  }.freeze

  def user_for(role)
    fixture = ROLES.fetch(role)
    fixture && users(fixture)
  end

  def assert_matrix(policy, action, record, **expected)
    assert_equal ROLES.keys.sort, expected.keys.sort,
      "a matriz tem os cinco papeis do enunciado; declare os cinco"

    actual = ROLES.keys.index_with do |role|
      policy.new(user_for(role), record).public_send(action)
    end

    assert_equal expected, actual
  end
end

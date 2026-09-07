class AddKindToSellingLocations < ActiveRecord::Migration[8.1]
  def change
    # Duas maneiras de dizer "estou aberto": um ponto fixo, cujo pino nao anda,
    # e a linha "circulando" do ambulante, regravada durante o turno. As duas
    # moram em selling_locations para que ST_DWithin, o mapa e o par
    # arrive/leave continuem sem tocar em nada.
    add_column :selling_locations, :kind, :string, null: false, default: "ponto"

    # Idade da posicao. Fica nulo no ponto fixo, que nunca se move.
    add_column :selling_locations, :position_updated_at, :datetime

    add_check_constraint :selling_locations,
                         "kind IN ('ponto', 'circulando')",
                         name: "selling_locations_kind_check"

    # Uma unica linha "circulando" por marmiteiro.
    add_index :selling_locations,
              :seller_profile_id,
              unique: true,
              where: "kind = 'circulando'",
              name: "index_selling_locations_on_one_roaming_per_seller"
  end
end

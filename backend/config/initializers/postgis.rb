# `spatial_ref_sys` e uma tabela de verdade, criada e populada pela extensao
# PostGIS com ~8500 sistemas de coordenadas — entre eles o SRID 4326, que e o
# que `selling_locations.lonlat` usa.
#
# Quando o Rails reaproveita um banco de teste que ja existe (os paralelos do
# `parallelize`, em toda execucao depois da primeira), ele nao recria o banco:
# chama `truncate_tables(*conn.tables)`, que esvazia TODAS as tabelas. O adapter
# `postgresql` puro nao sabe que `spatial_ref_sys` e da extensao e a esvazia
# junto. A partir dai qualquer `ST_SetSRID(..., 4326)` morre com
# "Cannot find SRID (4326) in spatial_ref_sys".
#
# Sintoma tipico: a primeira rodada passa, a segunda quebra. O
# `activerecord-postgis-adapter` faz exatamente esta exclusao; como aqui o
# adapter e o `postgresql` puro, ela vai a mao.
module PostgisTruncationGuard
  PROTECTED_TABLES = %w[ spatial_ref_sys ].freeze

  def truncate_tables(*table_names)
    super(*(table_names - PROTECTED_TABLES))
  end
end

ActiveSupport.on_load(:active_record_postgresqladapter) do
  prepend PostgisTruncationGuard
end

# Marmitas.top — `apps/rails` (guia de desenvolvimento)

API Rails 8.1 em modo `--api`, PostgreSQL 16 com PostGIS.

## Pré-requisitos

| O quê | Versão | Por quê |
|---|---|---|
| Ruby | 3.3.6 (`.ruby-version`) | roda a aplicação |
| Docker + Docker Compose | qualquer versão atual | sobe o Postgres com PostGIS |
| `psql` e `pg_dump` | **16** | o schema é versionado como `db/structure.sql` |

O cliente do PostgreSQL precisa ser da **mesma versão maior do servidor (16)**.
`bin/rails db:prepare` carrega o `db/structure.sql` com `psql`, e `bin/rails
db:migrate` regrava o arquivo com `pg_dump`. Um `pg_dump` mais antigo que o
servidor recusa a conexão.

```bash
# Debian/Ubuntu
sudo apt install postgresql-client-16
# macOS
brew install libpq && brew link --force libpq
```

## Do clone ao servidor rodando

```bash
git clone https://github.com/rafaelbressan/marmitas.top.git
cd marmitas.top

# 1. Banco de dados (Postgres 16 + PostGIS 3.4), na raiz do repositório
docker compose -f docker-compose.dev.yml up -d

# 2. Variáveis de ambiente
cd apps/rails
cp .env.example .env
openssl rand -hex 64            # cole o resultado em DEVISE_JWT_SECRET_KEY no .env

# 3. Dependências
bundle install

# 4. Banco: cria, carrega db/structure.sql e roda db/seeds.rb
bin/rails db:prepare

# 5. Sobe
bin/rails server
```

A API responde em `http://localhost:3000`. Health check: `GET /up`.

Confira que o ponto de venda existe (é o que quebrava antes):

```bash
bin/rails runner 'puts SellingLocation.count'
curl "http://localhost:3000/api/v1/sellers/nearby?latitude=-22.9295&longitude=-43.1774&radius=5"
```

### Portas

O container escuta em `127.0.0.1:5435`, seguindo o padrão da casa: a 5432 é do
`gbrain`, a 5433 do `benevoles` e a 5434 do `egerian`. Para usar outra:

```bash
POSTGRES_PORT=5555 docker compose -f docker-compose.dev.yml up -d
# e no apps/rails/.env
DATABASE_PORT=5555
```

## Variáveis de ambiente

Todas estão em `.env.example`, comentadas. `apps/rails/.env` é ignorado pelo git.

`DEVISE_JWT_SECRET_KEY` é obrigatória e **não tem valor padrão**: sem ela a
aplicação levanta erro na inicialização, em qualquer ambiente. Isso é
intencional — uma chave de assinatura de JWT com fallback nulo emitiria tokens
que qualquer um forja.

## Dados de exemplo

`bin/rails db:seed` é idempotente e cria 4 marmiteiros com perfil, pratos,
cardápio da semana disponível agora e pontos de venda com coordenadas reais no
Rio de Janeiro e em São Paulo. Dois deles estão anunciando presença
(`currently_active`), então `SellerProfile.nearby` devolve resultado sem nenhum
passo extra.

Senha de todos os usuários semeados: `senha123`.

| E-mail | Papel |
|---|---|
| `admin@marmitas.top` | administradora |
| `cliente@marmitas.top` | consumidor |
| `dona.marli@marmitas.top` | marmiteira, RJ, anunciando agora |
| `seu.jorge@marmitas.top` | marmiteiro, RJ |
| `ana.vegana@marmitas.top` | marmiteira, SP, anunciando agora |
| `chef.tadeu@marmitas.top` | marmiteiro, SP |

## Testes

```bash
bin/rails test
```

Minitest + fixtures, no padrão do `egerian` e do `benevoles`: `test/test_helper.rb`
com `parallelize(workers: :number_of_processors)` e `fixtures :all`. Não há RSpec,
FactoryBot nem shoulda-matchers no projeto.

As fixtures de `test/fixtures/` descrevem três marmiteiros coerentes entre si —
Dona Marli anunciando no Largo do Machado (RJ), Seu Jorge parado a 600 m dali, e
a Verdinha anunciando em Pinheiros (SP) — com pratos, cardápio, avaliações,
favoritos e tokens de dispositivo.

### `selling_locations` em fixture

Fixture entra direto no banco, sem passar pelos callbacks do modelo. O
`before_save :update_lonlat_from_coordinates` de `SellingLocation` não roda, e
`latitude`/`longitude` sozinhas deixam `lonlat` nulo — aí todo `ST_DWithin` some.

A solução é escrever o EWKT à mão no YAML, **longitude primeiro**:

```yaml
largo_do_machado:
  latitude: -22.929500
  longitude: -43.177400
  lonlat: "SRID=4326;POINT(-43.1774 -22.9295)"
```

### `parallelize` com PostGIS

Duas coisas separadas, ambas resolvidas.

**1. A extensão nos bancos paralelos.** Cada worker ganha o próprio banco
(`marmitas_top_test_0`, `_1`, ...), criado a partir do `db/structure.sql`. Como o
schema é versionado em SQL, o dump começa com
`CREATE EXTENSION IF NOT EXISTS postgis` e cada banco paralelo nasce com a
extensão, a coluna `geography` e o índice GiST. Com o `db/schema.rb` antigo eles
sairiam sem nem a tabela `selling_locations`.

**2. O truncate que apaga os SRIDs.** Esta é a que morde de verdade, e só na
segunda execução. Quando o banco paralelo já existe e o schema está em dia, o
Rails não o recria: chama `truncate_tables(*conn.tables)`. `spatial_ref_sys` é
uma tabela de verdade, criada e populada pela extensão com ~8500 sistemas de
coordenadas, e o adapter `postgresql` puro não sabe que ela é da extensão — leva
junto. A partir daí todo `ST_SetSRID(..., 4326)` morre com
`Cannot find SRID (4326) in spatial_ref_sys`.

O sintoma é traiçoeiro: **a primeira rodada passa e a segunda quebra.** Numa
máquina limpa e no CI, que sempre começam do zero, ele fica escondido.

`config/initializers/postgis.rb` exclui `spatial_ref_sys` do truncate — é a mesma
exclusão que o `activerecord-postgis-adapter` faz nativamente. O teste
`test/database_schema_test.rb` guarda o comportamento.

Para exercitar os bancos paralelos de propósito, **rodando duas vezes**:

```bash
PARALLEL_WORKERS=4 bin/rails test
PARALLEL_WORKERS=4 bin/rails test   # a segunda é a que pega o bug do truncate
```

## Banco de dados

O schema é versionado como **`db/structure.sql`**, não `db/schema.rb`
(`config.active_record.schema_format = :sql` em `config/application.rb`).

O dumper Ruby não sabe representar a coluna `geography` de `selling_locations` e
descartava a tabela inteira do dump — qualquer banco criado com `db:prepare` ou
`db:schema:load` saía sem a tabela central do produto. O `structure.sql` é um
`pg_dump` puro e mantém a extensão PostGIS, a coluna `geography` e o índice GiST.

Consequência prática no dia a dia: depois de `bin/rails db:migrate`, é o
`db/structure.sql` que aparece no `git status`. Faça commit dele junto com a
migration.

| Ambiente | Banco |
|---|---|
| development | `marmitas_top_development` |
| test | `marmitas_top_test` |

Comandos úteis:

```bash
bin/rails db:prepare        # cria e carrega o structure.sql
bin/rails db:migrate        # aplica migrations e regrava o structure.sql
bin/rails db:drop db:prepare           # do zero
docker compose -f docker-compose.dev.yml down -v   # apaga o volume também
```

## Nada e apagado

Deletar no produto e **descartar** (`gem "discard"`, coluna `discarded_at`),
igual ao `egerian`. `SellerProfile`, `Dish`, `WeeklyMenu`, `SellingLocation` e
`Review` sao descartaveis; `Favorite`, `DeviceToken` e `ReviewHelpful` continuam
com delete de verdade, porque a propria pessoa refaz com um toque.

Regras que valem em todo codigo novo (BRES-140):

- Controller nunca chama `destroy` num modelo descartavel — chama `discard`.
- Toda consulta que mostra o registro passa por `kept`.
- Descartar um marmiteiro desce para os pratos, cardapios, pontos de venda e
  avaliacoes dele; `undiscard` devolve exatamente o que caiu nessa cascata.
- `weekly_menu_dishes` fica **fora** da cascata: e o registro de quanto foi
  anunciado e quanto sobrou naquele dia.

```bash
bin/rails test test/models/discard_cascade_test.rb
bin/rails test test/integration/api/v1/discard_test.rb
```

## Trabalhos em segundo plano (Solid Queue)

As tabelas do Solid Queue ficam no **banco principal**, criadas por migration
(`db/migrate/20260907220100_create_solid_queue_tables.rb`), não num banco
separado com `db/queue_schema.rb` como o `solid_queue:install` gera. O motivo é o
mesmo `schema_format = :sql` da seção anterior: o carregador multi-banco do Rails
não sabe ler um `queue_schema.rb` quando o formato é SQL.

Em produção o adaptador é o `solid_queue` e o worker sobe com:

```bash
bin/jobs
```

Os trabalhos recorrentes estão em `config/recurring.yml`:

| Trabalho | Quando | O que faz |
|---|---|---|
| `shut_off_expired_broadcasts` | a cada 5 min | desliga o anúncio de quem passou do `leaving_at` |

O anúncio vencido tem **duas** proteções, de propósito. O job desliga, e o escopo
`SellerProfile.broadcasting` filtra por validade em toda consulta de leitura
(`nearby`, `map/sellers`, `map/bounds`, `sellers?active_only=true`). Se o worker
estiver parado ou atrasado, o mapa continua sem mentir.

## CORS

Configurado em `config/initializers/cors.rb` para `localhost:3000`,
`localhost:8081` e URLs `exp://` do Expo. Não há origem de produção definida.

## Referências

- `PROJECT_SPECIFICATION_V2.md` — especificação do produto
- `rating.md` — especificação das avaliações
- `ANALYSIS.md` — retrato técnico do repositório

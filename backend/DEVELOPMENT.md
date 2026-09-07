# Marmitas.top — backend (guia de desenvolvimento)

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
docker compose up -d

# 2. Variáveis de ambiente
cd backend
cp .env.example .env
openssl rand -hex 64            # cole o resultado em DEVISE_JWT_SECRET_KEY no .env

# 3. Dependências
bundle install

# 4. Banco: cria, carrega db/structure.sql e popula
bin/rails db:prepare db:seed

# 5. Sobe
bin/rails server
```

A API responde em `http://localhost:3000`. Health check: `GET /up`.

Confira que o ponto de venda existe (é o que quebrava antes):

```bash
bin/rails runner 'puts SellingLocation.count'
curl "http://localhost:3000/api/v1/sellers/nearby?latitude=-22.9295&longitude=-43.1774&radius=5"
```

### Se a porta 5432 já estiver ocupada

Escolha outra na subida do container e aponte o app para ela:

```bash
POSTGRES_PORT=5442 docker compose up -d
# e no backend/.env
DATABASE_PORT=5442
```

## Variáveis de ambiente

Todas estão em `.env.example`, comentadas. `backend/.env` é ignorado pelo git.

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
bundle exec rspec
```

RSpec + FactoryBot + shoulda-matchers já estão configurados
(`spec/rails_helper.rb`, `spec/support/`). `create(:user)` funciona sem prefixo.

Hoje existem apenas os guardas de ambiente (`spec/database_schema_spec.rb`,
`spec/factories_spec.rb`) e 3 stubs pendentes do gerador. Testes de regra de
negócio são outra issue.

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
bin/rails db:drop db:prepare db:seed   # do zero
docker compose down -v      # apaga o volume do Postgres também
```

## CORS

Configurado em `config/initializers/cors.rb` para `localhost:3000`,
`localhost:8081` e URLs `exp://` do Expo. Não há origem de produção definida.

## Referências

- `PROJECT_SPECIFICATION_V2.md` — especificação do produto
- `rating.md` — especificação das avaliações
- `ANALYSIS.md` — retrato técnico do repositório

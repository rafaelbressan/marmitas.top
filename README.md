# marmitas.top

Plataforma de descoberta de marmitas e quentinhas. O **marmiteiro** cadastra o
cardápio da semana e anuncia onde está vendendo hoje; o **consumidor** encontra
quem está perto, segue os favoritos e é avisado quando eles chegam ao ponto.

Especificação do produto: `PROJECT_SPECIFICATION_V2.md`. Avaliações: `rating.md`.
Arquitetura: `RAILS_ARCHITECTURE.md` e `EXPO_ARCHITECTURE.md`.

## Estrutura

```
apps/
  rails/     # Rails 8.1 — API do app (api/v1) e, a partir da etapa 2, o site publico
  mobile/    # Expo 54 / React Native — app iOS, Android e web
docs/
  historico/ # documentos que descrevem estados anteriores do projeto
docker-compose.dev.yml   # Postgres 16 + PostGIS para desenvolvimento
```

O site estático de 2019 (Hyperion + Nunjucks + Stylus + Gulp) saiu da `master` e
está preservado na tag **`v1-static-site`**:

```bash
git checkout v1-static-site
```

Não há `package.json` na raiz e não há npm workspaces: o único pacote JavaScript
do repositório é `apps/mobile`.

## Subindo o `apps/rails`

Precisa de Ruby 3.3.6, Docker e do cliente PostgreSQL **16** (`psql` e `pg_dump`
— o schema é versionado como `db/structure.sql`).

```bash
# 1. Banco (Postgres 16 + PostGIS 3.4), na raiz do repositorio
docker compose -f docker-compose.dev.yml up -d

# 2. Variaveis de ambiente
cd apps/rails
cp .env.example .env
openssl rand -hex 64      # cole em DEVISE_JWT_SECRET_KEY no .env

# 3. Dependencias, banco e servidor
bundle install
bin/rails db:prepare      # cria, carrega o structure.sql e roda os seeds
bin/rails server          # http://localhost:3000, health check em /up
```

Testes: `bin/rails test` (Minitest + fixtures). Detalhes, seeds e as armadilhas
do PostGIS estão em `apps/rails/DEVELOPMENT.md`.

## Subindo o `apps/mobile`

Precisa de Node 20+ e do app Expo Go (ou um emulador).

```bash
cd apps/mobile
npm install
npx tsc --noEmit          # checagem de tipos
npm start                 # Expo; use --android, --ios ou --web
```

Em desenvolvimento o app aponta para `http://localhost:3000/api/v1`
(`src/constants/index.ts`), então suba o `apps/rails` antes. Em dispositivo
físico, troque `localhost` pelo IP da máquina na rede local.

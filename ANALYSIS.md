# Análise técnica — marmitas.top

**Data:** 07/09/2026 · **Branch analisado:** `master` (44 commits) · **Issue:** BRES-96

Este documento é o retrato do repositório hoje: o que existe, o que está quebrado,
o que falta e o que precisa ser refeito. Ele substitui o `REPOSITORY_ANALYSIS.md`
(nov/2025), que descreve apenas o site estático de 2019 e não conhece a V2.

---

## 1. Resumo

O repositório tem **dois projetos coabitando**: o site estático morto de 2019 na
raiz, e a V2 (API Rails 8 + app Expo) em `backend/` e `frontend/`.

A V2 está mais avançada do que parece: 12 modelos, 15 controllers, 17 migrations,
~2.650 linhas de React Native. Mas ela **nunca foi executada de ponta a ponta por
ninguém**, e a análise abaixo mostra por quê: um banco criado do zero sai sem a
tabela principal de localização, o CI não roda (está na pasta errada), e não
existe um único teste de verdade.

O trabalho não é "continuar de onde parou". É **provar que o que existe funciona**,
e só então continuar.

| Área | Estado |
|---|---|
| Backend Rails — modelagem e endpoints | Escrito, nunca verificado |
| Backend — banco a partir do zero | **Quebrado** (§3.1) |
| CI | **Não executa** (§3.2) |
| Testes | **Zero** (§3.3) |
| Autorização | Ad-hoc, Pundit declarado e não usado (§4.1) |
| App Expo — lado consumidor | Parcial, sem push (§5.1) |
| App Expo — lado marmiteiro | **Inexistente** (§5.2) |
| App Expo — avaliações | **Inexistente** (§5.3) |
| Raiz do repo | Projeto morto de 2019 (§6) |

---

## 2. O que existe de fato

### Backend (`backend/`, Rails 8.1, Ruby 3.3.6, PostgreSQL + PostGIS)

Modelos: `User`, `SellerProfile`, `Dish`, `WeeklyMenu`, `WeeklyMenuDish`,
`SellingLocation`, `Favorite` (polimórfico), `Review`, `ReviewHelpful`,
`DeviceToken`, `JwtDenylist`.

API `api/v1` com 15 controllers: autenticação (Devise + JWT), navegação pública de
marmiteiros e cardápios, área do vendedor (perfil, pratos, cardápio semanal,
chegar/sair de um ponto de venda), favoritos, tokens de dispositivo, preferências
de notificação, mapa em GeoJSON, avaliações e moderação de avaliações.

Também existem: `PushNotificationService`, `NotifyFollowersJob`,
`SendModerationAlertJob`, e o texto pronto para compartilhar cardápio no WhatsApp.

A qualidade do código lido é razoável. O problema não é o código — é que nada
disso tem prova de funcionamento.

### App (`frontend/`, Expo 54, React Native 0.81, TypeScript)

7 telas: Login, Register, Home (lista de marmiteiros), Map, SellerDetail,
Favorites, Profile. Navegação por abas + stack. `AuthContext` com token em
`AsyncStorage`. Cliente HTTP (`src/services/api.ts`) com 25 métodos.

### Documentação

`PROJECT_SPECIFICATION_V2.md` (spec do produto, boa), `RAILS_ARCHITECTURE.md`,
`EXPO_ARCHITECTURE.md`, `rating.md` (spec do sistema de avaliações),
`SETUP_GUIDE.md` (desatualizado — descreve como "próximo passo" coisas que já
foram feitas).

---

## 3. Bloqueios — nada é verificável enquanto estes existirem

### 3.1 Um banco criado do zero não tem a tabela `selling_locations`

`backend/db/schema.rb`, linha 176:

```
# Could not dump table "selling_locations" because of following StandardError
#   Unknown type 'geography' for column 'lonlat'
```

A migration `20251110010319_enable_postgis.rb` habilita PostGIS e
`selling_locations` tem uma coluna `geography`. Mas o `schema_format` do Rails é
o padrão (`:ruby`), e o adapter é o `postgresql` puro — sem
`activerecord-postgis-adapter`. Resultado: o dump não consegue representar a
coluna e **descarta a tabela inteira** do `schema.rb`.

Consequência prática: `db:prepare`, `db:schema:load` e o setup de banco de teste
criam um banco **sem a tabela de pontos de venda**. Ou seja, a funcionalidade
central do produto — o marmiteiro anunciar onde está — não sobe em nenhuma
máquina nova, nem em CI.

Correção: `config.active_record.schema_format = :sql` (passa a usar
`structure.sql`) ou adotar o `activerecord-postgis-adapter`. É a primeira coisa
a fazer; sem isso nenhuma outra verificação é possível.

### 3.2 O CI nunca rodou

O workflow está em `backend/.github/workflows/ci.yml`. O GitHub Actions só lê
`.github/workflows/` **na raiz do repositório**. O arquivo é ignorado.

Dois problemas somados a esse:

- o gatilho é `push: branches: [main]`, e o branch padrão do repo é `master`;
- o workflow tem `brakeman`, `bundler-audit` e `rubocop`, mas **nenhum job de
  teste**.

O mesmo vale para `backend/.github/dependabot.yml`, que também está fora da raiz
e portanto inativo.

### 3.3 Não existe nenhum teste

`backend/spec/` tem 3 arquivos, e os 3 são o stub do gerador:

```ruby
RSpec.describe User, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
```

Não existe `spec/rails_helper.rb` nem `.rspec` — o `rails generate rspec:install`
nunca foi executado. Os specs sequer carregam (`require 'rails_helper'` falha).
As factories são o esqueleto gerado, com `"MyString"` nos campos e
`factory :user do end` vazio.

O app Expo não tem teste nenhum, nem lint, nem `tsc --noEmit` em CI.

15 controllers, ~2.000 linhas de regra de negócio, zero cobertura.

### 3.4 Não há como subir o ambiente

Sem `docker-compose.yml`, sem `.env.example`, sem seeds (`db/seeds.rb` é o
comentário padrão do Rails). O `DEVELOPMENT.md` tem 1 KB. Cada pessoa ou agente
que pegar o repo vai improvisar um Postgres com PostGIS por conta própria.

---

## 4. Backend — o que precisa ser revisto

### 4.1 Pundit está no Gemfile e não é usado em lugar nenhum

```
gem "pundit", "~> 2.3"
```

Não existe `app/policies/`. Nenhuma chamada a `authorize` no código. A
autorização é feita à mão em cada controller (`before_action :require_admin!`,
checagens de dono espalhadas). Isso funciona até alguém esquecer uma — e não há
teste que pegue o esquecimento.

Ou se adota Pundit com policies e testes de acesso, ou se remove o gem e se
assume a checagem manual com cobertura. O estado atual é o pior dos dois.

### 4.2 `reviews_count` tem duas fontes de verdade que se contradizem

Em `Review`:

```ruby
belongs_to :seller_profile, counter_cache: :reviews_count
```

Em `SellerProfile#recalculate_ratings!`, chamada por `after_save` de toda review:

```ruby
reviews_count: published_reviews.count
```

O counter cache conta **todas** as reviews; o recálculo grava só as
**publicadas**. Os dois escrevem na mesma coluna, em ordens diferentes. Pior: o
método retorna cedo (`return set_no_rating if published_reviews.count < 5`)
antes de gravar o contador, então abaixo de 5 avaliações o valor fica o que o
counter cache deixou. Precisa de um teste que fixe o comportamento esperado e de
uma única fonte de verdade.

### 4.3 Fila de jobs ambígua

O Gemfile traz `solid_queue` (padrão do Rails 8) **e** `sidekiq` + `redis`.
Nenhum `queue_adapter` está configurado em `config/application.rb`, e há
comentários no código dizendo "will implement with Sidekiq later". Os jobs de
push (`NotifyFollowersJob`) dependem disso. Escolher um, configurar, e apagar o
outro.

### 4.4 Itens menores, mas reais

- `jsonapi-serializer` no Gemfile, sem `app/serializers/` — os controllers montam
  JSON à mão. Decidir e limpar.
- `config/database.yml` usa `max_connections:`, que não é uma chave do Rails. O
  correto é `pool:`. O pool está silenciosamente no padrão.
- CORS (`config/initializers/cors.rb`) só libera `localhost` e `exp://`. Não há
  origem de produção. O app em produção vai bater em CORS.
- Action Cable está no `cable.yml` mas não existe `app/channels/` — o tempo real
  descrito na spec não foi implementado.
- Paginação feita à mão com `params[:page]` em vários controllers, com
  `per_page` sem teto — um cliente pode pedir `per_page=100000`.

---

## 5. App — o que falta

### 5.1 Push notification: 0% no app, 100% no backend

`expo-notifications` está no `package.json` e **nunca é importado**. O método
`registerDeviceToken()` existe em `api.ts` e **nunca é chamado**. Do lado do
servidor está tudo pronto: tabela `device_tokens`, `PushNotificationService`,
`NotifyFollowersJob` disparado quando o marmiteiro chega.

O recurso que é o argumento de venda do produto — "te aviso quando o marmiteiro
chegar" — não funciona porque falta a ponta do app.

### 5.2 Todo o lado do marmiteiro não existe no app

O backend tem `api/v1/seller/*`: perfil, pratos, cardápio semanal, chegar/sair de
um ponto de venda. O app **não tem nenhuma tela nem nenhum método de API** para
isso. Um marmiteiro hoje não consegue usar o aplicativo.

Isso é metade do produto.

### 5.3 Avaliações não existem no app

Backend completo (modelo com moderação, verificação por proximidade, detecção de
spam, média ponderada por recência, painel de admin). App: nenhuma tela, nenhum
método em `api.ts`. Foi implementado e nunca exposto.

### 5.4 Outros

- Sem tratamento de erro visível ao usuário, sem estados de carregamento
  consistentes, sem tela vazia.
- `constants/index.ts` tem cores, espaçamentos e tipografia, mas não há
  componentes compartilhados — cada tela repete estilos.
- `API_URL` de produção é `https://api.marmitas.top` — o domínio existe? Não há
  nada de deploy no repo.
- Sem TypeScript check, sem lint, sem CI.

---

## 6. A raiz do repositório ainda é o projeto de 2019

Na raiz convivem: `package.json` (nome `hyperion`, autor Christian Kaisermann),
`package-lock.json` de 557 KB com dependências de 2018, `gulpfile.js/`, `app/`
(templates Nunjucks + Stylus), `.hyperion/`, `.babelrc`, `.eslintrc`,
`.stylintrc`, e `.nvmrc` apontando para **Node v9.0.0** (fim de vida em 2018).

Isso não é só desordem: qualquer ferramenta que olhe a raiz (auditoria de
dependências, Dependabot, CI, um agente novo lendo o repo) vai encontrar primeiro
um projeto morto com dezenas de vulnerabilidades conhecidas, e não a V2.

Recomendação: preservar em uma tag (`v1-static-site`) e remover da `master`.

---

## 7. O que precisa ser refeito, o que precisa ser feito

**Refeito:**

- Estratégia de schema do banco (§3.1) — a atual não funciona.
- Local e conteúdo do CI (§3.2) — mover para a raiz e incluir testes.
- Setup de teste do backend (§3.3) — instalar RSpec de verdade e escrever as
  factories.
- Decisão sobre Pundit (§4.1) e sobre a fila de jobs (§4.3).
- `SETUP_GUIDE.md` (descreve como pendente o que já foi feito) e
  `REPOSITORY_ANALYSIS.md` (fala de um projeto que não é mais este).

**Feito do zero:**

- Ambiente reproduzível: docker-compose com Postgres+PostGIS, `.env.example`,
  seeds com dados realistas.
- Testes de request para os 15 controllers.
- Push notification na ponta do app.
- Todas as telas do marmiteiro.
- Todas as telas de avaliação.
- Componentes compartilhados de UI.
- Deploy: não existe nada no repo além de um `Dockerfile` e do gem `kamal`.

**Mantido como está:** a modelagem de dados, a spec do produto
(`PROJECT_SPECIFICATION_V2.md`) e a lógica das avaliações (`rating.md`) — são
bons e não precisam ser reescritos, só testados.

---

## 8. Ordem sugerida

1. **Destravar** — schema do banco, CI na raiz com testes, RSpec instalado,
   docker-compose. Sem isso, nenhuma entrega seguinte é verificável.
2. **Provar** — testes de request de toda a API, decisão e testes de
   autorização, correção do `reviews_count`.
3. **Completar o produto** — lado do marmiteiro no app, avaliações no app, push
   funcionando ponta a ponta.
4. **Limpar** — remover o site de 2019, consolidar a documentação, definir
   deploy.

---

## 9. Perguntas que só o Rafael responde

1. **O domínio `api.marmitas.top` existe e para onde vai o deploy?** Não há nada
   de infraestrutura no repositório. Isso muda o que a etapa 4 precisa entregar.
2. **O site estático de 2019 pode sair da `master`?** A recomendação é preservar
   em tag e remover, mas é uma decisão dele.
3. **Existe algum usuário real hoje?** Se não, dá para mudar schema e API sem
   migração de dados, o que acelera muito as etapas 1 e 2.

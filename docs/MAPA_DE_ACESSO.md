# Mapa de acesso da API

Toda ação de `api/v1`, quem pode chamar, e onde isso é checado depois da
BRES-103. Cinco papéis: **anônimo** (sem token), **consumidor** (conta sem
perfil de marmiteiro), **vendedor dono** (o marmiteiro do registro),
**vendedor outro** (qualquer outro marmiteiro) e **admin**.

A coluna "onde é checado" diz o que roda. `authorize` é a chamada do Pundit;
`escopo` é a busca pela associação do dono (`current_user.seller_profile.dishes.find`),
que responde 404 para id alheio antes de a policy opinar.

`after_action :verify_authorized` está ligado no `ApplicationController`: uma
ação que esqueça o `authorize` estoura, não passa em silêncio. As duas únicas
dispensas são `auth#register` e `auth#login`, que acontecem antes de existir
usuário.

## Autenticação

| Ação | Anônimo | Consumidor | Vendedor dono | Vendedor outro | Admin | Onde é checado |
|---|---|---|---|---|---|---|
| `POST auth/register` | ✅ | ✅ | ✅ | ✅ | ✅ | fora do `verify_authorized` |
| `POST auth/login` | ✅ | ✅ | ✅ | ✅ | ✅ | fora do `verify_authorized` |
| `DELETE auth/logout` | ❌ | ✅ | ✅ | ✅ | ✅ | `UserPolicy#logout?` |
| `GET auth/me` | ❌ | ✅ | ✅ | ✅ | ✅ | `UserPolicy#me?` |

`is_admin` não é gravável por endpoint nenhum: `register_params` permite só
email, senha, nome e telefone, e não existe rota que atualize usuário.

## Vitrine pública

| Ação | Anônimo | Consumidor | Vendedor dono | Vendedor outro | Admin | Onde é checado |
|---|---|---|---|---|---|---|
| `GET sellers` | ✅ | ✅ | ✅ | ✅ | ✅ | `SellerProfilePolicy#index?` |
| `GET sellers/:id` | ✅ | ✅ | ✅ | ✅ | ✅ | `SellerProfilePolicy#show?` |
| `GET sellers/nearby` | ✅ | ✅ | ✅ | ✅ | ✅ | `SellerProfilePolicy#nearby?` |
| `GET sellers/:id/menus` | ✅ | ✅ | ✅ | ✅ | ✅ | `WeeklyMenuPolicy#seller_menus?` |
| `GET menus` | ✅ | ✅ | ✅ | ✅ | ✅ | `WeeklyMenuPolicy#index?` |
| `GET menus/:id` | ✅ | ✅ | ✅ | ✅ | ✅ | `WeeklyMenuPolicy#show?` |
| `GET menus/available_today` | ✅ | ✅ | ✅ | ✅ | ✅ | `WeeklyMenuPolicy#available_today?` |
| `GET map/sellers` | ✅ | ✅ | ✅ | ✅ | ✅ | `MapPolicy#sellers?` |
| `GET map/bounds` | ❌ | ✅ | ✅ | ✅ | ✅ | `MapPolicy#bounds?` + rota autenticada |

`map/bounds` não está no `skip_before_action :authenticate_user!` e por isso
exige token, ao contrário de `map/sellers`. As duas policies liberam geral: a
diferença é da rota, e está aberta para decisão.

`sellers#show` responde por id mesmo para perfil não verificado; `index`,
`nearby` e o mapa filtram por `verified`.

## Avaliações

| Ação | Anônimo | Consumidor | Vendedor dono | Vendedor outro | Admin | Onde é checado |
|---|---|---|---|---|---|---|
| `GET sellers/:id/reviews` | ✅ | ✅ | ✅ | ✅ | ✅ | `ReviewPolicy#index?` |
| `GET reviews/:id` | ✅ | ✅ | ✅ | ✅ | ✅ | `ReviewPolicy#show?` |
| `POST sellers/:id/reviews` | ❌ | ✅ | ✅ | ✅ | ✅ | `ReviewPolicy#create?` |
| `PATCH reviews/:id` | ❌ | só autor | só autor | só autor | ❌ | `ReviewPolicy#update?` → `Review#editable_by?` |
| `DELETE reviews/:id` | ❌ | só autor | só autor | só autor | ❌ | `ReviewPolicy#destroy?` |
| `POST reviews/:id/flag` | ❌ | menos o autor | menos o autor | menos o autor | ✅ | `ReviewPolicy#flag?` → `Review#flaggable_by?` |
| `POST reviews/:id/helpful` | ❌ | menos o autor | menos o autor | menos o autor | ✅ | `ReviewPolicy#helpful?` |

Editar exige ser o autor **e** estar dentro de 48h **e** não estar sob
moderação. Essa regra continua no model; a policy chama, não reescreve.

## Painel do marmiteiro (`api/v1/seller/*`)

| Ação | Anônimo | Consumidor | Vendedor dono | Vendedor outro | Admin | Onde é checado |
|---|---|---|---|---|---|---|
| `GET seller/profile` | ❌ | ✅ | ✅ | ✅ | ✅ | `Seller::SellerProfilePolicy#show?` |
| `POST seller/profile` | ❌ | ✅ | ✅ | ✅ | ✅ | `Seller::SellerProfilePolicy#create?` |
| `PATCH seller/profile` | ❌ | ❌ | ✅ | ❌ | ❌ | `Seller::SellerProfilePolicy#update?` |
| `DELETE seller/profile` | ❌ | ❌ | ❌ | ❌ | ❌ | rota morta — ver nota |
| `GET seller/dishes` | ❌ | ❌ | ✅ | ✅ (os seus) | ❌ | `Seller::DishPolicy#index?` |
| `GET seller/dishes/favorites_stats` | ❌ | ❌ | ✅ | ✅ (os seus) | ❌ | `Seller::DishPolicy#favorites_stats?` |
| `POST seller/dishes` | ❌ | ❌ | ✅ | ✅ | ❌ | `Seller::DishPolicy#create?` |
| `GET/PATCH/DELETE seller/dishes/:id` | ❌ | ❌ | ✅ | ❌ | ❌ | escopo + `Seller::DishPolicy` |
| `GET seller/weekly_menus` | ❌ | ❌ | ✅ | ✅ (os seus) | ❌ | `Seller::WeeklyMenuPolicy#index?` |
| `POST seller/weekly_menus` | ❌ | ❌ | ✅ | ✅ | ❌ | `Seller::WeeklyMenuPolicy#create?` |
| `GET/PATCH/DELETE seller/weekly_menus/:id` | ❌ | ❌ | ✅ | ❌ | ❌ | escopo + `Seller::WeeklyMenuPolicy` |
| `POST .../add_dish`, `DELETE .../remove_dish/:id` | ❌ | ❌ | ✅ | ❌ | ❌ | escopo + `Seller::WeeklyMenuPolicy` |
| `POST .../duplicate` | ❌ | ❌ | ✅ | ❌ | ❌ | escopo + `Seller::WeeklyMenuPolicy` |
| `GET .../whatsapp_text` | ❌ | ❌ | ✅ | ❌ | ❌ | escopo + `Seller::WeeklyMenuPolicy` |
| `GET seller/selling_locations` | ❌ | ❌ | ✅ | ✅ (os seus) | ❌ | `Seller::SellingLocationPolicy#index?` |
| `POST seller/selling_locations` | ❌ | ❌ | ✅ | ✅ | ❌ | `Seller::SellingLocationPolicy#create?` |
| `GET/PATCH/DELETE seller/selling_locations/:id` | ❌ | ❌ | ✅ | ❌ | ❌ | escopo + `Seller::SellingLocationPolicy` |
| `POST .../arrive`, `POST .../leave` | ❌ | ❌ | ✅ | ❌ | ❌ | escopo + `Seller::SellingLocationPolicy` |

O admin não entra no painel de ninguém: não tem perfil de marmiteiro e
`owns_record?` fecha.

`GET`/`POST seller/profile` valem para qualquer conta porque são o caminho de
cadastro — quem ainda não é marmiteiro precisa poder perguntar (404 "crie um
primeiro") e criar.

`DELETE seller/profile` responde 404 sempre: o `before_action :set_profile`
cobre só `[:show, :update]`, então `@profile` nunca é carregado. Não foi
consertado na BRES-103 porque ligar um delete em cascata (pratos, cardápios,
pontos de venda e avaliações) é mudança de comportamento, não de autorização.

## Moderação (`api/v1/admin/*`)

| Ação | Anônimo | Consumidor | Vendedor dono | Vendedor outro | Admin | Onde é checado |
|---|---|---|---|---|---|---|
| `GET admin/reviews` | ❌ | ❌ | ❌ | ❌ | ✅ | `Admin::ReviewPolicy#index?` |
| `GET admin/reviews/:id` | ❌ | ❌ | ❌ | ❌ | ✅ | `Admin::ReviewPolicy#show?` |
| `POST admin/reviews/:id/approve` | ❌ | ❌ | ❌ | ❌ | ✅ | `Admin::ReviewPolicy#approve?` |
| `POST admin/reviews/:id/remove` | ❌ | ❌ | ❌ | ❌ | ✅ | `Admin::ReviewPolicy#remove?` |

O marmiteiro avaliado não aprova nem remove a avaliação sobre o próprio
negócio.

## Dados pessoais

| Ação | Anônimo | Consumidor | Vendedor dono | Vendedor outro | Admin | Onde é checado |
|---|---|---|---|---|---|---|
| `GET favorites`, `/dishes`, `/sellers`, `/check` | ❌ | ✅ | ✅ | ✅ | ✅ | `FavoritePolicy` |
| `POST favorites`, `DELETE favorites/remove` | ❌ | ✅ | ✅ | ✅ | ✅ | `FavoritePolicy` |
| `DELETE favorites/:id` | ❌ | só dono | só dono | só dono | ❌ | escopo + `FavoritePolicy#destroy?` |
| `GET/POST device_tokens`, `POST /deactivate_all` | ❌ | ✅ | ✅ | ✅ | ✅ | `DeviceTokenPolicy` |
| `DELETE device_tokens/:id` | ❌ | só dono | só dono | só dono | ❌ | escopo + `DeviceTokenPolicy#destroy?` |
| `GET/PATCH notification_preferences` | ❌ | só a própria | só a própria | só a própria | só a própria | `NotificationPreferencesPolicy` |

O admin não vê nem apaga favorito, token de push ou preferência de aviso de
ninguém.

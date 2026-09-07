# A jornada do marmiteiro e o que falta no app

**Issue:** BRES-100 · **Data:** 07/09/2026

Este documento não propõe telas bonitas. Ele descreve o dia de quem vende marmita
na rua, e só depois pergunta que tela resolve cada momento desse dia.

Tudo o que está escrito aqui sobre a API foi conferido em
`backend/config/routes.rb`, nos controllers de `backend/app/controllers/api/v1/seller/`
e nos modelos correspondentes. Onde a API não cobre, está escrito que não cobre —
não há suposição.

---

## 1. Quem é ele, na hora em que usa o app

Não é alguém sentado na frente de um computador.

Ele está **de pé**, quase sempre na rua. Segura a caixa de isopor com um braço.
O celular é Android barato, tela riscada, sol batendo em cima. O 4G oscila. A
bateria começou o dia em 60%. A mão está engordurada ou molhada.

E o mais importante: **ele é interrompido**. No meio de qualquer toque, um
cliente chega e pergunta o preço. O app precisa aguentar sumir por 40 segundos e
voltar exatamente onde estava.

Três consequências diretas de projeto:

1. **Ação principal = 1 toque.** Se "cheguei" custa três toques, ele para de usar.
2. **Nada de diálogo de confirmação.** Confirmação com a mão suja é um erro a
   mais. Use ação imediata + "desfazer" por alguns segundos.
3. **Nada se perde.** Texto digitado, quantidade escolhida, tudo sobrevive ao app
   ir para segundo plano.

---

## 2. O dia dele, em ordem

| Hora | O que acontece | O que ele precisa do app |
|---|---|---|
| 05h–09h | Cozinha em casa. | Nada. Não mexe no celular. |
| ~09h30 | Terminou. Sabe o que fez e quantas. | **Publicar o cardápio do dia** e mandar no zap. É o único momento parado do dia. |
| ~10h30 | Chega no ponto, carregando tudo. | **"Cheguei"** — um toque, botão grande. |
| 11h–13h | Vendendo. Troco na mão. | **Baixar a conta**: "faltam 5", "acabou". Sem abrir tela. |
| ~13h | Acabou, ou muda de ponto. | **"Sai daqui"**, e às vezes "cheguei" no ponto seguinte. |
| Fim do dia | Volta pra casa. | Ver como foi: quem favoritou, quem avaliou. Isso pode esperar. |

As interrupções que quebram esse fluxo, e que o app tem que tratar:

- **Ele esquece de dar baixa.** É o normal, não a exceção. O cardápio publicado
  vai mostrar quantidade errada. A tela tem que deixar corrigir em um toque, sem
  culpa e sem formulário.
- **Ele esquece de sair.** Hoje o backend marca `leaving_at` com 12 horas por
  padrão (`SellerProfile::DEFAULT_BROADCAST_DURATION`) e **nada desliga o
  anúncio quando o prazo vence** — ver §5, item 6. Ele fica no mapa a noite
  inteira, e o consumidor vai até um ponto vazio. Isso queima o produto para os
  dois lados.
- **Nem todo marmiteiro tem ponto.** Uns vendem sempre nos mesmos 2 ou 3 lugares;
  outros andam por uma região o dia inteiro e precisam transmitir a posição. O
  modelo hoje só atende o primeiro: a posição vem de um lugar salvo e só muda com
  `leave` + `arrive`. Os dois viram um conceito só na §7.

---

## 3. O conjunto mínimo de telas

Ordem de prioridade. Cada item diz o que resolve, que endpoints usa e quantos
toques custa.

### P0 — Gate: "Virar marmiteiro"

**Resolve:** hoje é impossível virar marmiteiro pelo app. Todo controller de
`api/v1/seller/*` responde `403 Seller profile required` enquanto não existir um
`seller_profile`. Sem esta tela, nenhuma das outras funciona.

Formulário curto: nome do negócio, cidade/estado, whatsapp, bio (opcional).

**Endpoints:** `POST /api/v1/seller/profile` · `GET /api/v1/seller/profile`

**Toques:** 4 campos + 1 botão. Uma vez na vida.

> ⚠️ Hoje a `RegisterScreen` tem um seletor "Consumidor / Marmiteiro"
> (`frontend/src/screens/RegisterScreen.tsx:120`) que **não faz nada**:
> `register_params` no `AuthController` permite apenas `email, password,
> password_confirmation, name, phone`. O campo `role` é descartado em silêncio,
> e `User#seller?` é simplesmente `seller_profile.present?`. Quem escolhe
> "Marmiteiro" hoje cria uma conta de consumidor comum e não tem como corrigir.
> **Proposta:** tirar o seletor do cadastro e colocar "Quero vender marmita" no
> Perfil, levando para esta tela.

### P0 — "Hoje" (a casa do marmiteiro)

**Resolve:** o dia inteiro em uma tela só. É a tela que ele abre 15 vezes por dia.

Três blocos, de cima para baixo:

1. **Onde você está** — "Você está na Praça XV desde 10h32. Sai às 13h." ou
   "Você não está anunciando."
2. **O botão** — `Cheguei` (verde, altura ≥ 64pt, ocupa a largura da tela) ou
   `Sai daqui` quando já está anunciando. Um toque. Sem confirmação, com
   "desfazer" por 5 segundos.
3. **Cardápio de hoje** — cada prato com o que resta e os controles `−` / `+` e
   `Acabou`.

**Endpoints:** `GET /seller/profile` · `GET /seller/selling_locations` ·
`GET /seller/weekly_menus?status=active` ·
`POST /seller/selling_locations/:id/arrive` ·
`POST /seller/selling_locations/:id/leave`

**Toques:** "Cheguei" com o ponto de ontem pré-selecionado = **1**. "Sai daqui" = **1**.

**Estado vazio:** sem perfil → "Quero vender marmita". Sem ponto salvo →
"Cadastre onde você vende". Sem cardápio hoje → "Publicar o cardápio de hoje"
com atalho para "repetir o de ontem".

**Estado de erro:** sem sinal, o toque em "Cheguei" fica pendente na tela
("Anunciando… vamos tentar de novo") e reenvia sozinho. Ele não pode ficar
olhando um spinner na calçada.

> ⚠️ Os controles `−` / `+` / `Acabou` **não têm endpoint**. Ver §5, item 1. Sem
> isso, este bloco vira só leitura, e o dia dele perde a ação mais frequente.

### P0 — "Cheguei" (folha de baixo, não tela cheia)

**Resolve:** de onde vem a posição deste turno (§7).

Uma lista só, com o último usado no topo: os pontos salvos dele **mais** a linha
"Circulando por aí". Quem tem um jeito só de trabalhar nunca vê esta folha — o
botão da tela "Hoje" repete o último turno em 1 toque. Abaixo, "Até que horas?"
com três atalhos: `2h`, `4h`, `até o fim do dia`.

**Endpoints:** `POST /seller/selling_locations/:id/arrive`
(aceita `hours_from_now` ou `leaving_at`; teto de 96h em `MAX_BROADCAST_DURATION`)

**Toques:** 1 (o ponto) + 1 opcional (a duração). Com 1 ponto salvo, esta folha
nem abre.

**Por que perguntar a duração:** o padrão do backend é 12 horas. Doze horas é a
noite inteira no mapa. Um atalho de "4h" custa um toque e evita o pior defeito
do produto hoje.

### P1 — "Cardápio de hoje" (publicar)

**Resolve:** o momento das 09h30. É a única tela em que ele digita.

Duas portas de entrada:

- **"Repetir o de ontem"** — o caminho de 80% dos dias.
- **Montar do zero** — lista os pratos já cadastrados, ele marca os de hoje e
  põe a quantidade de cada um.

Depois de publicar, a tela mostra **"Mandar no zap"**: pega o texto pronto do
backend e abre o WhatsApp com a mensagem preenchida.

**Endpoints:** `GET /seller/dishes` · `POST /seller/weekly_menus` ·
`POST /seller/weekly_menus/:id/add_dish` · `POST /seller/weekly_menus/:id/duplicate` ·
`GET /seller/weekly_menus/:id/whatsapp_text` (devolve `message` e
`encoded_message`, pronto para `Linking.openURL('whatsapp://send?text=…')`)

**Toques:** repetir o de ontem = **2**. Montar com 2 pratos já cadastrados =
**5 toques + 2 digitações de número**. Mandar no zap = **2**.

**Nota de modelo:** a tabela se chama `weekly_menus`, mas o controller trata como
cardápio do dia ("Daily menu created successfully") e exige `available_from` /
`available_until`. Na interface é **"cardápio de hoje"**, e o app calcula a
janela do dia. Não expor "semanal" para o marmiteiro.

**Estado vazio:** nenhum prato cadastrado → manda direto para "Meus pratos".

### P1 — "Meus pratos"

**Resolve:** ele faz as mesmas 5 ou 6 coisas o ano todo. Cadastra uma vez, reusa
todo dia. É o que faz "publicar o cardápio" custar 2 toques em vez de 20.

Lista com nome, preço e quantas pessoas favoritaram. Criar/editar: nome, preço,
descrição, marcadores (vegetariano, sem glúten…), fotos.

**Endpoints:** `GET/POST/PATCH/DELETE /seller/dishes` ·
`GET /seller/dishes/favorites_stats`

**Toques:** criar um prato = 3 campos + 1 botão.

> ⚠️ As fotos do prato sobem por `multipart/form-data`
> (`DishesController#attach_photos`). O `api.ts` de hoje é só JSON — precisa de um
> caminho com `FormData`. Ver §5, item 10.

### P2 — "Meus pontos"

**Resolve:** cadastrar e ajustar onde ele vende.

**Endpoints:** `GET/POST/PATCH/DELETE /seller/selling_locations`

**Toques:** cadastrar = nome + "usar onde estou agora" + salvar = **3**.

**Deixa de ser obrigatória.** Com o mecanismo da §7, os pontos aparecem sozinhos
depois da terceira visita ao mesmo lugar. Esta tela é para quem quer preparar
tudo antes, e para renomear ou apagar.

**Limite duro:** 3 pontos por marmiteiro, validado na criação. O quarto `POST`
falha com `"Cannot have more than 3 selling locations"`. A tela mostra "3 de 3"
**antes** de ele digitar, não depois de tentar salvar. Ver §5, item 7.

### P3 — "Minha loja"

**Resolve:** o fim do dia. Editar o perfil, ver as avaliações recebidas, ver os
pratos mais favoritados.

**Endpoints:** `GET/PATCH /seller/profile` · `GET /sellers/:id/reviews` (público,
ele usa o próprio id) · `GET /seller/dishes/favorites_stats`

**Nota:** `SellerProfile#display_rating?` só mostra a nota a partir de **5
avaliações**. Abaixo disso o texto correto é "Marmiteiro novo (2 avaliações)",
nunca "0 estrelas" — isso vale para as duas pontas do app.

### Navegação

O marmiteiro **não deve ver as abas do consumidor** quando está trabalhando. A
proposta: quando `has_seller_profile` for verdadeiro, o app ganha um seletor no
topo do Perfil — "Comprando" / "Vendendo" — que troca o conjunto de abas.

- **Vendendo:** Hoje · Cardápio · Pratos · Minha loja
- **Comprando:** as 4 abas de hoje

Ele é as duas coisas. Muita gente que vende marmita também compra marmita.

---

## 4. Resumo dos toques

| Ação | Toques | Bloqueada? |
|---|---|---|
| Cheguei (repetindo o último turno) | 1 | não |
| Cheguei (escolher na lista: pontos + "circulando") | 2 | parcial — a linha "circulando" precisa da §5.7 |
| Sai daqui pela notificação fixa, sem abrir o app | 1 | precisa do serviço em primeiro plano (§7) |
| Sai daqui | 1 | não |
| "Faltam 5" (baixar 1) | 1 | **sim — sem endpoint** |
| "Acabou" | 1 | **sim — sem endpoint** |
| Repetir o cardápio de ontem | 2 | não |
| Publicar cardápio novo (2 pratos) | 5 + 2 números | não |
| Mandar no zap | 2 | não |

---

## 5. Onde a API não cobre a jornada

Cada item aqui é uma issue de backend. Nenhum deles é contornável só com tela.

1. **Não existe como mudar a quantidade restante de um prato no cardápio.**
   `WeeklyMenuDish#remaining_quantity` só é escrito na criação
   (`set_remaining_quantity`) e por `decrease_quantity!`/`increase_quantity!`, que
   **nenhum controller expõe**. As rotas do menu são só `add_dish`, `remove_dish`,
   `duplicate` e `whatsapp_text`. Para dizer "faltam 5" hoje seria preciso
   remover e re-adicionar o prato — destrutivo e errado.
   **Falta:** `PATCH /seller/weekly_menus/:id/dishes/:dish_id` com
   `remaining_quantity`. É a ação mais frequente do dia dele.

2. **Publicar cardápio não avisa ninguém.** `PushNotificationService.notify_new_menu`
   existe e **não é chamado em lugar nenhum** (conferido por busca no `backend/app`).
   Criar um `weekly_menu` não enfileira job nenhum.

3. **Sair do ponto não avisa ninguém.** `NotifyFollowersJob` com
   `'departure'` só escreve no log. O consumidor não descobre que o marmiteiro foi
   embora.

4. **A entrega de push não funciona, mesmo com o app pronto.**
   `PushNotificationService` posta em `https://fcm.googleapis.com/fcm/send` — a API
   legada do FCM, desligada pelo Google em julho de 2024 — e o app é Expo, cujo
   token tem o formato `ExponentPushToken[…]`, que o FCM não aceita. Fazer a parte
   do app (registrar o token, pedir permissão) **não faz a notificação chegar**.
   Precisa mudar para o serviço de push do Expo (`https://exp.host/--/api/v2/push/send`)
   ou para o FCM HTTP v1 com credencial de serviço.

5. **`role` no cadastro é descartado.** Ver o aviso em §3, P0-Gate.

6. **Anúncio vencido nunca desliga.** `SellerProfile#auto_shutoff_if_expired!`
   existe e **não é chamado por nada** — não há cron, não há job recorrente. Com o
   padrão de 12h, quem esquece de sair fica no mapa a noite inteira. Mitigação no
   app: perguntar a duração no "Cheguei" (§3). Correção de verdade: um job
   recorrente no backend.

7. **Não existe posição ao vivo, e o teto de 3 conta tudo.** Não há como o
   ambulante transmitir onde está: a posição só muda com `leave` + `arrive`, e
   `SellingLocation#maximum_locations_per_seller` conta toda linha de
   `selling_locations`. **Falta:** coluna `kind` (`ponto` | `circulando`), com a
   linha `circulando` fora do teto, e `PUT /api/v1/seller/position` para regravá-la
   durante o turno, recusando fora de turno aberto. É o que destrava a §7 — uma
   coluna e um endpoint, sem tocar no mapa.

12. **Marmiteiro novo é invisível.** `seller_profiles.verified` nasce `false`
    (migration `20251107212103`) e todas as rotas de descoberta filtram `.verified`:
    `map/sellers`, `map/bounds`, `sellers`, `sellers/nearby`. Não existe endpoint
    para verificar ninguém — o namespace admin só tem avaliações. Ele se cadastra,
    publica cardápio, anuncia chegada, e não aparece para nenhum consumidor. Isso
    anula os dois modos da §7 e boa parte do produto.

8. **Não existe caixa de avisos do marmiteiro.** A spec promete "novo seguidor",
   "nova avaliação", "100 seguidores". Não existe tabela de notificação, nem
   endpoint, nem gatilho. Só dá para inferir olhando `followers_count` e a lista de
   avaliações.

9. **Não existe endpoint de estatística do dia.** "Quantas pessoas viram você
   hoje", "quantos avisos foram enviados" — não há nada disso. O que existe:
   `followers_count`, `average_rating`, `reviews_count` no perfil, e
   `GET /seller/dishes/favorites_stats`. O painel proposto usa só isso; não
   prometa mais na tela.

10. **Foto de prato é multipart e o cliente HTTP é só JSON.** Não é falta de API,
    é falta no `api.ts` — precisa de um caminho `FormData`.

11. **CORS não tem origem de produção** (`config/initializers/cors.rb` libera só
    `localhost` e `exp://`). Um build de produção do app bate em CORS. Não é UX,
    mas trava o teste real da tela.

---

## 6. As duas lacunas do lado do consumidor

### 6.1 Avaliações — backend inteiro, app zero

O backend tem modelo completo: moderação, verificação por proximidade, detecção
de spam, média ponderada por recência, painel de admin. O app não tem nem tela nem
método em `api.ts`.

**O mínimo:**

- **Bloco de avaliações no `SellerDetailScreen`** — nota, quantidade e as últimas
  3 avaliações, com "ver todas". `GET /sellers/:id/reviews` (devolve
  `rating_summary` com distribuição e tendência prontos).
- **Folha "Avaliar"** — 5 estrelas + comentário opcional. **2 toques** no caso
  mínimo (estrela + enviar).
  `POST /sellers/:id/reviews`.

**Três regras do backend que a tela precisa respeitar:**

- Mandar `encounter_latitude`/`encounter_longitude` junto. Se o consumidor estiver
  a menos de 50 m do ponto onde o marmiteiro está anunciando, a avaliação sai como
  `verified_encounter` — vale um selo "avaliou no local". Se ele negar o GPS, a
  avaliação ainda vale, só não é verificada. Diga isso na tela, não esconda.
- **Nota 1 ou 5 exige comentário** (`validates :comment, presence: true, if:
  :extreme_rating?`). O botão "Enviar" fica desativado até ter texto, com o motivo
  escrito: "Conta pra gente o que aconteceu."
- **Uma avaliação por marmiteiro por dia.** O erro do backend já vem em português
  ("Você já avaliou este marmiteiro hoje") — mostre esse texto, não um genérico.
- **Abaixo de 5 avaliações não existe nota.** Mostre "Marmiteiro novo".

### 6.2 Push — o argumento de venda que não funciona

`expo-notifications` está no `package.json` e **nunca é importado**.
`api.registerDeviceToken()` existe e **nunca é chamado**.

**O mínimo do lado do app:**

1. Pedir permissão **na hora certa**: logo depois do primeiro favorito, com a
   frase "Quer que a gente te avise quando ele chegar?". Nunca na abertura do app —
   pedido frio na primeira tela é negado e não volta atrás.
2. Pegar o token do Expo e mandar para `POST /device_tokens` com a plataforma.
3. Tocar na notificação abre o `SellerDetail` do marmiteiro (o payload já traz
   `seller_id` e `location_id`).
4. Tela de preferências, ligada em `GET/PATCH /notification_preferences` (já
   existe: `seller_arrivals`, `new_menus`, `order_updates`, `promotions`).

**E o aviso honesto:** feito tudo isso, **a notificação ainda não chega**, pelo
item 4 da §5. Fazer a ponta do app sem corrigir a entrega no backend entrega uma
permissão pedida e nenhuma notificação — que é pior do que não pedir. As duas
coisas precisam andar juntas.

---

## 7. Ambulante e ponto fixo: um conceito só

São dois públicos de verdade, com necessidades opostas:

- **O ambulante** anda por uma região o dia inteiro. Precisa **transmitir a
  posição de tempos em tempos**. Gastar bateria faz parte do trabalho dele.
- **O ponto fixo** vende no mesmo lugar vários dias, no máximo 2 ou 3 lugares.
  Precisa dizer "estou no ponto B", e **esse pino não pode andar no mapa**.

Não são dois produtos. São **duas maneiras de dizer a mesma frase: "estou
aberto"**.

### O conceito único: o turno

Um turno é: ele abriu, está vendendo, vai fechar. O modelo já tem isso inteiro —
`currently_active`, `arrived_at`, `leaving_at`, `current_location_id`.

A única diferença entre os dois públicos é **de onde vem a posição do turno**:

| | De onde vem a posição | O pino |
|---|---|---|
| **Ponto** | De um lugar salvo. Escrita uma vez, na chegada. | Parado |
| **Circulando** | Do aparelho, enquanto o turno está aberto. | Anda |

Tudo o mais é idêntico: o mesmo botão, o mesmo cardápio, o mesmo aviso aos
seguidores, o mesmo desligamento automático no `leaving_at`, a mesma tela do
consumidor. Uma regra, dois valores.

### Por que isso é DRY: o mapa não muda uma linha

`MapController#sellers` lê a coordenada de `seller.current_location.longitude` e
`.latitude`, e `SellerProfile.nearby` faz o `ST_DWithin` em
`selling_locations.lonlat`.

Então a posição do ambulante mora onde já mora a de todo mundo: **uma linha de
`selling_locations`, uma por marmiteiro, do tipo "circulando"**, que o app
regrava enquanto o turno está aberto.

O que continua funcionando sem tocar:

- `SellerProfile.nearby` e a consulta PostGIS;
- `GET /map/sellers` e `GET /map/bounds`;
- `arrive`, `leave`, `current_location_id`;
- o push de chegada aos seguidores.

A alternativa — colocar `current_latitude/longitude/lonlat` em `seller_profiles` —
é conceitualmente mais bonita e mexe na consulta PostGIS, no controller do mapa e
no GeoJSON. Não compensa, ainda mais com o schema PostGIS já quebrado
(`ANALYSIS.md` §3.1).

### Por que isso é KISS: não existe "modo" na interface

Ele nunca escolhe um perfil, nunca vê a palavra "modo". A folha do `Cheguei` é
uma lista de onde ele pode estar, com o último usado no topo:

```
  Onde você está?
  ▸ Praça XV                     (ponto)
  ▸ Portão da obra               (ponto)
  ▸ Circulando por aí            (posição ao vivo)
```

O ambulante toca na última linha — que para ele estará sempre no topo, porque é a
que ele sempre usa. **1 toque.** O do ponto fixo toca no ponto dele. **1 toque.**
Quem só tem um jeito de trabalhar nem vê a folha: o botão da tela "Hoje" já
resolve.

É a mesma lista, o mesmo botão, o mesmo turno. A diferença entre os dois públicos
virou uma linha a mais na lista.

### O que o ambulante precisa que ainda não existe

**No app** (nada disso está instalado ou configurado hoje):

- `expo-task-manager` **não está no `package.json`**. Sem ele não há
  `Location.startLocationUpdatesAsync`, que é o que transmite em segundo plano.
- `frontend/app.json` **não tem plugins, nem permissão de localização em segundo
  plano, nem `UIBackgroundModes: ["location"]`**. Sem isso o iOS para de mandar
  quando ele bloqueia a tela — que é o estado normal do celular dele.
- No Android, transmissão em segundo plano exige **serviço em primeiro plano com
  notificação fixa**. Isso não é um custo, é um ganho: a notificação é o aviso
  "você está aberto" e leva um botão **"Sai daqui"** direto na aba de
  notificações — um toque, sem abrir o app, com a mão ocupada.

**Por distância, não por tempo.** `distanceInterval` de ~200 m em vez de um
cronômetro: parado não gasta bateria nenhuma, andando atualiza na hora. Ele
aceita gastar bateria, mas não faz sentido gastar quando ele está há 40 minutos
na mesma esquina. É o jeito mais simples e o mais preciso ao mesmo tempo.

**Desliga sozinho, sempre.** Ao tocar "Sai daqui", e no `leaving_at`. Nunca
transmite fora de um turno aberto. Isso é a regra de privacidade e também o que
impede a bateria de sumir de madrugada.

**No backend:**

1. `selling_locations.kind` (`ponto` | `circulando`). Uma linha `circulando` por
   marmiteiro, que **não conta** no teto de 3 pontos. (Substitui a coluna `saved`
   que eu tinha proposto antes — mesmo custo, resolve mais.)
2. `PUT /api/v1/seller/position` com `latitude` e `longitude`: regrava a linha
   `circulando` e atualiza `last_active_at`. **Recusa se não houver turno
   aberto** — é a trava de privacidade no servidor, não só no app.
3. No GeoJSON, devolver `kind` e `position_updated_at`.

### O consumidor precisa enxergar a diferença

Isso não é enfeite. Quem vai andar 10 minutos até um vendedor tem que saber se
ele fica parado esperando ou se está andando.

- **Ponto:** pino com o nome do lugar — "Praça XV".
- **Circulando:** marcador diferente, e o texto **"andando por aqui · há 2 min"**.

Sem a idade da posição na tela, o mapa promete uma precisão que não tem.

> ⚠️ **Os dois modos são invisíveis hoje.** `seller_profiles.verified` nasce
> `false` (migration `20251107212103`), e **todas** as rotas de descoberta filtram
> `.verified` — `map/sellers`, `map/bounds`, `sellers`, `sellers/nearby`. Não
> existe endpoint para verificar ninguém: o namespace admin só tem avaliações.
> Ou seja, um marmiteiro novo anuncia, o turno abre, e ele não aparece para
> ninguém. Vale para ponto fixo e para circulando. Ver §5, item 12.

---

## 8. Ordem de implementação sugerida

1. Componentes compartilhados e tokens de `constants` — botão, campo, estado
   vazio, estado de erro, carregamento. Tudo abaixo depende disso.
2. Gate "Virar marmiteiro" + troca "Comprando / Vendendo".
3. Tela "Hoje" com Cheguei / Sai daqui e a lista de onde ele está (§7). O caminho
   do ponto salvo funciona com a API de hoje; a linha "Circulando por aí" acende
   junto com a coluna `kind` e o `PUT /seller/position` (§5, item 7).
4. Transmissão ao vivo do ambulante: `expo-task-manager`, permissões de segundo
   plano no `app.json`, serviço em primeiro plano no Android com "Sai daqui" na
   notificação. Depende do item 3.
5. Meus pratos → Cardápio de hoje → Mandar no zap.
6. Meus pontos.
7. Avaliações do lado do consumidor.
8. Baixa de quantidade — **depois** do endpoint da §5.1.
9. Push no app — **junto com** a correção de entrega da §5.4, nunca antes.

Nada disso fica visível para o consumidor enquanto `verified` não for resolvido
(§5, item 12). Esse é o primeiro item da lista de backend, não o último.

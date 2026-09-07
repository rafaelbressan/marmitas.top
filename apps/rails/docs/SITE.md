# O site público do Marmitas Top

**Issue:** BRES-113 · **Data:** 07/09/2026

Este documento define o que é o site, para quem, com que páginas e com que
texto. Ele não escreve tela: escreve a decisão que a tela vai obedecer.

Tudo o que está escrito aqui sobre dados foi conferido em
`apps/rails/db/structure.sql`, nos modelos de `apps/rails/app/models/` e em
`apps/rails/config/routes.rb`. Onde o dado não existe, está dito que não existe
(§7) — não há suposição.

O padrão técnico já está fixado (BRES-96): o site é o próprio Rails, com Hotwire
e Tailwind, no mesmo `apps/rails`. As páginas falam com os models direto. Não há
cliente de API para o site, não há app web separado, e **não há login no site**.

---

## 1. Para que serve o site — e o que ele não é

O app resolve o uso do dia. O site resolve **o primeiro contato**, e isso é outro
problema.

Quem chega no site não tem o app. Ele veio de uma busca no Google, de um link que
um marmiteiro mandou no zap, ou de um amigo. Ele decide em segundos se instala,
se manda mensagem, ou se fecha a aba.

**O site não é o app com outra roupa.** Ele não tem mapa ao vivo, não tem
favorito, não tem aviso de chegada, não tem cadastro. Tudo isso é o app, e o
site diz isso com todas as letras em vez de fingir que faz.

O que o site faz, em uma frase por público:

- **Consumidor:** mostra que existe marmita boa e barata perto dele, com nome,
  foto, preço e como falar com quem faz — **sem pedir nada em troca**.
- **Marmiteiro:** explica em 30 segundos que ele ganha freguesia sem pagar nada,
  e mostra a página dele pronta como prova.

Se o site cobra cadastro antes de mostrar comida, ele perde os dois.

---

## 2. As duas jornadas, do clique de fora até a ação

### 2.1 Consumidor — "tem marmita boa e barata perto de mim?"

```
Google: "quentinha em Botafogo"
   └─> /marmita-em/rio-de-janeiro/botafogo
         vê 6 marmiteiros, foto, preço a partir de R$ 15, nota
         └─> /m/joao-da-marmita
               vê o cardápio de hoje, o preço, quem já comeu o que achou
               ├─> [Chamar no zap]        ← ação principal, resolve HOJE
               └─> [Me avisa quando ele chegar]  ← baixa o app, resolve AMANHÃ
```

A ordem importa. **Primeiro entrega, depois pede.** Pedir o download antes de
mostrar comida é pedir esforço antes de dar valor — e ele fecha a aba.

O outro caminho é mais curto e mais comum do que parece: o marmiteiro manda o
link da página dele no grupo do zap do prédio. A pessoa cai direto em `/m/:slug`
sem passar por lugar nenhum. **Essa página tem que se sustentar sozinha**, sem
contexto e sem menu de navegação.

### 2.2 Marmiteiro — "isso me traz cliente e quanto custa?"

```
Um marmiteiro mostra a página dele para outro no ponto
   └─> /vender
         "Você cozinha. A gente avisa a sua freguesia."
         entende: é de graça, é um toque por dia, o cliente recebe aviso
         ├─> [Ver uma página de verdade] ─> /m/joao-da-marmita  (a prova)
         └─> [Baixar o app] ─> /app                             ← ação principal
```

Ele não quer ler sobre "plataforma". Ele quer saber três coisas, nesta ordem:
**quanto custa**, **quanto trabalho dá**, **isso traz gente**. A página responde
as três acima da dobra, e a prova é uma página de marmiteiro real, não um
desenho.

Não há cadastro no site. Quem quer vender baixa o app — porque vender exige
"cheguei", cardápio e aviso, e nada disso funciona no navegador.

---

## 3. O que é público sem login — a decisão

Esta é a decisão mais pesada da issue, e ela não é uma só: é **uma por tipo de
dado**.

### 3.1 A regra que decide tudo

> **O que é estável e a pessoa escolheu publicar pode ir para o Google.
> O que muda junto com o corpo dela, não.**

Nome do negócio, comida, preço e o ponto onde ela vende todo dia são **placa de
comércio**: existem para ser achados, são iguais amanhã, e publicar não conta
nada de novo sobre a pessoa.

"Onde ela está agora" é outra coisa. Publicado na web aberta e indexado, isso
vira **registro de paradeiro de uma pessoa física** — que trabalha sozinha, na
rua, com dinheiro no bolso. O Google guarda cópia; a página cacheada sobrevive
ao turno. Repetido por semanas, o índice vira histórico de deslocamento de
alguém que só queria vender almoço.

Não é hipótese distante: são quase sempre mulheres vendendo sozinhas em ponto
fixo, com o horário de chegada e a hora de fechar o caixa escritos numa página
que qualquer um lê sem se identificar.

### 3.2 Três camadas

**Camada 1 — pública e indexável** (entra no Google, entra no sitemap):

- nome do negócio, foto, bio;
- pratos, preços, tags de dieta, foto do prato;
- cardápio da semana e o de hoje;
- nota e avaliações (com a regra de nome do §3.4);
- **cidade e bairro** onde ele costuma vender — nunca mais fino que bairro;
- o **nome** dos pontos habituais ("Praça XV", "Portão da obra"), sem endereço.

Nada aqui tem hora. É o retrato do negócio, não do dia.

**Camada 2 — pública, mas fora do índice** ("está vendendo agora"):

Renderizada em um Turbo Frame próprio (`/m/:slug/agora`), com
`X-Robots-Tag: noindex` e `Cache-Control: no-store`. O HTML principal da página
não contém nada disso, então o que o Google guarda nunca tem hora nem lugar.

O que ela mostra, e com que precisão:

| Situação | O site mostra | Por quê |
|---|---|---|
| Turno aberto, **ponto salvo** | "Vendendo agora na **Praça XV**, Centro · chegou às 10h32" | O ponto é público, é o mesmo todo dia e é onde ele quer ser achado. É placa. |
| Turno aberto, **circulando** | "Circulando **pelo Centro** agora" | Não há ponto: a posição é o corpo dele em tempo real. Bairro resolve a descoberta sem dizer a esquina. |
| Turno fechado | "Não está vendendo agora · costuma vender no Centro" | O passado não fica na tela. |

**Camada 3 — nunca no site, em nenhuma hipótese:**

- **coordenada** (latitude/longitude) em HTML, em JSON, em atributo de dado ou em
  URL de mapa. Pino no mapa é o app, com a pessoa localizada e logada;
- **`selling_locations.address`** — é texto livre, escrito pelo marmiteiro, e
  hoje pode conter "portão da obra da Rua X, 300" ou o **endereço da casa dele**,
  para quem vende de casa. O site usa só `name` + bairro;
- **telefone e whatsapp em texto** — §3.3;
- posição de quem está circulando com qualquer precisão maior que bairro;
- qualquer coisa depois que o turno fecha.

### 3.3 O botão do zap sem publicar o número

O zap é a ação principal da página do marmiteiro, e ao mesmo tempo um número de
celular de pessoa física numa página aberta — comida pronta para robô de spam e
para lista de disparo.

**Solução:** o número não aparece no HTML. O botão aponta para
`/m/:slug/zap`, que responde `302` para `https://wa.me/55…` com a mensagem
pré-preenchida. Um clique para a pessoa, nada colhível para o robô, e de quebra
dá para contar quantos cliques a página gera — que é o número que o marmiteiro
quer ver.

### 3.4 Avaliações: nome de quem comeu

O `ReviewsController` devolve hoje `user.name` inteiro. No app, entre pessoas
logadas, tudo bem. Numa página indexada, "Rafael Bressan achou a comida fria"
é o nome completo de alguém preso ao Google para sempre.

**No site: primeiro nome + inicial** — "Rafael B.". Sem foto, sem link, sem
perfil de consumidor. Só é publicada avaliação com `moderation_status =
published`, que o model já garante.

### 3.5 O marmiteiro precisa poder desligar

Ele se cadastrou num **app**. Ninguém combinou com ele que existiria uma página
dele na internet aberta. Publicar sem dizer é errado mesmo que ajude a vender.

**A página nasce ligada** — `seller_profiles.public_page`, `default: true`
(decisão do Rafael em 07/09/2026, §8). Quem é publicado por padrão precisa ser
avisado por padrão, então as três coisas abaixo entram **junto** com a coluna, no
mesmo PR. Nenhuma é opcional.

1. **O aviso no cadastro**, uma frase na tela de "Quero vender marmita":

   > Sua página vai para a internet, e quem procurar marmita no Google te acha.
   > A rua onde você está agora não vai. Você pode desligar quando quiser.

2. **A chave no perfil, visível** — não escondida em "configurações avançadas":

   > **Minha página na internet**
   > Ligada · [Ver minha página] · [Desligar]

   Desligada: sai do `sitemap.xml`, ganha `noindex` e a URL responde `404`. Sem
   meio-termo e sem página fantasma com "este marmiteiro saiu".

3. **A página `/privacidade/o-que-aparece-de-voce`**, em português comum, com a
   lista do §3.2 item a item. É o link que se manda para o marmiteiro que
   pergunta "o que aparece de mim aí?".

### 3.6 A trava que o site precisa fazer sozinho

`SellerProfile#auto_shutoff_if_expired!` existe e **não é chamado por nada** —
não há job recorrente (levantado em `apps/mobile/UX_MARMITEIRO.md` §5.6). Com o
padrão de 12 horas, quem esquece de sair continua com `currently_active = true`
a noite inteira.

Então o site **não pode confiar em `currently_active`**. A consulta de "está
vendendo agora" é sempre:

```ruby
scope :selling_now, -> {
  where(currently_active: true).where("leaving_at IS NULL OR leaving_at > ?", Time.current)
}
```

Sem isso o site publica "vendendo agora na Praça XV" às três da manhã — errado
para o consumidor e perigoso para o marmiteiro. A correção de verdade continua
sendo o job recorrente no backend, mas a página não espera por ele.

---

## 4. As páginas, em ordem de prioridade

### P0 — `/m/:slug` · A página do marmiteiro

**Quem chega:** alguém que recebeu o link no zap, ou que achou o nome dele no
Google. Sem contexto nenhum.

**O que resolve:** "quem é, o que tem hoje, quanto custa, como falo com ele".

**Ação principal:** `Chamar no zap`. **Secundária:** `Me avisa quando ele chegar`
(leva para o app).

**Models:** `SellerProfile` (+ `profile_photo`), `Dish` (+ `photos`),
`WeeklyMenu` / `WeeklyMenuDish`, `Review`, `SellingLocation` (só `name` + bairro).

**A página, de cima para baixo:**

```
[foto]  João da Marmita                      ⭐ 4,7 (32 avaliações)
        Comida caseira · Centro, Rio de Janeiro

        ┌─ turbo-frame: /m/joao-da-marmita/agora ──────────────┐
        │ 🟢 Vendendo agora na Praça XV, Centro                │
        │    Chegou às 10h32                                   │
        └──────────────────────────────────────────────────────┘

        [ Chamar no zap ]                     ← botão grande, primário

   O que tem hoje
   ─────────────────────────────────────────
   [foto] Feijoada                    R$ 20
          Com arroz, couve e laranja
   [foto] Frango com quiabo           R$ 18
          Sem glúten

   Onde ele vende
   ─────────────────────────────────────────
   Praça XV, Centro · quase todo dia
   Portão da obra, Centro

   O que dizem quem comeu
   ─────────────────────────────────────────
   ⭐⭐⭐⭐⭐ Rafael B. · há 3 dias
   "Feijoada de domingo num terça. Voltei no outro dia."
   ⭐⭐⭐⭐ Marina S. · há 1 semana
   "Comida boa, chega meio tarde."
                                          [ Ver as 32 avaliações ]

   ┌───────────────────────────────────────────────────────────┐
   │ Quer saber na hora que ele chegar?                        │
   │ O app te avisa no celular quando o João chega no ponto.   │
   │ [ Baixar o app — de graça ]                               │
   └───────────────────────────────────────────────────────────┘
```

**Texto de estado, escrito por extenso:**

| Estado | O que a página diz |
|---|---|
| Turno fechado | "Não está vendendo agora. Costuma vender no Centro, de segunda a sexta." |
| Sem cardápio hoje | "Ele ainda não disse o que tem hoje. Chama no zap e pergunta." |
| Sem prato nenhum cadastrado | Seção some. Não existe "nenhum prato encontrado". |
| Menos de 5 avaliações | "Marmiteiro novo — ainda sem nota." (regra de `display_rating?`) |
| Nenhuma avaliação | "Ninguém avaliou ainda. Comeu? Conta pra gente pelo app." |
| Sem foto | Cor de marca com a inicial do nome. Nunca ícone de foto quebrada. |
| Marmiteiro não existe / página desligada | 404 com "Esse marmiteiro não está aqui." + busca por bairro. |
| Erro do servidor | "Deu ruim aqui do nosso lado. Tenta de novo daqui a pouco." |

**Compartilhamento no zap (og:tags).** É por aqui que a maioria das pessoas vai
ver essa página pela primeira vez. A prévia precisa mostrar foto, nome e o preço
mais baixo:

- `og:title` → "João da Marmita — marmita no Centro"
- `og:description` → "Feijoada R$ 20, frango com quiabo R$ 18. Hoje na Praça XV."
  (sem hora e sem lugar quando o turno está fechado)
- `og:image` → foto do perfil, 1200×630, **URL estável** — ver §7.9.

**Dados estruturados:** `schema.org/FoodEstablishment` com `name`, `image`,
`servesCuisine`, `priceRange`, `aggregateRating` e `areaServed` (bairro).
**Sem `address` e sem `geo`** — é a mesma decisão do §3.2, escrita em JSON-LD.

---

### P1 — `/marmita-em/:cidade/:bairro` · Quem vende marmita aqui

**Quem chega:** busca no Google — "marmita em Botafogo", "quentinha perto do
metrô". É a porta de entrada de SEO do produto inteiro.

**O que resolve:** "quem vende marmita nesse pedaço da cidade, e por quanto".

**Ação principal:** abrir a página de um marmiteiro.

**Models:** `SellerProfile` + `SellingLocation` agrupados por bairro (depende do
campo que **não existe** — §7.2), preço mínimo vindo de `Dish`.

```
   Marmita em Botafogo
   6 marmiteiros vendem por aqui. A partir de R$ 15.

   [ ] Vendendo agora (3)          ← filtro, sem JS, é só um link com query

   [foto] João da Marmita        ⭐ 4,7   a partir de R$ 18
          Vendendo agora na Praça XV
   [foto] Dona Cleide            ⭐ 4,9   a partir de R$ 15
          Costuma vender de manhã, no Largo
   ...

   Também tem marmita em: Flamengo · Catete · Laranjeiras
```

**Vazio (o estado mais comum no começo):** "Ninguém anuncia marmita em Botafogo
ainda. Se você vende por aqui, o app é de graça: [Quero vender]." — o vazio de
um lado é a captação do outro.

Ordem da lista: quem está vendendo agora primeiro, depois nota, depois quem
publicou cardápio hoje. **Nunca aleatório** — a mesma busca amanhã tem que dar a
mesma resposta.

---

### P1 — `/vender` · Para quem vende marmita

**Quem chega:** marmiteiro que viu a página de outro, ou que procurou "como
vender marmita".

**O que resolve:** "isso traz cliente, quanto custa e quanto trabalho dá".

**Ação principal:** `Baixar o app`. **Secundária:** ver uma página de marmiteiro
de verdade.

**Models:** contagem de marmiteiros e de bairros ativos, para a prova social.

```
   Você cozinha. A gente avisa a sua freguesia.

   Quem gosta da sua comida recebe um aviso no celular quando você
   chega no ponto. Você só toca em "Cheguei".

   [ Baixar o app — de graça ]      [ Ver uma página de verdade ]

   Como funciona
   1. Você diz o que fez hoje e o preço.
   2. Chegou no ponto? Um toque em "Cheguei".
   3. Quem te segue recebe o aviso na hora.

   Quanto custa
   Nada. Você não paga para aparecer, não paga por cliente e não
   tem comissão em cima da sua marmita.

   Sua página fica assim
   [prévia da página de um marmiteiro real]
   Você manda esse link no zap e no grupo do prédio. Ela é sua.

   O que aparece de você
   Seu nome, sua comida, seu preço e o bairro onde você vende.
   A rua exata onde você está agora não vai para a internet.
   [ Ver a lista inteira ]  ← /privacidade/o-que-aparece-de-voce
```

Essa última seção não é rodapé. Ela é **argumento de venda**: para quem trabalha
sozinho na rua, "não publico onde você está" é motivo para confiar.

---

### P2 — `/` · A porta da frente

**Quem chega:** quem digitou marmitas.top, ou clicou num link solto.

**O que resolve:** manda cada um para o seu lado em um toque.

**Ação principal (consumidor):** escolher a cidade / o bairro.
**Ação secundária:** a faixa "vende marmita?" leva para `/vender`.

```
   Marmita boa e barata perto de você

   [ Escolha seu bairro ▾ ]  ou  [ Usar minha localização ]

   Vendendo agora
   [foto] Dona Cleide · Centro · a partir de R$ 15
   [foto] João        · Botafogo · a partir de R$ 18

   Onde já tem marmiteiro
   Rio de Janeiro: Centro · Botafogo · Flamengo · Tijuca
   São Paulo: Pinheiros · Sé

   ─────────────────────────────────────────────
   Vende marmita? Anuncie de graça.  [ Saiba como ]
```

"Usar minha localização" é `navigator.geolocation` num controller Stimulus, que
só redireciona para o bairro mais próximo. **Nada de mapa no site** — mapa é o
app, e mapa no site é lento no 4G e ainda expõe pino.

---

### P2 — `/m/:slug/avaliacoes` · Todas as avaliações

Página 2 da anterior, com paginação (Kaminari já está no Gemfile). Existe porque
avaliação é o que convence, e cabem 3 na página do marmiteiro.

**Models:** `Review.published` do marmiteiro + `rating_distribution` do perfil.

**Vazio:** "Ninguém avaliou ainda."

---

### P3 — `/app`, `/privacidade`, `/termos`, `/privacidade/o-que-aparece-de-voce`

- **`/app`** — links das lojas, com fallback de texto. Página curta.
- **`/privacidade` e `/termos`** — obrigatórias no momento em que o site publica
  nome, foto, avaliação e bairro de pessoa física (LGPD). Não é burocracia: é a
  contrapartida de tudo o que está no §3.
- **`/privacidade/o-que-aparece-de-voce`** — a lista do §3.2 em português comum,
  para o marmiteiro. É o link que a gente manda quando ele pergunta.

### Não construir

- **Mapa ao vivo no site.** Expõe pino, é lento no 4G e canibaliza o app.
- **Login, cadastro ou área do marmiteiro no site.** Decidido na issue.
- **Busca por texto livre.** Sem volume, uma busca que devolve vazio é pior que
  não ter busca. Bairro resolve.
- **Blog / receitas.** Só quando alguém for escrever de verdade.

### Infraestrutura de site que não é página

- `robots.txt` liberando tudo, menos `/m/*/agora` e `/m/*/zap`.
- `sitemap.xml` com as páginas de marmiteiro (só as com `public_page = true`) e
  as de bairro, com `lastmod` de `updated_at`.
- 404 e 500 com texto nosso, em português — a página de erro padrão do Rails em
  inglês num site de marmita é um vazamento de que ninguém cuidou.

---

## 5. Como a gente escreve

Palavras que a gente usa: **marmiteiro, marmita, quentinha, prato, cardápio da
semana, ponto, freguesia, zap, "cheguei"**.

Palavras que **não** entram no site: usuário, plataforma, solução, produtor,
estabelecimento, parceiro, "explore", "descubra", "gerencie", "otimize".

Três regras:

1. **Preço com R$ e sem centavo quando é redondo.** "R$ 18", não "R$ 18,00".
2. **Hora do jeito que se fala.** "chegou às 10h32", não "10:32:00".
3. **O botão diz o que acontece quando aperta.** "Chamar no zap", não "Entrar em
   contato". "Baixar o app", não "Saiba mais".

E o erro nunca culpa quem está lendo: "Deu ruim aqui do nosso lado", não
"Requisição inválida".

---

## 6. Direção visual — os tokens do app viram Tailwind

A fonte da verdade hoje é `apps/mobile/src/constants/index.ts`. O site tem que
parecer a mesma marca, então os tokens são os mesmos — **com uma correção de
contraste que o app também precisa aplicar**.

### 6.1 O problema do laranja

`COLORS.primary` é `#FF6B35`. Contra branco ele dá **2,83:1** — reprova em WCAG
AA (4,5:1) para texto normal e reprova até para texto grande (3:1). Contra o
`text` `#2E2E2E` ele dá 7,4:1.

Ou seja: **o laranja da marca é fundo, nunca texto pequeno.** Fundo laranja pede
texto escuro, não branco. Para os lugares onde o laranja precisa ser texto ou
fundo com texto branco (link, botão primário), entra um `brand-forte` mais
escuro, `#C2410C`, que dá **5,05:1** contra branco.

Mesma conta reprova o `danger` `#EF476F` (3,62:1) como texto: mensagem de erro
usa `#B3243F`. E o `textLight` `#6E6E6E` passa (5,14:1) — pode continuar sendo
texto secundário.

Isso não é preciosismo: o público lê essa tela **na rua, com sol na tela**, que
é o pior caso de contraste que existe.

### 6.2 `app/assets/tailwind/application.css`

Mesma estrutura de `benevoles`: `@theme` com `--color-*: initial` para apagar a
paleta default do Tailwind — assim `bg-red-500` deixa de existir como classe e
"nenhuma view usa cor solta" vira impossível de quebrar por distração.

```css
@import "tailwindcss";

:root {
  --brand:        #FF6B35;  /* fundo. Texto por cima: --ink */
  --brand-forte:  #C2410C;  /* texto e botão com texto branco (5,05:1) */
  --brand-suave:  #FFF1EA;  /* faixas e realces */
  --azul:         #004E89;  /* COLORS.secondary */
  --verde:        #06D6A0;  /* "vendendo agora". Fundo, com --ink por cima */
  --amarelo:      #FFD23F;
  --vermelho:     #EF476F;  /* fundo/borda */
  --vermelho-forte: #B3243F;/* texto de erro */

  --papel:  #FFFFFF;  /* COLORS.card */
  --fundo:  #F7F7F7;  /* COLORS.background */
  --ink:    #2E2E2E;  /* COLORS.text */
  --ink-fraco: #6E6E6E; /* COLORS.textLight */
  --borda:  #E0E0E0;  /* COLORS.border */
}

@theme {
  --color-*: initial;
  --color-papel: var(--papel);
  --color-fundo: var(--fundo);
  --color-ink: var(--ink);
  --color-ink-fraco: var(--ink-fraco);
  --color-borda: var(--borda);
  --color-brand: var(--brand);
  --color-brand-forte: var(--brand-forte);
  --color-brand-suave: var(--brand-suave);
  --color-verde: var(--verde);
  --color-amarelo: var(--amarelo);
  --color-vermelho: var(--vermelho);
  --color-vermelho-forte: var(--vermelho-forte);
  --color-azul: var(--azul);

  --radius-*: initial;
  --radius: 8px;   /* 12 das 20 ocorrências de borderRadius no app são 8 */
  --radius-lg: 16px;
}
```

**Espaçamento não precisa de token novo.** `SPACING` é 4 / 8 / 16 / 24 / 32, que
é exatamente a escala padrão do Tailwind (`1 / 2 / 4 / 6 / 8`). A regra é só
proibir valor arbitrário: nada de `p-[13px]`.

**Tipografia.** `FONT_SIZES` (12/14/16/18/24/32) mapeia em `text-xs / text-sm /
text-base / text-lg / text-2xl / text-3xl`. Corpo em 16px com `line-height: 1.6`,
igual ao `benevoles`.

**Fonte: nenhuma fonte externa no primeiro release.** O app não carrega fonte
nenhuma hoje — usa a do sistema. Copiar isso deixa o site idêntico ao app e
economiza 60–120 KB numa conexão 4G ruim, que é a de quem está na rua. Se um dia
entrar fonte de marca, ela entra nos dois ao mesmo tempo.

### 6.3 Componentes

ViewComponent, como em `benevoles` (`app/components/`). O mínimo para as páginas
acima, e nada além disso:

`ButtonComponent` · `CardMarmiteiroComponent` · `CardPratoComponent` ·
`BadgeStatusComponent` ("vendendo agora" / "fechado") · `EstrelasComponent` ·
`AvaliacaoComponent` · `EmptyStateComponent` · `PageHeaderComponent`.

Regras herdadas do CLAUDE.md do app, que valem igual no site: alvo de toque de
**44 px** (`min-h-11`), foco sempre visível, e nenhum texto que quebre quando o
sistema está com fonte grande.

---

## 7. O que os models não entregam

Cada item aqui é issue de backend, não suposição minha. Os quatro primeiros
**bloqueiam** as páginas do §4.

1. **Não existe `slug`.** `seller_profiles` não tem coluna de slug. Sem ela a URL
   é `/m/42` — que o marmiteiro não manda no zap e o Google não entende.
   **Falta:** `slug` único, gerado de `business_name`, com redirecionamento
   quando ele muda o nome.

2. **Não existe bairro em lugar nenhum.** Só há `seller_profiles.city/state` e
   `selling_locations.address`, que é texto livre. Toda a camada de descoberta
   por lugar (§4 P1) e a decisão de privacidade do §3.2 dependem de bairro.
   **Falta:** `selling_locations.neighborhood`, preenchido por geocodificação
   reversa no save (o gem `geocoder` já está no Gemfile), mais um normalizador de
   cidade para as URLs.

3. **Não existe consentimento de página pública.** Nada no schema diz que o
   marmiteiro concordou em ter uma página na internet aberta.
   **Falta:** `seller_profiles.public_page` (booleano, `default: true` — §8), o
   controle no perfil e o aviso no cadastro, tudo no mesmo PR (§3.5).

4. **Ninguém é `verified`, e não existe como verificar.** `verified` nasce
   `false` (migration `20251107212103`) e toda a descoberta filtra por ele; o
   namespace admin só tem avaliações. **Se o site usar o mesmo filtro, ele nasce
   vazio.** Já levantado em `apps/mobile/UX_MARMITEIRO.md` §5.12 — e agora
   bloqueia as duas pontas. **Falta:** decidir o que `verified` significa e um
   jeito de virar a chave.

5. **`operating_hours` é um jsonb sem formato.** Nasce `{}`, nenhum código lê ou
   escreve. A página quer dizer "costuma vender de 11h às 14h" e não tem de onde
   tirar. Também não dá para inferir: a tabela `activity_logs` é um `TODO` no
   `SellerProfile`, nada registra chegada. **Falta:** definir o formato, ou
   registrar as chegadas e derivar daí. Enquanto não existir, a página omite o
   horário — não inventa.

6. **A API pública vaza mais do que o site vai mostrar.**
   `GET /api/v1/sellers/:id` responde **sem autenticação** e devolve `phone`,
   `whatsapp` e **todos** os `selling_locations` com latitude e longitude exatas
   — inclusive os pontos onde ele não está agora. É o mapa dos lugares onde uma
   pessoa costuma estar, aberto para qualquer um com `curl`. Isso é bug de
   privacidade **independente do site**, e precisa ser consertado antes, senão a
   decisão do §3 fica valendo só no HTML.

7. **Não existe preço "a partir de".** As listas do §4 mostram o menor preço do
   marmiteiro; hoje isso é um `MIN(dishes.base_price)` por marmiteiro, com N+1
   garantido numa lista de 20. **Falta:** um `min_price` denormalizado ou uma
   consulta agregada — decisão de quem implementar, não bloqueia o desenho.

8. **Nome público de quem avalia.** O model só tem `user.name` inteiro (§3.4).
   Um helper de view resolve; não precisa de coluna.

9. **Foto não tem URL estável para og:image.** `config.active_storage.service` é
   `:local` em produção e não há `asset_host`. As URLs padrão de Active Storage
   são assinadas e **expiram** — e o WhatsApp e o Google guardam a `og:image` por
   dias. A prévia do link quebra sozinha depois de um tempo. **Falta:**
   `resolve_model_to_route = :rails_storage_proxy` (URL estável e cacheável), ou
   um serviço público de verdade. Também não há variante 1200×630 gerada.

10. **O Rails ainda é `api_only`.** `config.api_only = true`,
    `ApplicationController < ActionController::API`, e o Gemfile não tem
    `propshaft`, `importmap-rails`, `turbo-rails`, `stimulus-rails`,
    `tailwindcss-rails` nem `view_component`. Não existe `layouts/application`.
    Nada disso é surpresa — é a primeira tarefa da etapa 4, e as rotas de
    `api/v1` não são tocadas.

---

## 8. A decisão, tomada

**A página pública do marmiteiro nasce ligada**, com chave para desligar no app.
Rafael, 07/09/2026.

Todo marmiteiro que se cadastra ganha página e é achável no Google — que é o
motivo pelo qual ele se cadastrou. Quem não quiser, desliga em um toque.

O que isso obriga, e que não é negociável junto com a decisão:

- o aviso no cadastro, antes de existir página (§3.5, item 1);
- a chave visível no perfil, com link para ver a própria página (§3.5, item 2);
- `/privacidade/o-que-aparece-de-voce` no ar **antes** do primeiro `sitemap.xml`.
  Publicar primeiro e explicar depois é a ordem errada.

Um marmiteiro que já existe hoje no banco vira `public_page = true` na migration.
Ele também não combinou nada — então o aviso do item 1 tem que aparecer para ele
na primeira vez que abrir o app depois disso, não só para quem se cadastrar
daqui para frente.

---

## 9. Ordem de implementação

1. Tirar o `api_only`, adicionar Hotwire, Tailwind e ViewComponent, layout e as
   páginas de erro. Nada abaixo existe sem isso (§7.10).
2. `slug` e `public_page` (§7.1, §7.3) — e o consentimento no app junto, não
   depois.
3. `/m/:slug` inteira, com o Turbo Frame do "agora" já com `noindex` e a trava do
   `leaving_at` (§3.6). É a página que sustenta todas as outras.
4. Consertar o vazamento de `GET /api/v1/sellers/:id` (§7.6). Antes de qualquer
   página ir para o ar.
5. `neighborhood` (§7.2) e as páginas de bairro.
6. `/vender`, `/`, `/app`.
7. Privacidade, termos e "o que aparece de você".
8. `sitemap.xml`, `robots.txt`, og:image estável (§7.9).

Enquanto `verified` (§7.4) não for resolvido, **todas as páginas de descoberta
nascem vazias** — a de bairro, a home e a lista de "vendendo agora". A página
individual do marmiteiro funciona sem isso, e por isso ela é a primeira.

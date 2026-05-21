# Marmitas.top V0 Launch - Full Implementation Plan
**Target:** Complete V0 MVP for both iOS and Android  
**Timeline:** 4 weeks (20 working days)  
**Status:** PLANNING - Awaiting Plan agent completion for Orders system details

---

## Context

### Why This Change Is Needed

Marmitas.top is a location-based food marketplace connecting home cooks (marmiteiros/sellers) with consumers seeking affordable homemade meals. The platform currently has **65% completion** with core features implemented:

**What's Working:**
- ✅ Authentication & user management (JWT, Devise)
- ✅ Geospatial search with PostGIS (nearby sellers)
- ✅ Menu & dish management system
- ✅ Location broadcasting ("I'm here!" feature)
- ✅ Favorites system (polymorphic)
- ✅ Push notification infrastructure
- ✅ Reviews & ratings (weighted, anti-gaming)
- ✅ Mobile app UI (consumer screens mostly complete)

**What's Blocking Launch:**
- ❌ **Orders/Purchases system** - No way to place or track orders
- ❌ **Seller mobile app** - Sellers can't manage business from phone
- ❌ **Deployment** - Nothing is live in production
- ❌ **Mobile builds** - No APK/IPA builds available

The Orders system is the **critical blocker** - without it, consumers can browse but cannot transact, and sellers have no order management. This plan addresses that gap and completes remaining V0 requirements.

### Success Criteria

At V0 launch, the platform must enable:
1. Consumers to discover sellers → browse menus → place orders → track status
2. Sellers to post menus → receive orders → update status → manage inventory
3. Platform operators to moderate content and verify sellers
4. Both platforms (iOS + Android) deployed to app stores

**Target Metrics:**
- 10 marmiteiros onboarded and actively posting menus
- 50 consumers browsing and placing orders  
- 5+ weekly menu posts sustained

---

## Implementation Roadmap

### Week 1: Orders Backend + Activity Logs (5 days)

**Priority: CRITICAL** 🔴

#### Day 1-2: Orders/Purchases System Backend

**Additional Features Required:**

1. **Delivery Fee System**
   - Add delivery_fee (decimal) to orders table
   - Add offers_delivery (boolean) to seller_profiles
   - Add delivery_fee_amount to seller_profiles
   - Total = items subtotal + delivery_fee (if applicable)

2. **Validation Code for Completion**
   - Add completion_code (string, 6 digits) to orders table
   - Generated on order creation, shown to seller
   - Consumer must enter code to mark order completed
   - New endpoint: POST /orders/:id/complete with validation_code param

3. **Auto-Cancel When Broadcast Expires**
   - Background job checks for pending orders where seller.leaving_at < Time.current
   - Auto-cancel those orders, restore quantities, notify customer
   - Run job every 5 minutes via cron/scheduler

4. **Cart Abandonment Warning**
   - Frontend: detect navigation away from seller with non-empty cart
   - Show confirmation dialog: "Você tem itens no carrinho. Deseja abandoná-los?"
   - Clear cart only if confirmed

5. **Geographic Order Restriction**
   - Validate customer location within seller's discovery_radius at checkout
   - Return error if customer too far from seller's current location
   - Frontend: show warning if user moving out of range

6. **Cold Storage for Old Orders**
   - Add archived_at (datetime) to orders table
   - Background job moves orders older than 3 months to archived status
   - Archived orders excluded from default queries but retrievable

**Database Schema:**

**orders** table:
- user_id (references users, indexed)
- seller_profile_id (references seller_profiles, indexed)
- weekly_menu_id (optional reference)
- status (string, default 'pending', check constraint)
- total_price (decimal 10,2) - includes delivery_fee if applicable
- delivery_fee (decimal 10,2, default 0)
- completion_code (string, 6 chars) - for customer validation
- order_date (datetime, default current_timestamp, indexed)
- confirmed_at, ready_at, completed_at, cancelled_at, archived_at (datetime)
- cancellation_reason (text)
- seller_location_name, seller_latitude, seller_longitude (snapshot)
- customer_latitude, customer_longitude (for distance verification)
- Composite indexes: [user_id, order_date], [seller_profile_id, status], [seller_profile_id, order_date]
- Check constraint: status IN ('pending', 'confirmed', 'ready', 'completed', 'cancelled')

**seller_profiles** additions:
- offers_delivery (boolean, default false)
- delivery_fee_amount (decimal 10,2)

**order_items** table:
- order_id (references orders, indexed)
- dish_id (references dishes, indexed)
- weekly_menu_dish_id (optional reference)
- quantity (integer, check > 0)
- unit_price (decimal 10,2)
- subtotal (decimal 10,2)
- dish_name_snapshot, dish_description_snapshot (for historical accuracy)

**Counter cache columns:**
- seller_profiles: total_orders_count, completed_orders_count
- users: orders_count

**Models:**

**Order** (backend/app/models/order.rb):
- Associations: user, seller_profile, weekly_menu (optional), order_items, dishes (through order_items)
- Validations: status inclusion, total_price > 0, order_date presence
- Custom validations: cannot_order_from_self, seller_must_be_active, must_have_order_items, total_matches_items_sum, cannot_cancel_after_window
- Scopes: pending, confirmed, ready, completed, cancelled, active, recent, for_user, for_seller, today
- Callbacks:
  - before_validation: set_order_date, snapshot_seller_location
  - before_create: decrement_quantities!
  - after_update: increment_completed_counter (if completed)
  - after_destroy: restore_quantities!
- State methods: confirm!, mark_ready!, complete!, cancel!(reason)
- Query methods: can_cancel?, within_cancellation_window?, editable_by?(user)

**OrderItem** (backend/app/models/order_item.rb):
- Associations: order, dish, weekly_menu_dish (optional)
- Validations: quantity > 0, unit_price > 0, subtotal > 0, dish_name_snapshot presence
- Callbacks:
  - before_validation: calculate_subtotal, snapshot_dish_data

**Controllers & Routes:**

**Api::V1::OrdersController** (consumer endpoints):
- GET /orders (index with filters, pagination)
- GET /orders/:id (show with items)
- POST /orders (create with transaction, quantity validation)
- DELETE /orders/:id/cancel (cancel with quantity restore)

**Api::V1::Seller::OrdersController** (seller endpoints):
- GET /seller/orders (index with stats, filters: pending/active/completed/today)
- GET /seller/orders/:id (show with customer details)
- PATCH /seller/orders/:id/update_status (confirm/ready/complete transitions)

**Background Jobs:**
- NotifySellerNewOrderJob (push notification on new order)
- NotifyCustomerOrderUpdateJob (push notification on status change)
- AutoCancelExpiredOrdersJob (cancels pending orders when seller broadcast expires)
- ArchiveOldOrdersJob (moves 3+ month old orders to archived status)

**Business Logic:**
- Atomic quantity reservations via database transactions with row locking
- 30-minute cancellation window (configurable constant Order::CANCELLATION_WINDOW)
- Status workflow: pending → confirmed → ready → completed (via validation code)
- Seller must have currently_active = true at order creation
- Customer must be within seller's discovery_radius at checkout
- Quantities auto-restored on cancellation or order destruction
- Total price = items subtotal + delivery_fee (if seller offers_delivery)
- Location snapshot (seller + customer) captured at order creation time
- Completion requires customer entering 6-digit validation code
- Pending orders auto-cancel if seller's broadcast expires (leaving_at passes)
- Orders older than 3 months automatically archived (soft delete)

**Files to Create:**
```
backend/db/migrate/[timestamp]_create_orders.rb
backend/db/migrate/[timestamp]_create_order_items.rb
backend/app/models/order.rb
backend/app/models/order_item.rb
backend/app/controllers/api/v1/orders_controller.rb
backend/app/controllers/api/v1/seller/orders_controller.rb
```

**Files to Modify:**
```
backend/config/routes.rb (add order routes)
backend/app/models/user.rb (add has_many :orders)
backend/app/models/seller_profile.rb (add has_many :orders, counter_cache)
backend/app/models/weekly_menu_dish.rb (add quantity management methods if missing)
```

#### Day 3: Activity Logs & Image Uploads

**Activity Logs:**
- Create `ActivityLog` model
- Track: seller arrivals, departures, menu posts, sold out events
- API endpoint: `GET /api/v1/seller/activity_logs`

**Image Uploads:**
- Uncomment S3 in `config/storage.yml`
- Create upload endpoints for profile photos, dish photos
- Add image processing (resize, optimize)

**Files to Create:**
```
backend/app/models/activity_log.rb
backend/app/controllers/api/v1/seller/activity_logs_controller.rb
backend/app/controllers/api/v1/uploads_controller.rb
```

#### Day 4-5: Admin Panel Backend

**Admin Endpoints:**
- User management (list, verify seller, suspend/ban)
- Platform statistics
- Seller verification workflow
- Reports handling

**Files to Create:**
```
backend/app/controllers/api/v1/admin/users_controller.rb
backend/app/controllers/api/v1/admin/sellers_controller.rb
backend/app/controllers/api/v1/admin/stats_controller.rb
```

---

### Week 2: Seller App + Admin Polish (5 days)

**Priority: CRITICAL** 🔴

#### Day 6-8: Seller Mobile App Screens

**Navigation**: Add seller tab navigator with Home, Orders, Menu, Stats tabs

**Screens to Build:**
1. **Seller Dashboard** (home)
   - Quick stats (orders today, revenue, active followers)
   - Quick actions: Post Menu, I'm Here, View Orders
   - Recent activity feed

2. **Post Menu Screen**
   - Form: select dishes, set quantities, prices
   - Duplicate from previous menu
   - WhatsApp share button

3. **Manage Dishes Screen**
   - CRUD for seller's dish catalog
   - Photo upload
   - Dietary tags

4. **Announce Location Screen**
   - Map with saved locations
   - "I'm Here" button with duration picker
   - "I'm Leaving" button

5. **Incoming Orders Screen**
   - List orders by status (pending, confirmed, ready)
   - Status update buttons
   - Order details modal

6. **Business Stats Screen**
   - Charts: revenue, orders over time
   - Rating distribution
   - Top dishes

**Files to Create:**
```
frontend/src/screens/seller/SellerDashboardScreen.tsx
frontend/src/screens/seller/PostMenuScreen.tsx
frontend/src/screens/seller/ManageDishesScreen.tsx
frontend/src/screens/seller/AnnounceLocationScreen.tsx
frontend/src/screens/seller/IncomingOrdersScreen.tsx
frontend/src/screens/seller/StatsScreen.tsx
frontend/src/components/OrderCard.tsx
frontend/src/components/DishForm.tsx
```

**Files to Modify:**
```
frontend/src/navigation/AppNavigator.tsx (add seller tab navigator)
frontend/src/services/api.ts (add seller endpoints)
frontend/src/types/index.ts (add Order, OrderItem types)
```

#### Day 9-10: Polish Admin Features

- Complete admin moderation UI
- Seller verification checklist
- Platform analytics dashboard

---

### Week 3: Consumer Orders UI + Reviews (5 days)

**Priority: CRITICAL** 🔴

#### Day 11-12: Consumer Orders Flow

**State Management**: CartContext using React Context + AsyncStorage for persistence

**Cart Business Rules:**
- Cart tied to single seller (changing seller clears cart)
- Items stored with: weekly_menu_dish_id, dish_id, dish_name, unit_price, quantity, remaining_quantity
- Cart persisted to AsyncStorage for offline recovery
- Total recalculated on every cart modification
- Quantity limits enforced: cannot exceed remaining_quantity

**Checkout Flow:**
1. Frontend validates cart (non-empty, seller still active)
2. POST /api/v1/orders with { seller_profile_id, items: [{weekly_menu_dish_id, quantity}] }
3. Backend validates quantities available inside transaction
4. Backend creates Order + OrderItems atomically
5. Backend decrements WeeklyMenuDish.remaining_quantity
6. Backend triggers push notification to seller
7. Frontend clears cart and navigates to OrderDetail

**Screens to Build:**
1. **Menu Browse with Add to Cart**
   - Modify SellerDetailScreen to show menu items
   - Quantity selector component
   - "Add to Cart" button

2. **Cart Screen**
   - List cart items with quantities
   - Update quantity, remove items
   - Total price calculation
   - "Checkout" button

3. **Checkout Screen**
   - Review order summary
   - Add notes/special requests
   - Confirm location is nearby
   - "Place Order" button

4. **Order History Screen**
   - List user's orders (grouped by status)
   - Filter by status
   - Tap to see order details

5. **Order Detail Screen**
   - Order items list
   - Status timeline
   - Seller info
   - Cancel button (if within window)
   - "Leave Review" button (if completed)

**Files to Create:**
```
frontend/src/screens/CartScreen.tsx
frontend/src/screens/CheckoutScreen.tsx
frontend/src/screens/OrderHistoryScreen.tsx
frontend/src/screens/OrderDetailScreen.tsx
frontend/src/components/CartItem.tsx
frontend/src/components/OrderStatusBadge.tsx
frontend/src/contexts/CartContext.tsx (optional: persist cart)
```

**Files to Modify:**
```
frontend/src/screens/SellerDetailScreen.tsx (add cart functionality)
frontend/src/navigation/AppNavigator.tsx (add order screens to stack)
frontend/src/services/api.ts (add order endpoints)
```

#### Day 13: Reviews UI

**Components to Build:**
- Write Review screen
- Rating stars component (reusable)
- Review list with helpful voting
- Flag review button

**Files to Create:**
```
frontend/src/screens/WriteReviewScreen.tsx
frontend/src/components/StarRating.tsx
frontend/src/components/ReviewCard.tsx
```

---

### Week 4: Deployment + Launch (5 days)

**Priority: CRITICAL** 🔴

#### Day 14-15: Backend Deployment

**Infrastructure Setup:**
1. **Railway/Render Deployment**
   - Create project on Railway
   - Connect GitHub repository
   - Configure environment variables:
     ```
     DATABASE_URL=postgresql://...
     REDIS_URL=redis://...
     JWT_SECRET_KEY=...
     SECRET_KEY_BASE=...
     FCM_SERVER_KEY=...
     AWS_ACCESS_KEY_ID=...
     AWS_SECRET_ACCESS_KEY=...
     S3_BUCKET=marmitas-top-production
     RAILS_ENV=production
     ```
   - Run migrations automatically
   - Set up health checks

2. **PostgreSQL + Redis**
   - Provision PostgreSQL with PostGIS extension
   - Provision Redis instance (if using Action Cable)
   - Configure connection pooling

3. **S3 Bucket**
   - Create bucket for image storage
   - Configure CORS for uploads
   - Set lifecycle policies for thumbnails

4. **Domain Setup**
   - Point api.marmitas.top to Railway
   - Configure SSL certificates (automatic on Railway)
   - Set up rate limiting

5. **Monitoring**
   - Configure Sentry for error tracking
   - Set up logging aggregation
   - Create uptime monitoring (UptimeRobot)

**Files to Create:**
```
backend/railway.json (or render.yaml)
backend/.env.production.example
backend/config/initializers/fcm.rb
```

**Files to Modify:**
```
backend/config/storage.yml (activate S3)
backend/config/environments/production.rb (configure storage)
backend/Dockerfile (add migration step)
```

#### Day 16-17: Mobile App Builds

**Android Build:**
1. Configure app.json for production
   - Update app name, bundle ID, version
   - Add app icons and splash screen
   - Configure permissions (location, camera, notifications)

2. Build signed APK/AAB:
   ```bash
   eas build --platform android --profile production
   ```

3. Upload to Google Play Console (closed alpha)
4. Create store listing (screenshots, description)

**iOS Build:**
1. Configure iOS-specific settings
2. Build for TestFlight:
   ```bash
   eas build --platform ios --profile production
   ```
3. Upload to App Store Connect
4. Submit for TestFlight review

**Files to Modify:**
```
frontend/app.json (production config)
frontend/eas.json (build profiles)
frontend/src/constants/index.ts (production API URL)
```

**Files to Create:**
```
frontend/assets/icon.png (1024x1024 app icon)
frontend/assets/splash.png
frontend/assets/adaptive-icon.png (Android)
```

#### Day 18: QA Testing

**End-to-End Test Scenarios:**
1. Consumer flow:
   - Register → Browse sellers → Favorite seller
   - Receive notification → View menu → Add to cart
   - Checkout → Place order → Track status
   - Complete order → Leave review

2. Seller flow:
   - Register → Create profile → Get verified
   - Post menu → Announce location
   - Receive order → Update status → Complete
   - View stats

3. Edge cases:
   - Concurrent orders on last item
   - Order cancellation and quantity restore
   - Seller goes offline mid-order
   - Location permission denied

**Files to Create:**
```
QA_CHECKLIST.md (testing scenarios)
```

#### Day 19: Soft Launch

- Invite 5-10 beta testers (sellers + consumers)
- Monitor logs for errors
- Gather feedback
- Fix critical bugs

#### Day 20: Public Launch

- Publish to Google Play Store (production)
- Submit to Apple App Store (review)
- Launch marketing (social media, local groups)
- Monitor metrics

---

## Design Decisions & Business Rules

### Business Rules (Resolved)

1. **Order Cancellation**: ✅ 30-minute window from order_date (configurable constant)
2. **Multiple Sellers**: ✅ No - one order = one seller (cart clears when switching sellers)
3. **Minimum Order**: ✅ No minimum for MVP (can add later per seller)
4. **Auto-Confirm**: ✅ Manual - seller must explicitly confirm orders
5. **Quantity Limits**: ✅ No hard max per order; per-dish limited by remaining_quantity
6. **Status Transitions**: ✅ Linear flow - pending (customer) → confirmed (seller) → ready (seller) → completed (seller)
7. **Notifications**: ✅ Push on every status change (new order, confirmed, ready, completed)
8. **Order Retention**: ✅ Keep all orders (no soft delete) - cancelled orders retained for history/analytics
9. **Disputes**: ⏸️ Manual for MVP - customer contacts seller via phone/WhatsApp (future: dispute resolution flow)
10. **Location Verification**: ✅ Snapshot seller location at order time; no geo-fence enforcement on customer

### Technical Decisions (Resolved)

1. **Cart Storage**: ✅ Client-only with AsyncStorage persistence (no backend cart sync for MVP)
2. **Concurrency**: ✅ Pessimistic locking - use database transactions with row locks on quantity updates
3. **Order Numbers**: ✅ Auto-increment ID (simple for MVP; future: custom format with prefix)
4. **Decimal Precision**: ✅ 2 decimals (10,2) for all prices; format as "R$ X,XX" in display
5. **Soft Delete**: ✅ No soft delete for orders - keep all records permanently
6. **Real-time**: ⏸️ Polling for MVP (pull-to-refresh); Action Cable for V1
7. **Payment Future**: ✅ No payment integration in schema - add payment_status, payment_method columns later

### Finalized Requirements from User

✅ **Concurrent Orders**: No limit - multiple customers can order from same seller simultaneously  
✅ **Order Acceptance**: Seller MUST manually confirm orders (they check if can fulfill)  
✅ **Pending Order Timeout**: Auto-cancel if seller doesn't respond before broadcast expires (leaving_at)  
✅ **Response Time**: Track average seller confirmation time  
✅ **Order Notes**: Not allowed - simple ordering only  
✅ **Minimum Order**: 1 item (seller can set delivery fee if they deliver in area)  
✅ **Single Seller Cart**: Yes - if navigating away with cart, ask to confirm abandoning  
✅ **Order Completion**: Consumer enters validation code to mark completed (like iFood)  
✅ **Notifications**: App-only push notifications (WhatsApp later)  
✅ **Order Retention**: 3 months fresh, then cold storage (soft delete always)  
✅ **Dispute Handling**: Platform stays out - just intermediary, no money handling yet  
✅ **Order Geography**: Orders only available within seller's discovery range  
✅ **Cart Storage**: Client-only with AsyncStorage (broadcast is ephemeral)  
✅ **Concurrency**: Pessimistic locking on order creation (simple solution)  
✅ **Order Numbers**: Auto-generated integer IDs  
✅ **Currency**: BRL (R$) - but design system for future multi-currency  
✅ **Max Items**: Determined on product level by seller (remaining_quantity)

---

## User Journey Scenarios (Happy Path)

### Scenario 1: Seller - First Day with Online Orders

**Actor**: Maria, home cook selling marmitas for the first time

**Setup Phase** (One-time):
1. Maria downloads Marmitas.top app from Play Store
2. Signs up with phone number (SMS verification)
3. Taps "Vender Marmitas" to create seller profile
4. Fills profile: Business name "Marmitas da Maria", photo, bio, WhatsApp
5. Adds her signature dishes to catalog:
   - Feijoada completa (R$ 15)
   - Frango grelhado com legumes (R$ 12)
   - Strogonoff de carne (R$ 14)
   - Each with photo, description, dietary tags
6. Admin reviews and verifies her profile (within 24h)

**Daily Routine** (Every work day):

**Morning - Prep (8:00 AM)**:
1. Maria opens app, sees her seller dashboard
2. Taps "Postar Cardápio" (Post Menu)
3. Selects today's dishes from her catalog:
   - Feijoada (20 marmitas available)
   - Frango grelhado (15 marmitas available)
4. Confirms prices, adds note: "Pronto às 11h!"
5. Taps "Publicar Cardápio"
6. System sends push notifications to her 23 followers

**Mid-Morning - Travel (10:30 AM)**:
1. Maria packs her cooler with 35 marmitas
2. Drives to her usual spot (Praça da República)
3. Parks and sets up her table

**Arrival - Broadcast (10:50 AM)**:
1. Opens app, taps "Estou Aqui!" (I'm Here!)
2. Selects saved location: "Praça da República - Esquina Rua Aurora"
3. Sets duration: "Até 14:00" (4 hours)
4. Confirms broadcast
5. System updates her profile: currently_active = true, leaving_at = 14:00
6. System sends push to nearby users within 2km radius: "Marmitas da Maria está próxima!"

**First Hour - In-Person Sales (11:00-12:00)**:
1. Regular customer João approaches: "Quero uma feijoada!"
2. Maria serves him, receives R$ 15 cash
3. Maria manually reduces inventory in app:
   - Opens "Gerenciar Cardápio de Hoje"
   - Taps Feijoada, reduces from 20 → 19
4. System updates remaining_quantity in real-time
5. Customers browsing app see updated count: "19 disponíveis"

**First Online Order! (12:15 PM)**:
1. 🔔 Push notification: "Novo pedido #127!"
2. Maria taps notification, sees order details:
   - Customer: Ana Paula
   - Items: 2x Frango grelhado (R$ 24 total)
   - Status: Pendente confirmação
   - Pickup code: 847293
3. Maria checks her cooler - has 13 frangos left
4. Taps "Confirmar Pedido"
5. System sends push to Ana: "Seu pedido foi confirmado! Pronto em 5 min"
6. System auto-decrements: Frango 15 → 13

**Peak Time - Multiple Orders (12:30-13:30)**:
1. 🔔 New order #128: Carlos - 1x Feijoada
2. Maria confirms immediately
3. 🔔 New order #129: Beatriz - 2x Strogonoff... wait, she didn't bring strogonoff!
4. Maria taps order, sees she can't fulfill
5. Taps "..." menu → "Marcar Prato Esgotado"
6. Strogonoff changes to "Esgotado" on her menu
7. System auto-rejects Beatriz's order, refunds quantities, notifies her

**Pickup Flow - Ana Arrives (12:40 PM)**:
1. Ana approaches: "Tenho um pedido online"
2. Maria: "Qual o código?"
3. Ana checks app, reads: "847293"
4. Maria checks her order list, finds order #127
5. Hands Ana the 2 marmitas
6. Taps "Marcar como Pronto" (changes status to 'ready')
7. Ana pays R$ 24 cash
8. Ana opens her app, enters code 847293 in "Confirmar Retirada"
9. Order status → Completed
10. System prompts Ana: "Avaliar Marmitas da Maria?"

**End of Day - Going Home (14:00)**:
1. Maria taps "Estou Saindo" (I'm Leaving)
2. System broadcasts departure notification to nearby users
3. System sets currently_active = false
4. Any pending unconfirmed orders auto-cancel, quantities restored
5. Maria reviews her stats:
   - 28 marmitas sold (18 in-person, 10 online)
   - R$ 392 revenue
   - 4 online orders completed
   - 3 new followers
   - Current rating: ⭐ 4.8 (47 avaliações)

**Evening - Reviews (19:00)**:
1. 🔔 Push: "Ana Paula avaliou você!"
2. Maria reads: ⭐⭐⭐⭐⭐ "Frango delicioso, Maria é super simpática!"
3. Maria taps "Curtir" (acknowledge review)

---

### Scenario 2: Customer - First Online Order

**Actor**: Pedro, office worker discovering the app

**Discovery (12:00 PM - Lunch break)**:
1. Pedro feeling hungry, opens Marmitas.top app
2. App requests location permission → Allow
3. Home screen shows map with 4 active sellers nearby
4. Filters by "Disponível Agora"
5. Sees "Marmitas da Maria" - 800m away, ⭐ 4.8
6. Taps her pin on map

**Browsing (12:02 PM)**:
1. Seller detail screen loads:
   - Profile photo, business name, rating distribution
   - "Ativa agora em: Praça da República"
   - "Saindo às 14:00" (2h remaining)
   - Today's menu (2 items available)
2. Pedro scrolls to reviews - sees recent 5-star from Ana
3. Taps "Ver Cardápio de Hoje"

**Menu & Cart (12:05 PM)**:
1. Menu screen shows:
   - Feijoada completa - R$ 15 (12 disponíveis) ⭐ Popular
   - Frango grelhado - R$ 12 (13 disponíveis)
2. Pedro taps Feijoada → quantity selector appears
3. Selects quantity: 1
4. Taps "Adicionar ao Carrinho"
5. Toast: "Feijoada adicionada ao carrinho!"
6. Bottom bar shows: "🛒 1 item - R$ 15"

**Checkout (12:06 PM)**:
1. Pedro taps cart icon
2. Cart screen shows:
   - Marmitas da Maria
   - 1x Feijoada completa - R$ 15
   - Subtotal: R$ 15
   - (No delivery fee - pickup only)
   - Total: R$ 15
3. Taps "Finalizar Pedido"
4. Confirmation screen:
   - "Confirmar localização?" (map shows he's 800m away - within range ✓)
   - "Retirada em: Praça da República"
   - Payment: "Pagar na retirada (dinheiro/PIX)"
5. Taps "Confirmar Pedido"

**Order Placed (12:07 PM)**:
1. Loading spinner → Success!
2. "Pedido realizado! #130"
3. Shows order detail:
   - Status: Aguardando confirmação
   - Estimated ready: 15 min
   - Pickup code: 394751
   - Seller contact: WhatsApp button
4. Cart cleared automatically

**Waiting (12:10 PM)**:
1. 🔔 Push: "Marmitas da Maria confirmou seu pedido!"
2. Pedro taps notification
3. Order status updated: Confirmado → Pronto em 10 min
4. Pedro finishes current task, starts walking

**Pickup (12:25 PM)**:
1. Pedro arrives at Praça da República
2. Sees Maria's table with coolers
3. "Oi! Tenho um pedido online"
4. Maria: "Código?"
5. Pedro shows phone screen: "394751"
6. Maria hands him the marmita
7. 🔔 App shows: "Pronto para retirada!"
8. Pedro pays R$ 15 (PIX via Maria's QR code)
9. Maria marks as ready in her app
10. Pedro's app prompts: "Digite o código para confirmar retirada"
11. Pedro enters: 394751
12. ✓ Order completed!

**Post-Order (14:00 PM - Back at office)**:
1. 🔔 Push: "Como foi sua experiência com Marmitas da Maria?"
2. Pedro taps "Avaliar"
3. Rates ⭐⭐⭐⭐⭐ (5 stars)
4. Comments: "Feijoada muito boa! Atendimento rápido"
5. Taps "Enviar Avaliação"
6. App prompts: "Deseja seguir Marmitas da Maria?"
7. Pedro taps "Seguir" → will get notifications when she posts menus

**Next Day Discovery (Next day, 11:00 AM)**:
1. 🔔 Push: "Marmitas da Maria postou cardápio novo!"
2. Pedro taps → sees today's options
3. Orders again because yesterday was great

---

### Scenario 3: Edge Cases Handled Gracefully

**Case A: Seller Runs Out Mid-Day**:
1. Maria has 3 feijoadas left, shows "3 disponíveis"
2. Customer A adds 2 to cart → not yet ordered
3. Customer B adds 2 to cart → not yet ordered
4. Customer A hits checkout first (12:01:30.000)
5. System locks quantities, processes order → 3 becomes 1
6. Customer B hits checkout 2 seconds later (12:01:32.000)
7. System validates: wants 2, but only 1 remaining
8. Error: "Quantidade insuficiente para Feijoada (apenas 1 disponível)"
9. Customer B cart auto-updates to max available (1)
10. Customer B can checkout with 1, or remove item

**Case B: Seller Leaves Early**:
1. Maria's broadcast says "até 14:00"
2. At 13:30, she sold everything
3. Taps "Estou Saindo" early
4. System checks: 2 pending orders not yet confirmed
5. Dialog: "Você tem 2 pedidos pendentes. Cancelar tudo?"
6. Maria taps "Cancelar Pedidos e Sair"
7. System cancels both orders, restores quantities (already 0, no-op)
8. System notifies customers: "Vendedor encerrou atividade. Pedido cancelado."

**Case C: Customer Takes Too Long**:
1. João places order at 13:50 (Maria leaving at 14:00)
2. Maria doesn't see notification (busy)
3. 14:00 arrives, Maria's broadcast expires
4. AutoCancelExpiredOrdersJob runs (every 5 min)
5. Finds João's order: pending, seller.leaving_at passed
6. Auto-cancels order, restores quantity
7. Sends push to João: "Pedido cancelado - vendedor encerrou atividade"

**Case D: Customer Wants to Cancel**:
1. Ana places order at 12:00
2. At 12:10, she needs to cancel (meeting came up)
3. Opens order detail, taps "Cancelar Pedido"
4. Confirms cancellation
5. System restores quantities: Frango 13 → 15
6. Ana sees: "Pedido cancelado. Você pode fazer um novo pedido a qualquer momento."
7. At 12:35, Ana tries to cancel different order
8. Error: "Não é possível cancelar após 30 minutos"

**Case E: Fraudulent Validation Code**:
1. Malicious user Carlos places order (code: 582910)
2. Carlos tells friend Bruno: "Hey, pick up my order with code 582910"
3. Bruno goes to Maria, says code 582910
4. Maria marks order as ready
5. Bruno tries to enter code in his own app
6. Error: "Este código pertence a outro pedido"
7. Only Carlos's app can validate with that code (tied to user_id)

---

### Scenario 4: Seller Growth Over Time

**Week 1**: Maria makes R$ 420/week (30 marmitas sold, mostly in-person)
**Week 2**: 8 followers, R$ 680/week (48 marmitas, 30% online orders)
**Week 4**: 23 followers, R$ 1,120/week (80 marmitas, 50% online orders)
**Month 3**: 67 followers, ⭐ 4.9 rating (89 reviews), R$ 1,800/week
- Maria now preps more because she can predict demand
- She added delivery option (R$ 3 fee within 1km)
- Her feijoada is "top dish" in the area
- Customers pre-order before she even broadcasts

**Virtuous Cycle**:
1. Great food → 5-star reviews
2. Reviews → higher discovery ranking
3. Ranking → more followers
4. Followers → predictable demand
5. Demand → ability to prep more
6. More revenue → can invest in better ingredients
7. Better ingredients → even better food → loop continues

---

## Summary of Happy Path Journeys

**Seller Daily Routine**:
Prep → Post Menu → Travel → Broadcast "I'm Here" → Serve in-person + accept online orders → Mark items sold out when needed → Hand orders to customers → Customer validates pickup → End day "I'm Leaving" → Review stats

**Customer Journey**:
Discover nearby seller → Browse menu → Add to cart → Checkout → Wait for confirmation → Go to pickup location → Show code → Receive order → Pay seller directly → Validate pickup in app → Leave review

**Platform Role**:
- Discovery (geolocation)
- Inventory management (quantities)
- Order coordination (status flow)
- Quality signals (reviews)
- Notifications (push)
- Does NOT handle: payments, disputes, delivery logistics

**Success Metrics**:
- Seller: Revenue, followers, rating, repeat customers
- Customer: Fast discovery, reliable inventory, quality food
- Platform: GMV (gross merchandise value), active sellers, order completion rate



**Philosophy**: Platform is just intermediary - no money handling, minimal dispute resolution.

**Recommendation for MVP**:

1. **No Built-in Dispute System**
   - Customers and sellers resolve issues directly (phone/WhatsApp)
   - Platform only provides contact information
   - No escrow, no refunds, no mediation

2. **Quality Signals Instead**
   - Reviews system (already implemented) surfaces bad actors
   - Weighted ratings with anti-gaming (already implemented)
   - Flag review for admin attention (already implemented)

3. **Admin Actions Only for Extreme Cases**
   - Ban user accounts (malicious behavior)
   - Ban seller accounts (repeated issues)
   - Remove fraudulent reviews
   - No financial dispute resolution

4. **Future V1 Additions** (only if necessary):
   - Report button on orders (category: "Não recebi", "Problema com pedido", etc.)
   - Admin dashboard shows order reports
   - Admin can contact both parties for context
   - Admin decision: warn/suspend/ban accounts
   - Still no money handling - just account management

5. **Legal Protection**:
   - Terms of Service: Platform doesn't mediate disputes
   - Clear disclaimer: Transactions are between seller and customer
   - Platform provides discovery only, not payment processing

**Action Items**:
- Add "Relatar Problema" button to completed orders (future)
- Add report categories: Não recebi / Qualidade ruim / Cancelamento indevido / Outro
- Admin dashboard shows flagged orders (future)
- For MVP: rely on reviews + ability to ban users

---

## Critical Files Reference

### Backend Files to Create (Orders)
```
backend/db/migrate/*_create_orders.rb
backend/db/migrate/*_create_order_items.rb
backend/app/models/order.rb
backend/app/models/order_item.rb
backend/app/controllers/api/v1/orders_controller.rb
backend/app/controllers/api/v1/seller/orders_controller.rb
backend/app/models/activity_log.rb
backend/app/controllers/api/v1/admin/users_controller.rb
```

### Frontend Files to Create (Orders)
```
frontend/src/screens/CartScreen.tsx
frontend/src/screens/CheckoutScreen.tsx
frontend/src/screens/OrderHistoryScreen.tsx
frontend/src/screens/OrderDetailScreen.tsx
frontend/src/screens/seller/SellerDashboardScreen.tsx
frontend/src/screens/seller/PostMenuScreen.tsx
frontend/src/screens/seller/IncomingOrdersScreen.tsx
frontend/src/components/CartItem.tsx
frontend/src/components/OrderCard.tsx
frontend/src/components/StarRating.tsx
```

### Existing Patterns to Reuse

**From Review model** (backend/app/models/review.rb):
- Validation patterns (uniqueness with scope, custom validators)
- State management (moderation_status string)
- Callback patterns (after_save :update_seller_rating)

**From WeeklyMenuDish model**:
- Quantity tracking (available_quantity, remaining_quantity)
- Atomic decrement/increment methods

**From HomeScreen** (frontend/src/screens/HomeScreen.tsx):
- FlatList with pull-to-refresh
- Loading/error states
- Card-based layouts

**From API service** (frontend/src/services/api.ts):
- Axios instance with interceptors
- Token injection
- Error handling patterns

---

## Verification & Testing

### Orders System Testing

**Backend API Tests:**
```bash
# Create test data
bin/rails runner tmp/create_order_test_data.rb

# Test order creation
curl -H "Authorization: Bearer $TOKEN" \
  -d '{"order":{"seller_profile_id":1,"items":[{"dish_id":1,"quantity":2}]}}' \
  http://localhost:3000/api/v1/orders

# Verify quantity decremented
bin/rails runner "puts WeeklyMenuDish.find(1).remaining_quantity"

# Test order cancellation
curl -X DELETE -H "Authorization: Bearer $TOKEN" \
  http://localhost:3000/api/v1/orders/1

# Verify quantity restored
bin/rails runner "puts WeeklyMenuDish.find(1).remaining_quantity"
```

**Frontend Manual Tests:**
1. Open app → Login as consumer
2. Browse sellers → Find active seller
3. View menu → Add items to cart
4. Open cart → Verify totals
5. Checkout → Place order
6. Check order appears in history
7. Login as seller → Verify order appears
8. Update order status → Verify consumer sees update
9. Complete order → Verify can leave review

**Load Testing:**
- Simulate 10 concurrent orders for same dish
- Verify no overselling (quantity cannot go negative)
- Check database locks and transaction handling

### Deployment Verification

**Production Health Checks:**
```bash
# API health
curl https://api.marmitas.top/up

# Database connection
curl https://api.marmitas.top/api/v1/sellers

# Authentication
curl -d '{"email":"test@test.com","password":"test123"}' \
  https://api.marmitas.top/api/v1/auth/login

# Geospatial queries
curl "https://api.marmitas.top/api/v1/sellers/nearby?latitude=-23.56&longitude=-46.65"

# Image uploads (S3)
curl -F "file=@test.jpg" https://api.marmitas.top/api/v1/uploads
```

**Mobile App Verification:**
- Install APK on Android device
- Install TestFlight build on iOS device
- Test without WiFi (cellular only)
- Test location permissions
- Test push notifications
- Test offline behavior

---

## Technical Debt & Future Work

**After V0 Launch:**
1. Real-time order updates (Action Cable)
2. Background jobs (Sidekiq)
3. In-app payments (Stripe)
4. Email notifications
5. Advanced filters
6. Analytics dashboard
7. Automated testing (RSpec, Jest)
8. CI/CD pipeline
9. Performance optimization
10. Caching layer (Redis)

---

## Risk Mitigation

**High-Risk Areas:**
1. **Overselling**: Atomic transactions + row-level locks on quantity updates
2. **Concurrent Orders**: Database-level constraints, optimistic locking
3. **Stale Data**: Refresh cart before checkout, validate quantities server-side
4. **Order Abandonment**: Clear cart after 1 hour, restore quantities if not completed
5. **Seller Offline**: Auto-cancel pending orders if seller broadcasts expire
6. **Review Gaming**: Reuse anti-gaming patterns from existing review system

---

## Plan Status: COMPLETE - Ready for Review

**Completed Phases:**
1. ✅ Phase 1: Exploration complete (3 agents analyzed codebase patterns)
2. ✅ Phase 2: Design complete (Plan agent delivered comprehensive Orders system spec)
3. ✅ Phase 3: Plan file updated with detailed specifications
4. ✅ Phase 4: Business rules and technical decisions documented

**Plan Deliverables:**
- Complete database schema for Orders/OrderItems with migrations
- Full backend implementation (models, controllers, routes, jobs)
- Complete frontend implementation (screens, context, API integration)
- Edge case handling (concurrency, validation, cancellation)
- Testing strategy and verification steps
- 4-week roadmap with daily breakdown
- Deployment checklist for Railway + Expo

**Next Step:** Exit plan mode and await user approval to begin implementation

# Implementation Instructions for Claude Code

## OBJECTIVE

Implement a seller-level review and rating system for Marmitas.top MVP with comprehensive moderation tools and gaming prevention mechanisms.

---

## CONTEXT

**Project:** Marmitas.top V2 - Rails 8 API + Expo mobile app  
**Current State:** Basic marketplace with users, marmiteiro profiles, and daily menus  
**Task:** Add review system where consumers rate marmiteiros (sellers), not individual dishes  
**Critical Requirements:**
- Prevent reputation gaming (deleting bad reviews)
- Implement moderation tools for admins
- Protect against fake/malicious reviews
- Keep UI simple (not overwhelming users)

---

## SUCCESS CRITERIA

### Must Have (MVP)
1. ✅ Consumers can leave 1-5 star rating + optional text comment for marmiteiros
2. ✅ One review per user per marmiteiro per day (prevent spam)
3. ✅ Extreme ratings (1 or 5 stars) require text comment
4. ✅ Reviews cannot be deleted by marmiteiros (soft delete for menus preserves review history)
5. ✅ Marmiteiro profile shows aggregate rating (weighted by recency)
6. ✅ Rating only shows after minimum 5 reviews
7. ✅ Users can edit reviews within 48 hours
8. ✅ Users can flag inappropriate reviews
9. ✅ Users can mark reviews as "helpful"
10. ✅ Admin moderation queue for flagged/suspicious reviews
11. ✅ Automatic detection of suspicious patterns (all 1-star reviews, too many reviews)
12. ✅ Rating distribution display (how many 5-star, 4-star, etc.)

### System Behavior
- ✅ Reviews persist even if daily menu is deleted (soft delete only)
- ✅ Recent reviews weighted more heavily in aggregate rating (60% last 30 days, 30% 30-90 days, 10% older)
- ✅ Reviews under moderation don't count toward rating
- ✅ Rating recalculates automatically when reviews added/removed/moderated

---

## IMPLEMENTATION SCENARIOS

### Scenario 1: Consumer Creates Review
**Given:** Maria (consumer) tried João's marmita today  
**When:** She opens João's profile and taps "Write Review"  
**Then:**
- System checks she hasn't reviewed João today (duplicate prevention)
- System checks she's not reviewing her own business
- She rates 1-5 stars
- If 1 or 5 stars, comment field becomes required
- She optionally adds text comment
- Review saves with `encounter_date = today`
- If she includes GPS coordinates in payload, system verifies she was within 50m of João's location → marks as "verified_encounter"
- João's rating counters update automatically
- Review appears in João's review list immediately

**Edge Cases:**
- Trying to review same marmiteiro twice today → Error: "Você já avaliou este marmiteiro hoje"
- Marmiteiro trying to review themselves → Error: Forbidden
- 1-star rating without comment → Validation error
- User has pattern of 3+ one-star reviews in past week → Auto-flagged for moderation (status = 'under_review')

### Scenario 2: Consumer Edits Review
**Given:** Maria wrote a 3-star review yesterday  
**When:** She changes her mind and wants to update to 4 stars  
**Then:**
- System checks review is within 48-hour edit window
- System checks she owns this review
- System checks review is not under moderation
- Update succeeds
- `edit_count` increments
- `last_edited_at` updates
- João's rating recalculates

**Edge Cases:**
- Trying to edit after 48 hours → Error: "Esta avaliação não pode mais ser editada"
- Review is under moderation → Error: Cannot edit
- After 3 days, even owner cannot delete review (permanent record)

### Scenario 3: Marmiteiro Deletes Menu
**Given:** João posted "Feijoada" menu with 5 reviews  
**When:** He deletes the Feijoada menu  
**Then:**
- Menu gets soft deleted (deleted_at = timestamp, not hard delete)
- All 5 reviews remain in database
- Reviews still point to menu via foreign key
- In review display, dish shows as "Feijoada (não disponível)"
- Reviews still count toward João's aggregate rating
- João CANNOT remove reviews by deleting menus

### Scenario 4: User Flags Review
**Given:** Pedro sees a review that seems fake/inappropriate  
**When:** He clicks "Flag" on the review  
**Then:**
- System checks Pedro is not the review author (can't self-flag)
- System checks review hasn't been flagged already
- Flag dialog asks for reason
- Review gets marked: `flagged = true`, `moderation_status = 'under_review'`
- Review disappears from public view
- Admin moderation queue receives notification
- Marmiteiro's rating recalculates without this review (temporarily)

### Scenario 5: Admin Moderates Review
**Given:** Admin sees flagged review in moderation queue  
**When:** Admin reviews the content  
**Then:**

**Option A - Approve:**
- Admin clicks "Approve" with optional note
- Review status → 'published'
- Review reappears in public view
- Marmiteiro rating recalculates including this review

**Option B - Remove:**
- Admin clicks "Remove" with required reason
- Review status → 'removed'
- Review permanently excluded from rating
- Review stays in database (audit trail)
- Marmiteiro rating recalculates without this review

### Scenario 6: Aggregate Rating Calculation
**Given:** João has 12 reviews over 6 months  
**When:** System calculates his aggregate rating  
**Then:**
- Only counts reviews with `moderation_status = 'published'`
- Recent reviews (last 30 days): 5 reviews averaging 4.8 → weight 60%
- Medium reviews (30-90 days): 4 reviews averaging 4.2 → weight 30%
- Old reviews (90+ days): 3 reviews averaging 3.5 → weight 10%
- Weighted average formula: (4.8×5×0.6 + 4.2×4×0.3 + 3.5×3×0.1) / (5×0.6 + 4×0.3 + 3×0.1)
- Result rounded to 2 decimals
- Stored in `marmiteiro_profiles.average_rating`
- Rating distribution counters updated (rating_1_count through rating_5_count)

**Display Rules:**
- If reviews_count < 5 → Show "New seller (X reviews)" instead of numeric rating
- If reviews_count >= 5 → Show "⭐ 4.7 (12 avaliações)"

### Scenario 7: "Helpful" Voting
**Given:** Carlos reads Maria's review  
**When:** He clicks "Mark as helpful"  
**Then:**
- System checks Carlos is not the review author
- Creates entry in review_helpfuls table
- Review.helpful_count increments
- If Carlos clicks again → Removes vote, count decrements (toggle)

### Scenario 8: Suspicious Pattern Detection
**Given:** User creates new review  
**When:** System runs pre-save checks  
**Then:**
- Check recent reviews from same user (last 7 days)
- If 3+ reviews AND all are 1-star → Set `moderation_status = 'under_review'`
- If 10+ reviews in 7 days → Set `moderation_status = 'under_review'`
- Flag appears in admin queue automatically

---

## DATABASE REQUIREMENTS

### New Tables
1. **reviews** - Core review data
   - Required fields: user_id, marmiteiro_profile_id, rating, encounter_date
   - Optional: comment, daily_menu_id, verification data
   - Moderation: flagged, flag_reason, moderation_status, moderation_note
   - Engagement: helpful_count, edit_count
   - Unique constraint: [user_id, marmiteiro_profile_id, encounter_date]

2. **review_helpfuls** - Helpful votes
   - Fields: review_id, user_id
   - Unique constraint: [review_id, user_id]

### Modified Tables
3. **daily_menus** - Add soft delete
   - Add column: deleted_at (datetime, indexed)
   - Preserve reviews when deleted

4. **marmiteiro_profiles** - Add rating counters
   - average_rating (decimal 3,2)
   - reviews_count (integer, counter_cache)
   - rating_1_count through rating_5_count (integers)

### Indexes Required
- reviews(marmiteiro_profile_id) - List reviews per seller
- reviews(moderation_status) - Admin queue
- reviews(flagged) - Admin queue
- reviews(created_at) - Sorting
- reviews([user_id, marmiteiro_profile_id, encounter_date]) - Duplicate prevention
- marmiteiro_profiles(average_rating) - Sorting/filtering
- daily_menus(deleted_at) - Soft delete queries

---

## API ENDPOINTS REQUIRED

### Consumer Endpoints
```
GET    /api/v1/marmiteiros/:id/reviews
       - List reviews (published only)
       - Params: page, sort (recent/helpful/rating), filter (rating, verified_only, with_comments)
       - Returns: reviews array + rating summary + pagination meta

POST   /api/v1/marmiteiros/:id/reviews
       - Create review
       - Body: { rating, comment, daily_menu_id, encounter_lat/lng, encounter_timestamp }
       - Validates: not duplicate, not self-review, extreme rating has comment
       - Returns: created review

GET    /api/v1/reviews/:id
       - Show single review (detailed)
       - Returns: review + edit permissions + flag permissions

PATCH  /api/v1/reviews/:id
       - Update review (within 48h window)
       - Body: { rating, comment }
       - Validates: owner, within window, not under moderation
       - Returns: updated review

DELETE /api/v1/reviews/:id
       - Delete review (within 48h window)
       - Validates: owner, within window
       - Soft deletes or hard deletes (decision needed)

POST   /api/v1/reviews/:id/flag
       - Flag review for moderation
       - Body: { reason }
       - Validates: not self-flag, not already flagged
       - Returns: success message

POST   /api/v1/reviews/:id/helpful
       - Toggle helpful vote
       - No body
       - Returns: new helpful_count + user's vote status
```

### Admin Endpoints
```
GET    /api/v1/admin/reviews
       - List all reviews needing moderation
       - Filter: status (flagged/under_review/removed)
       - Returns: reviews + user/marmiteiro context + moderation stats

GET    /api/v1/admin/reviews/:id
       - Show review detail for moderation
       - Returns: full review + user history + similar patterns

POST   /api/v1/admin/reviews/:id/approve
       - Approve flagged review
       - Body: { note }
       - Changes status to 'published'
       - Recalculates rating

POST   /api/v1/admin/reviews/:id/remove
       - Remove review permanently
       - Body: { note } (required)
       - Changes status to 'removed'
       - Recalculates rating
```

---

## BUSINESS LOGIC REQUIREMENTS

### Rating Calculation Algorithm
```
For each marmiteiro:
1. Fetch all reviews where moderation_status = 'published'
2. Group by age:
   - Recent: created_at > 30 days ago
   - Medium: 30-90 days ago  
   - Old: > 90 days ago
3. Calculate weighted average:
   weighted = (recent_avg × recent_count × 0.6 + 
               medium_avg × medium_count × 0.3 + 
               old_avg × old_count × 0.1) /
              (recent_count × 0.6 + medium_count × 0.3 + old_count × 0.1)
4. Round to 2 decimals
5. Update marmiteiro_profile.average_rating
6. Update distribution counters (rating_1_count through rating_5_count)
```

### Edit Window Rules
- Reviews editable for 48 hours after creation
- After 48 hours, locked permanently (maintains trust)
- Edit increments edit_count
- Edit updates last_edited_at
- Reviews under moderation cannot be edited

### Duplicate Prevention
- One review per [user + marmiteiro + date] combination
- Enforced at database level (unique index)
- Users CAN review same marmiteiro on different days
- This allows for multiple experiences over time

### Moderation Triggers
**Auto-flag for review if:**
- User has 3+ one-star reviews in last 7 days (all ratings = 1)
- User has 10+ reviews in last 7 days (spam pattern)
- (Future) User's IP matches known bad actors

**Manual flag triggers:**
- Another user reports the review
- Admin proactively reviews content

### Verification Logic
If review includes encounter_latitude and encounter_longitude:
1. Check if marmiteiro currently_active = true
2. Fetch marmiteiro's current selling_location
3. Calculate distance between encounter coords and location
4. If distance < 50 meters → verified_encounter = true
5. Display "✓ Verified" badge in UI

---

## AUTHORIZATION RULES (Pundit)

### Review Permissions
```
create_review:
  - User must be authenticated
  - User role must be 'consumer' (not admin, not marmiteiro for this profile)
  - User cannot review their own marmiteiro_profile
  - User has not reviewed this marmiteiro today

view_reviews:
  - Anyone can view published reviews
  - Only owner/admin can view own unpublished reviews

edit_review:
  - User must own the review
  - Review must be within 48-hour window
  - Review must not be under moderation

delete_review:
  - Same as edit_review

flag_review:
  - User must be authenticated
  - User cannot flag own review
  - Review must not already be flagged
  - Review must be published

mark_helpful:
  - User must be authenticated
  - User cannot mark own review as helpful

moderate_review: (admin only)
  - User role must be 'admin'
```

---

## TESTING REQUIREMENTS

### Unit Tests (Model)
```ruby
Review model:
✓ validates rating presence and range (1-5)
✓ validates comment presence for extreme ratings (1 or 5)
✓ prevents duplicate reviews (same user + marmiteiro + date)
✓ snapshots dish_name on creation
✓ calculates editable_by? correctly (owner, within window, status)
✓ displays deleted dish names correctly
✓ auto-flags suspicious patterns
✓ updates marmiteiro counters after save/destroy

MarmiteiroProfile model:
✓ recalculates average_rating correctly
✓ applies recency weighting correctly
✓ ignores removed reviews in calculation
✓ calculates rating distribution correctly
✓ shows rating only after 5+ reviews
✓ calculates rating trend (recent vs old)

DailyMenu model:
✓ soft deletes instead of hard delete
✓ preserves foreign key relationships after deletion
✓ restore! method works correctly
```

### Integration Tests (Request)
```ruby
GET /marmiteiros/:id/reviews:
✓ returns only published reviews
✓ includes rating summary
✓ supports pagination
✓ filters by rating
✓ filters by verified_only
✓ sorts by recent/helpful/rating

POST /marmiteiros/:id/reviews:
✓ creates review with valid params
✓ requires comment for extreme ratings
✓ prevents duplicate (same day)
✓ prevents self-review (marmiteiro reviewing self)
✓ auto-flags suspicious patterns
✓ sets verified_encounter if coordinates valid
✓ returns 401 if not authenticated

PATCH /reviews/:id:
✓ allows owner to edit within window
✓ increments edit_count
✓ prevents editing after 48 hours
✓ prevents editing if under moderation
✓ returns 403 if not owner

POST /reviews/:id/flag:
✓ flags review with reason
✓ sets moderation_status to under_review
✓ prevents self-flagging
✓ prevents double-flagging

POST /reviews/:id/helpful:
✓ increments helpful_count
✓ toggles on/off
✓ prevents self-helpful

Admin endpoints:
✓ requires admin role
✓ lists flagged reviews
✓ approves review correctly
✓ removes review correctly
✓ recalculates ratings after moderation
```

---

## FILE STRUCTURE

```
app/
├── models/
│   ├── review.rb (new)
│   ├── review_helpful.rb (new)
│   ├── marmiteiro_profile.rb (modify - add rating methods)
│   ├── daily_menu.rb (modify - add soft delete)
│   └── user.rb (modify - add review associations)
│
├── controllers/api/v1/
│   ├── reviews_controller.rb (new)
│   └── admin/
│       └── reviews_controller.rb (new)
│
├── policies/
│   └── review_policy.rb (new)
│
├── jobs/
│   ├── recalculate_marmiteiro_ratings_job.rb (new)
│   └── send_moderation_alert_job.rb (new)
│
└── serializers/ (if using)
    └── review_serializer.rb (new)

db/
└── migrate/
    ├── [timestamp]_create_reviews.rb
    ├── [timestamp]_add_deleted_at_to_daily_menus.rb
    ├── [timestamp]_add_review_counters_to_marmiteiro_profiles.rb
    └── [timestamp]_create_review_helpfuls.rb

spec/
├── models/
│   ├── review_spec.rb
│   ├── marmiteiro_profile_spec.rb
│   └── daily_menu_spec.rb
│
├── requests/api/v1/
│   ├── reviews_spec.rb
│   └── admin/
│       └── reviews_spec.rb
│
└── policies/
    └── review_policy_spec.rb

config/
└── routes.rb (modify - add review routes)
```

---

## COMPLETION CHECKLIST

### Phase 1: Database Setup
- [ ] Generate and run migration for reviews table
- [ ] Generate and run migration for review_helpfuls table
- [ ] Generate and run migration for daily_menus soft delete
- [ ] Generate and run migration for marmiteiro rating counters
- [ ] Verify all indexes created correctly
- [ ] Verify foreign key constraints work

### Phase 2: Models
- [ ] Create Review model with all validations
- [ ] Create ReviewHelpful model
- [ ] Update DailyMenu with soft delete methods
- [ ] Update MarmiteiroProfile with rating calculation methods
- [ ] Update User model with review associations
- [ ] All model tests passing

### Phase 3: Controllers & Routes
- [ ] Create ReviewsController with all actions
- [ ] Create Admin::ReviewsController
- [ ] Update routes.rb with nested review routes
- [ ] All controller tests passing

### Phase 4: Authorization
- [ ] Create ReviewPolicy with all rules
- [ ] Add authorize calls in controllers
- [ ] Policy tests passing

### Phase 5: Background Jobs
- [ ] Create rating recalculation job
- [ ] Create moderation alert job
- [ ] Jobs process correctly in test environment

### Phase 6: Integration Testing
- [ ] All request specs passing
- [ ] Test all edge cases (duplicate, edit window, self-review)
- [ ] Test moderation workflow end-to-end
- [ ] Test rating calculation accuracy

### Phase 7: Manual QA
- [ ] Can create review via API
- [ ] Can edit review within window
- [ ] Cannot edit after window
- [ ] Duplicate prevention works
- [ ] Flag workflow works
- [ ] Helpful toggle works
- [ ] Admin can moderate reviews
- [ ] Ratings calculate correctly
- [ ] Soft delete preserves reviews
- [ ] Suspicious patterns auto-flag

---

## DEFINITION OF DONE

**This feature is complete when:**

1. ✅ All migrations run successfully in development and test
2. ✅ All model tests pass (100% coverage on new models)
3. ✅ All controller/request tests pass
4. ✅ All policy tests pass
5. ✅ Postman/curl can successfully:
   - Create a review
   - List reviews with filters
   - Edit a review (within window)
   - Flag a review
   - Mark helpful
   - Admin can moderate (approve/remove)
6. ✅ Rating calculation produces correct results (verified with sample data)
7. ✅ Soft delete prevents reviews from being lost
8. ✅ Suspicious pattern detection works (test with 3 one-star reviews)
9. ✅ All edge cases handled gracefully (duplicates, self-review, expired window)
10. ✅ No N+1 queries in list endpoints (use includes/joins appropriately)
11. ✅ All background jobs execute without errors
12. ✅ Code follows Rails conventions and project style guide
13. ✅ No security vulnerabilities (mass assignment, SQL injection, XSS)

---

## EXAMPLE TEST DATA SETUP

For manual testing, create this scenario:
```ruby
# seeds.rb or rails console
consumer1 = User.create!(name: 'Maria', email: 'maria@test.com', role: 'consumer')
consumer2 = User.create!(name: 'Pedro', email: 'pedro@test.com', role: 'consumer')
marmiteiro_user = User.create!(name: 'João', email: 'joao@test.com', role: 'marmiteiro')
marmiteiro = MarmiteiroProfile.create!(user: marmiteiro_user, business_name: "João's Marmitas")

# Create reviews spanning different time periods
Review.create!(user: consumer1, marmiteiro_profile: marmiteiro, rating: 5, comment: "Excellent!", created_at: 10.days.ago)
Review.create!(user: consumer2, marmiteiro_profile: marmiteiro, rating: 4, comment: "Good!", created_at: 20.days.ago)
Review.create!(user: consumer1, marmiteiro_profile: marmiteiro, rating: 3, comment: "Okay", created_at: 50.days.ago, encounter_date: 50.days.ago.to_date)
Review.create!(user: consumer2, marmiteiro_profile: marmiteiro, rating: 5, comment: "Great!", created_at: 100.days.ago, encounter_date: 100.days.ago.to_date)

# Recalculate rating
marmiteiro.recalculate_ratings!

# Expected: average_rating around 4.3-4.5 (recent reviews weighted more)
puts "Rating: #{marmiteiro.average_rating}"
puts "Distribution: #{marmiteiro.rating_distribution}"
```

---

## QUESTIONS TO RESOLVE BEFORE STARTING

1. **Hard vs Soft Delete for Reviews:** Should users be able to permanently delete their reviews, or only within 48h then permanent? (Recommendation: Permanent after 48h for trust)

2. **Anonymous Reviews:** Should consumer names be shown or anonymized? (Recommendation: Show names to prevent fake reviews)

3. **Response to Reviews:** Should marmiteiros be able to respond publicly to reviews? (Recommendation: Yes, in Phase 2)

4. **Photo Uploads:** Should reviews support photo uploads? (Recommendation: No for MVP, add Phase 2)

5. **Notification Strategy:** Should marmiteiros get notified immediately of new reviews? (Recommendation: Daily digest email)

6. **Admin Notification:** How should admins be notified of flagged reviews? (Email, in-app notification, Slack webhook?)

---

## EXECUTION COMMAND

**To implement this feature, Claude Code should:**

1. Start by reading this document completely
2. Ask clarifying questions if any requirements are ambiguous
3. Begin with database migrations (Phase 1)
4. Proceed through phases sequentially
5. Run tests after each phase
6. Report progress and blockers
7. When complete, run the manual QA checklist

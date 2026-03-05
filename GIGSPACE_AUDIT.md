# GigSpace — Full Codebase Audit
**Date:** March 2026 | **Status:** Pre-rebuild analysis

---

## Executive Summary

The current codebase is a functional but fundamentally misaligned MVP. It proves the concept works but it was built with a different mental model than the one in the project overview. Most of the misalignment is structural — wrong roles, missing state transitions, incomplete trust layer, wrong stack assumptions — and cannot be patched. It needs a purposeful rebuild using the existing code as a reference, not a base.

The good news: the schema bones are solid, the routing is logical, and the frontend component architecture is clean. Nothing needs to be thrown away — it needs to be refactored with precision.

---

## 1. Stack Reality vs. Stack Intent

### What the overview assumed:
- Flutter (mobile frontend)
- Firebase (Auth, Firestore, Cloud Functions, Notifications)

### What was actually built:
- Next.js 14 (web frontend)
- Express.js + Prisma + **SQLite** (backend)
- Socket.io (real-time chat)
- Zustand (state management)

### Verdict:
The decision to use Next.js + Express is not wrong — it's actually a better choice for rapid development and a web-first campus platform. **Keep this stack.** However, SQLite is a critical problem:

- SQLite is a single-file, single-writer database. It will break under concurrent writes.
- It cannot be deployed to any cloud host in a meaningful way.
- It has no real-time capability.

**Action Required:** Migrate to **PostgreSQL** (via Prisma, which already supports it — one line change in schema.prisma). Use Supabase or Railway for free-tier hosting.

---

## 2. Database Schema — Gaps & Bugs

### 2a. Missing Models (Critical)

| Model | Status | Impact |
|---|---|---|
| `Rating` | ❌ Missing | Ratings are a flat Float on User — no per-transaction ratings, no review text, no history |
| `Notification` (user-facing) | ❌ Missing | Only `AdminNotification` exists. Users receive zero notifications |
| `Transaction` | ❌ Missing | Payment flow is an in-memory interface with no DB persistence |

### 2b. User Model Problems

```
Current fields: firstName, lastName, email, phone, city, password, role
```

**What's wrong:**
- `city` — This is not a campus platform field. Campus = `university`, `department`, `year`
- `phone` — Required on registration. Students won't give this. Should be optional.
- No `universityEmail` verification — The core trust mechanism of the whole platform is absent. Anyone with any email can register.
- No `bio` or `skills` fields — The overview explicitly lists these as profile fields. They're completely missing.
- No `profilePhoto` field

**The role system is wrong:**
```
Current roles: WORKER | BUYER | RENTAL_OWNER | ADMIN
```
This creates artificial silos. The overview says any student can post a gig AND accept a gig AND list items AND rent items. The role should be:
```
Correct roles: STUDENT | ADMIN
```
A STUDENT can do everything. Role-based restrictions on actions (e.g., can't accept your own gig) are enforced at the API level, not by assigning a static role.

### 2c. Gig Model Problems

**Missing fields:**
- `acceptedBy` (userId of the accepted worker) — Currently inferred from GigApplication but not directly on the Gig
- `completedAt` timestamp
- No `ACCEPTED` status — The overview defines this as a distinct state

**State machine mismatch:**

| Overview States | Current States |
|---|---|
| OPEN | OPEN ✅ |
| ACCEPTED | ❌ Missing |
| IN_PROGRESS | IN_PROGRESS ✅ |
| COMPLETED_PENDING_REVIEW | ❌ Missing |
| CLOSED | COMPLETED (partial) |
| CANCELLED | CANCELLED ✅ |
| REPORTED | ❌ Missing |

The `ACCEPTED` → `IN_PROGRESS` transition is critical. It's the moment the executor says "I've started work." Without it, there's no way to distinguish "accepted but not started" from "actively working." The UI collapses these into one, which breaks the trust timeline.

### 2d. Rental Model Problems

**Missing fields:**
- `availabilityStartDate` / `availabilityEndDate` — Owner needs to specify when the item is available
- `images[]` — The frontend expects `images: string[]` but the DB model has no image field at all. This is a live bug.
- `condition` — Important for damage dispute resolution

**RentalBooking unique constraint bug:**
```sql
UNIQUE(rentalId, userId, startDate)
```
This prevents the same user from booking the same item twice only if they choose the exact same startDate. It does NOT prevent double-bookings by different users for overlapping dates. There is zero overlap detection logic in the codebase.

**State machine mismatch:**

| Overview States | Current States |
|---|---|
| AVAILABLE | AVAILABLE ✅ |
| REQUESTED | PENDING (in Booking, not on Rental) |
| ACTIVE | CONFIRMED (partial) |
| RETURN_PENDING | ❌ Missing |
| COMPLETED | COMPLETED ✅ |
| DISPUTED | ❌ Missing |
| CANCELLED | CANCELLED ✅ |

### 2e. Leaderboard Model — Architectural Problem

The `Leaderboard` model is a denormalized duplicate of User data:
```
Leaderboard.completedGigs = User.completedGigs
Leaderboard.totalEarnings = User.totalEarnings
Leaderboard.rating = User.rating
```
This means there are two sources of truth. They will drift. Either compute the leaderboard as a view/query from User data, or drop the standalone model entirely.

---

## 3. Backend — Structural Problems

### 3a. Everything in one file

`backend/src/index.ts` contains: auth middleware, admin middleware, all route handlers, payment logic, report logic, chat logic — in a single file. This is the definition of technical debt. As the codebase grows this becomes impossible to debug.

**Required structure:**
```
backend/src/
  routes/
    auth.ts
    gigs.ts
    rentals.ts
    users.ts
    chat.ts
    admin.ts
    notifications.ts
  middleware/
    auth.ts
    admin.ts
    rateLimit.ts
  services/
    gigService.ts
    rentalService.ts
    trustService.ts
    notificationService.ts
  index.ts  ← only app setup and route mounting
```

### 3b. Payment is fake

`PaymentRecord` is defined as a TypeScript interface and stored in-memory:
```typescript
interface PaymentRecord {
  id: string
  userId: string
  amount: number
  status: PaymentStatus
  ...
}
```
There's a `NEXT_PUBLIC_RAZORPAY_KEY` in the env example but zero Razorpay integration in the actual code. If a user pays, the record disappears on server restart.

### 3c. No university email validation

Registration accepts any email. The core trust mechanism — `@university.edu` verification — doesn't exist. There's no email verification flow at all (no verification tokens, no verification emails, no "unverified" user state).

### 3d. Socket.io declared but broken

`socket.ts` in the frontend imports and initializes Socket.io. The backend `index.ts` doesn't mount a Socket.io server. Real-time chat will silently fail. Chat currently works by polling the REST API, not via WebSocket.

---

## 4. Frontend — Page-by-Page Issues

### 4a. Auth Pages (`/auth/login`, `/auth/register`)

**Register:**
- Collects: firstName, lastName, email, phone, city — wrong fields for a campus product
- Should collect: name, university email, department, year
- No email verification step after register
- No university domain whitelist validation client-side

### 4b. Dashboard (`/dashboard`)

- Shows `totalEarnings`, `completedGigs`, `activeRentals`, `currentRank` — good structure
- `upcomingGigs` is fetched but the shape is `any[]` — no type safety
- No distinction between gigs where user is the *poster* vs *executor* — a user will see a confusing mix
- No rental notifications (pending approvals, active rentals due back)

### 4c. Gig Detail (`/gigs/[id]`)

- Has one button: "Accept Gig" — this collapses the entire lifecycle into one action
- Missing: Apply button (for executor), Accept applicant (for poster), Mark Started, Mark Complete, Rate
- No display of applications list for the gig poster
- Status badge exists but doesn't gate which actions are available

### 4d. Rental Detail (`/rentals/[id]`)

- `images: string[]` is in the interface but the DB has no image field — this will always be empty
- The booking form has start/end date but no overlap check before submit
- No deposit display logic
- No owner approval step shown — booking goes straight to "confirmed" in the UI

### 4e. Profile Page (`/profile`)

- Shows: name, email, phone, city, rating, logout button
- Missing: bio, skills, department, completed gigs history, ratings received, items listed
- No edit functionality (Edit button exists but leads nowhere)

### 4f. Landing Page (`/`)

- `Hero.tsx`, `Features.tsx`, `Testimonials.tsx`, `Pricing.tsx` are all stub components:
  ```typescript
  export default function HeroStub() {}
  export default function FeaturesStub() {}
  ```
  The landing page is completely empty. A new visitor sees nothing.

### 4g. Leaderboard (`/leaderboard`)

This page exists and works but it's a vanity feature for an MVP. The leaderboard ranking system as currently implemented (`Leaderboard` table) is a dead-end architecture. Acceptable to keep the page, but should be computed from User data.

### 4h. Admin Panel (`/admin/*`)

The admin pages are actually fairly complete:
- `/admin/dashboard` — analytics summary ✅
- `/admin/users` — list, search, suspend, ban ✅
- `/admin/users/[id]` — user detail, edit, password reset ✅
- `/admin/listings` — view/delete gigs and rentals ✅
- `/admin/reports` — view, resolve reports ✅
- `/admin/analytics` — stats ✅

The admin panel is the most complete part of the frontend. Keep and refine.

---

## 5. UI/UX — What Needs to Change Everywhere

The current UI is functional but generic. Dark theme, gray cards, standard Tailwind patterns. It doesn't feel like a campus product — it feels like a freelance SaaS.

**Core UX problems:**

1. **No onboarding flow** — After register, user lands on dashboard with empty states and no guidance. They don't know what to do.

2. **No empty state design** — Browse gigs with no gigs, browse rentals with no rentals, no messaging. Empty states are blank or show raw text. They should guide the user to action.

3. **No trust signals on cards** — Gig/rental cards show title + budget but not rating, completion count, or verified badge of the poster. Trust is invisible.

4. **No contextual chat entry** — Chat is a standalone section. It should be launchable from a gig or rental context ("Message about this item") so conversations have context.

5. **Role confusion in navigation** — The nav bar shows all options (Post Gig, Browse Gigs, List Item, Browse Rentals) simultaneously. A first-time user has no mental model of which role they're in.

6. **No mobile-responsive polish** — The Header has a hamburger menu but the content pages aren't optimized for mobile. Campus students are on their phones.

---

## 6. What to Keep, What to Rebuild

### Keep (solid foundation):
- Prisma schema structure (extend, don't rewrite)
- Zustand auth store pattern
- React Query setup
- Route structure (`/gigs`, `/rentals`, `/admin/*`)
- Admin panel pages (most complete area)
- AnimatedCard, AnimatedButton, AnimatedSkeleton components
- `helpers.ts` and `validation.ts` utilities
- Chat model (Chat, ChatParticipant, ChatMessage) — correct design

### Extend (needs new fields/logic):
- User model → add department, university, bio, skills, profilePhoto, universityVerified
- Gig model → add acceptedBy, fix state machine
- Rental model → add images, availabilityWindow, condition
- Backend routes → split into files, add missing endpoints
- Gig detail page → full lifecycle UI
- Rental detail page → full booking flow with overlap detection
- Profile page → complete with edit, history, ratings

### Rebuild (wrong approach):
- User role system → STUDENT | ADMIN only
- Leaderboard model → compute from User, no separate table
- Payment layer → real Razorpay integration or stub clearly
- Landing page → build real Hero, Features, CTA
- Register flow → university email + verification
- State machines → implement all states from spec
- Rating system → dedicated Rating model per transaction

---

## 7. Priority Build Order

**Phase 1 — Foundation (must fix before adding features)**
1. Switch SQLite → PostgreSQL
2. Fix User model (department, university, bio, skills, universityVerified)
3. Fix role system (STUDENT | ADMIN)
4. Add Rating model
5. Add Notification model
6. Fix Gig state machine (add ACCEPTED, COMPLETED_PENDING_REVIEW, REPORTED)
7. Fix Rental state machine (add RETURN_PENDING, DISPUTED)
8. Split backend index.ts into routes + services

**Phase 2 — Core flows**
1. University email verification flow
2. Full gig lifecycle UI (apply → accept → start → complete → rate)
3. Full rental lifecycle UI (request → approve → active → return → confirm → rate)
4. Notification system (user-facing)
5. Overlap detection for rental bookings

**Phase 3 — Trust & Polish**
1. Rating display on all cards and profiles
2. Landing page with real content
3. Onboarding flow
4. Empty state designs
5. Mobile UX polish
6. Real payment integration

**Phase 4 — Admin & Analytics**
1. Dispute resolution workflow
2. Marketplace freeze capability
3. Admin broadcast announcements
4. Real-time analytics

---

## 8. One Sentence Per File

| File | Verdict |
|---|---|
| `schema.prisma` | Good skeleton, needs Rating/Notification/Transaction models + field additions |
| `backend/src/index.ts` | Too large, functional but unmaintainable — split urgently |
| `store/auth.ts` | Correct pattern, update User type to match new schema |
| `services/api.ts` | Clean axios wrapper — keep |
| `services/socket.ts` | Declared but backend has no socket server — either wire up or remove |
| `app/auth/register` | Wrong fields, no verification — rebuild |
| `app/gigs/[id]` | Collapsed lifecycle — rebuild |
| `app/rentals/[id]` | Missing images, no overlap check, no approval step — rebuild |
| `app/profile` | Mostly display-only, missing edit + history — extend |
| `app/dashboard` | Good structure, needs role-aware content split — extend |
| `app/admin/*` | Most complete section — keep and refine |
| `app/page.tsx` | All stubs — rebuild |
| `components/Animated*` | Solid, reusable — keep |

---

*End of audit. Suggested next step: Phase 1 schema changes + backend restructure.*

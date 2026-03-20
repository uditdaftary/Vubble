import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/rental_model.dart';
import '../../models/application_model.dart';
import '../../providers/gig_rental_providers.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/rating_sheet.dart';
import '../../theme/app_theme.dart' hide RentalCategory;

// ─────────────────────────────────────────────
//  MY RENTALS SCREEN
// ─────────────────────────────────────────────
class MyRentalsScreen extends ConsumerStatefulWidget {
  const MyRentalsScreen({super.key});
  @override
  ConsumerState<MyRentalsScreen> createState() => _MyRentalsScreenState();
}

class _MyRentalsScreenState extends ConsumerState<MyRentalsScreen>
    with TickerProviderStateMixin {
  late TabController _tabs;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() => setState(() {}));
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final owned = ref.watch(myOwnedRentalsProvider);
    final borrowed = ref.watch(myBorrowedRentalsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: NestedScrollView(
          headerSliverBuilder: (_, _) => [_appBar(), _tabBar()],
          body: TabBarView(
            controller: _tabs,
            children: [
              // ── Tab 1: Items I Own ───────────────
              owned.when(
                loading: () => _LoadingState(),
                error: (e, _) => _ErrorState(message: e.toString()),
                data: (items) => items.isEmpty
                    ? _EmptyState(
                        emoji: '📦',
                        title: 'No items listed',
                        sub: 'List your idle items and earn while they sit.',
                        actionLabel: 'List an Item',
                        onAction: () =>
                            Navigator.pushNamed(context, '/rentals/list'),
                      )
                    : _RentalList(items: items, role: _RentalRole.owner),
              ),

              // ── Tab 2: Items I'm Borrowing ───────
              borrowed.when(
                loading: () => _LoadingState(),
                error: (e, _) => _ErrorState(message: e.toString()),
                data: (items) => items.isEmpty
                    ? _EmptyState(
                        emoji: '🔍',
                        title: 'Nothing borrowed yet',
                        sub: 'Find items from other students on campus.',
                        actionLabel: 'Browse Rentals',
                        onAction: () =>
                            Navigator.pushNamed(context, '/rentals'),
                      )
                    : _RentalList(items: items, role: _RentalRole.renter),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── app bar ───────────────────────────────────
  Widget _appBar() => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('My Rentals', style: AppText.display(size: 28)),
          const SizedBox(height: 4),
          Text(
            'Manage items you own and items you borrow.',
            style: AppText.body(size: 14, color: AppColors.textMuted),
          ),
        ],
      ),
    ),
  );

  // ── tab bar ───────────────────────────────────
  Widget _tabBar() => SliverPersistentHeader(
    pinned: true,
    delegate: _StickyTab(
      TabBar(
        controller: _tabs,
        indicatorColor: AppColors.cyan,
        indicatorWeight: 2,
        labelColor: AppColors.textPrimary,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 13),
        tabs: [
          _tabItem(
            'My Items',
            ref.watch(myOwnedRentalsProvider).valueOrNull?.length,
          ),
          _tabItem(
            'Borrowing',
            ref.watch(myBorrowedRentalsProvider).valueOrNull?.length,
          ),
        ],
      ),
    ),
  );

  Tab _tabItem(String label, int? count) => Tab(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        if (count != null && count > 0) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.cyan.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.syne(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.cyan,
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

// ─────────────────────────────────────────────
//  RENTAL LIST
// ─────────────────────────────────────────────
enum _RentalRole { owner, renter }

class _RentalList extends StatelessWidget {
  final List<RentalModel> items;
  final _RentalRole role;
  const _RentalList({required this.items, required this.role});

  @override
  Widget build(BuildContext context) {
    final activeStatuses = {
      RentalStatus.requested,
      RentalStatus.active,
      RentalStatus.returnPending,
      RentalStatus.available,
    };
    final active = items
        .where((r) => activeStatuses.contains(r.status))
        .toList();
    final done = items
        .where((r) => !activeStatuses.contains(r.status))
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        if (active.isNotEmpty) ...[
          _sectionLabel('ACTIVE  (${active.length})'),
          const SizedBox(height: 10),
          ...active.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RentalCard(rental: r, role: role),
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (done.isNotEmpty) ...[
          _sectionLabel('HISTORY  (${done.length})'),
          const SizedBox(height: 10),
          ...done.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RentalCard(rental: r, role: role),
            ),
          ),
        ],
      ],
    );
  }

  Widget _sectionLabel(String t) => Text(t, style: AppText.label());
}

// ─────────────────────────────────────────────
//  RENTAL CARD  — state-aware
// ─────────────────────────────────────────────
class _RentalCard extends ConsumerWidget {
  final RentalModel rental;
  final _RentalRole role;
  const _RentalCard({required this.rental, required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cc = _catColor(rental.category);

    return SurfaceCard(
      borderColor: rental.isOverdue ? AppColors.coral.withValues(alpha: 0.5) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── header ──────────────────────────────
          Row(
            children: [
              // emoji icon
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: cc.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cc.withValues(alpha: 0.25)),
                ),
                child: Center(
                  child: Text(
                    rental.category.emoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rental.itemName, style: AppText.heading(size: 15)),
                    const SizedBox(height: 2),
                    CategoryBadge(label: rental.category.label, color: cc),
                  ],
                ),
              ),
              _StatusPill(status: rental.status),
            ],
          ),
          const SizedBox(height: 12),

          // ── pricing row ──────────────────────────
          Row(
            children: [
              Text('₹${rental.dailyRate}', style: AppText.price(size: 16)),
              Text(
                '/day',
                style: AppText.body(size: 12, color: AppColors.textMuted),
              ),
              if (rental.deposit > 0) ...[
                const SizedBox(width: 10),
                Text(
                  '+ ₹${rental.deposit} deposit',
                  style: AppText.body(size: 12, color: AppColors.textMuted),
                ),
              ],
              const Spacer(),
              // days remaining pill (only when active)
              if (rental.isActive && rental.rentalEnd != null) ...[
                if (rental.isOverdue)
                  _OverduePill()
                else
                  _DaysRemainingPill(days: rental.daysRemaining),
              ],
            ],
          ),

          // ── rental period ────────────────────────
          if (rental.rentalStart != null && rental.rentalEnd != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.date_range_rounded,
                  size: 13,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 5),
                Text(
                  '${_fmtDate(rental.rentalStart!)} → ${_fmtDate(rental.rentalEnd!)}  '
                  '(${rental.rentalDays} day${rental.rentalDays != 1 ? 's' : ''})',
                  style: AppText.body(size: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ],

          // ── renter/owner info row ─────────────────
          if (rental.renterId != null) ...[
            const SizedBox(height: 10),
            Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.person_rounded,
                  size: 14,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  role == _RentalRole.owner
                      ? 'Renter: ${rental.renterName}'
                      : 'Owner: ${rental.ownerName}',
                  style: AppText.body(size: 12, color: AppColors.textMuted),
                ),
                const Spacer(),
                StarRating(rating: rental.ownerRating),
              ],
            ),
          ],

          // ── total cost summary (when active) ──────
          if (rental.isActive && rental.rentalDays > 0) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    'Total value',
                    style: AppText.body(size: 12, color: AppColors.textMuted),
                  ),
                  const Spacer(),
                  Text(
                    '₹${rental.totalCost}',
                    style: GoogleFonts.syne(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.lime,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── action buttons ────────────────────────
          ..._buildActions(context, ref),
        ],
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context, WidgetRef ref) {
    final service = ref.read(rentalServiceProvider);
    final userId = ref.read(authStateProvider).valueOrNull?.uid ?? '';

    // ── OWNER actions ────────────────────────────
    if (role == _RentalRole.owner) {
      if (rental.isAvailable) {
        return [
          const SizedBox(height: 12),
          // Application count badge
          if (rental.applicationCount > 0) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.cyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.cyan.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.people_rounded,
                    size: 16,
                    color: AppColors.cyan,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${rental.applicationCount} application${rental.applicationCount > 1 ? "s" : ""}',
                    style: AppText.body(
                      size: 13,
                      color: AppColors.cyan,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _ActionButton(
              label: 'View Applications',
              color: AppColors.cyan,
              icon: Icons.visibility_rounded,
              onTap: () => showModalBottomSheet(
                context: context,
                backgroundColor: AppColors.surface,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (_) => DraggableScrollableSheet(
                  initialChildSize: 0.6,
                  maxChildSize: 0.9,
                  minChildSize: 0.3,
                  expand: false,
                  builder: (ctx, sc) => _RentalApplicationsSheet(
                    rentalId: rental.rentalId,
                    rental: rental,
                    scrollController: sc,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          _ActionButton(
            label: 'Remove Listing',
            color: AppColors.coral,
            icon: Icons.delete_outline_rounded,
            onTap: () => _confirm(context, 'Remove this listing?', () async {
              await service.cancelListing(rental.rentalId, userId);
            }),
          ),
        ];
      }
      if (rental.isActive) {
        return [
          const SizedBox(height: 12),
          // Handoff confirmation (REQ-03)
          if (!rental.itemHandedOver)
            _ActionButton(
              label: 'Mark Item as Given',
              color: AppColors.cyan,
              icon: Icons.handshake_rounded,
              onTap: () =>
                  _confirm(context, 'Mark the item as handed over?', () async {
                    await service.markItemGiven(rental.rentalId);
                    _snack(context, 'Item marked as given ✅', AppColors.cyan);
                  }),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.lime.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '✅ Item Handed Over',
                  style: AppText.body(size: 13, color: AppColors.lime),
                ),
              ),
            ),
          // Early return (REQ-12)
          if (rental.earlyReturnRequested) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.amber.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_rounded,
                    size: 16,
                    color: AppColors.amber,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Renter requested early return',
                      style: AppText.body(size: 13, color: AppColors.amber),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _ActionButton(
              label: 'Approve Early Return',
              color: AppColors.lime,
              icon: Icons.check_circle_rounded,
              onTap: () => _confirm(context, 'Approve early return?', () async {
                await service.approveEarlyReturn(rental.rentalId);
              }),
            ),
          ],
        ];
      }
      if (rental.isReturnPending) {
        return [
          const SizedBox(height: 12),
          _ActionButton(
            label: 'Confirm Return Received',
            color: AppColors.lime,
            icon: Icons.inventory_2_rounded,
            onTap: () => _confirm(
              context,
              'Confirm you received the item back?',
              () async {
                await service.confirmReturn(rental.rentalId);
                if (context.mounted) {
                  await showRatingSheet(
                    context,
                    targetUserId: rental.renterId!,
                    reviewerUserId: userId,
                    sourceId: rental.rentalId,
                    sourceType: 'rental',
                  );
                  await service.markOwnerRated(rental.rentalId);
                }
              },
            ),
          ),
        ];
      }
      if (rental.isCompleted && !rental.ownerRated) {
        return [
          const SizedBox(height: 12),
          _ActionButton(
            label: 'Rate Renter',
            color: AppColors.amber,
            icon: Icons.star_rounded,
            onTap: () async {
              await showRatingSheet(
                context,
                targetUserId: rental.renterId!,
                reviewerUserId: userId,
                sourceId: rental.rentalId,
                sourceType: 'rental',
              );
              await service.markOwnerRated(rental.rentalId);
            },
          ),
        ];
      }
    }

    // ── RENTER actions ───────────────────────────
    if (role == _RentalRole.renter) {
      if (rental.isActive) {
        return [
          const SizedBox(height: 12),
          // Confirm item received (REQ-03)
          if (!rental.itemReceived)
            _ActionButton(
              label: 'Confirm Item Received',
              color: AppColors.cyan,
              icon: Icons.check_box_rounded,
              onTap: () =>
                  _confirm(context, 'Confirm you received the item?', () async {
                    await service.confirmItemReceived(rental.rentalId);
                    _snack(context, 'Item receipt confirmed ✅', AppColors.cyan);
                  }),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.lime.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '✅ Item Received',
                  style: AppText.body(size: 13, color: AppColors.lime),
                ),
              ),
            ),
          const SizedBox(height: 8),
          _ActionButton(
            label: rental.isOverdue
                ? 'Return Item (Overdue!)'
                : 'Initiate Return',
            color: rental.isOverdue ? AppColors.coral : AppColors.cyan,
            icon: Icons.keyboard_return_rounded,
            onTap: () => _confirm(context, 'Mark item as returned?', () async {
              await service.markReturnRequested(rental.rentalId);
            }),
          ),
          // Early return (REQ-12)
          if (!rental.earlyReturnRequested && !rental.isOverdue) ...[
            const SizedBox(height: 8),
            _ActionButton(
              label: 'Request Early Return',
              color: AppColors.amber,
              icon: Icons.fast_forward_rounded,
              onTap: () => _confirm(context, 'Request early return?', () async {
                await service.requestEarlyReturn(rental.rentalId);
                _snack(context, 'Early return requested', AppColors.amber);
              }),
            ),
          ] else if (rental.earlyReturnRequested) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '⏳ Early return requested',
                  style: AppText.body(size: 13, color: AppColors.amber),
                ),
              ),
            ),
          ],
        ];
      }
      if (rental.isRequested) {
        return [
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.amber),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Waiting for owner approval…',
                  style: AppText.body(size: 13, color: AppColors.amber),
                ),
              ],
            ),
          ),
        ];
      }
      if (rental.isCompleted && !rental.renterRated) {
        return [
          const SizedBox(height: 12),
          _ActionButton(
            label: 'Rate Owner',
            color: AppColors.amber,
            icon: Icons.star_rounded,
            onTap: () async {
              await showRatingSheet(
                context,
                targetUserId: rental.ownerId,
                reviewerUserId: userId,
                sourceId: rental.rentalId,
                sourceType: 'rental',
              );
              await service.markRenterRated(rental.rentalId);
            },
          ),
        ];
      }
    }

    return [];
  }

  String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  Color _catColor(RentalCategory cat) {
    switch (cat) {
      case RentalCategory.electronics:
        return AppColors.cyan;
      case RentalCategory.labGear:
        return AppColors.violet;
      case RentalCategory.books:
        return AppColors.lime;
      case RentalCategory.sports:
        return AppColors.coral;
      case RentalCategory.clothing:
        return AppColors.amber;
      case RentalCategory.other:
        return const Color(0xFF7777AA);
    }
  }

  Future<void> _confirm(
    BuildContext context,
    String message,
    Future<void> Function() action,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDialog(message: message),
    );
    if (ok == true && context.mounted) {
      await action();
      _snack(context, 'Done ✅', AppColors.cyan);
    }
  }

  void _snack(BuildContext context, String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.plusJakartaSans(color: Colors.white),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SHARED SMALL WIDGETS
// ─────────────────────────────────────────────
class _StatusPill extends StatelessWidget {
  final RentalStatus status;
  const _StatusPill({required this.status});

  Color get _color {
    switch (status) {
      case RentalStatus.available:
        return AppColors.lime;
      case RentalStatus.requested:
        return AppColors.amber;
      case RentalStatus.active:
        return AppColors.cyan;
      case RentalStatus.returnPending:
        return AppColors.violet;
      case RentalStatus.completed:
        return AppColors.textMuted;
      case RentalStatus.disputed:
        return AppColors.coral;
      case RentalStatus.cancelled:
        return AppColors.coral;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: _color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: _color.withValues(alpha: 0.35)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(status.label, style: AppText.label(size: 10, color: _color)),
      ],
    ),
  );
}

class _DaysRemainingPill extends StatelessWidget {
  final int days;
  const _DaysRemainingPill({required this.days});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.cyan.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      '$days day${days != 1 ? 's' : ''} left',
      style: AppText.label(size: 10, color: AppColors.cyan),
    ),
  );
}

class _OverduePill extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.coral.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      'OVERDUE',
      style: AppText.label(size: 10, color: AppColors.coral),
    ),
  );
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.syne(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ConfirmDialog extends StatelessWidget {
  final String message;
  const _ConfirmDialog({required this.message});
  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: AppColors.surface,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    title: Text('Confirm', style: AppText.heading(size: 16)),
    content: Text(
      message,
      style: AppText.body(size: 14, color: AppColors.textMuted),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: Text(
          'Cancel',
          style: AppText.body(size: 14, color: AppColors.textMuted),
        ),
      ),
      GestureDetector(
        onTap: () => Navigator.pop(context, true),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.cyan,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Confirm',
            style: GoogleFonts.syne(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ),
      ),
    ],
  );
}

class _LoadingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Center(
    child: CircularProgressIndicator(color: AppColors.cyan, strokeWidth: 2),
  );
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});
  @override
  Widget build(BuildContext context) => Center(
    child: Text('Error: $message', style: AppText.body(color: AppColors.coral)),
  );
}

class _EmptyState extends StatelessWidget {
  final String emoji, title, sub, actionLabel;
  final VoidCallback onAction;
  const _EmptyState({
    required this.emoji,
    required this.title,
    required this.sub,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 32),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 52)),
        const SizedBox(height: 20),
        Text(
          title,
          style: AppText.heading(size: 18),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          sub,
          style: AppText.body(size: 14, color: AppColors.textMuted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        GradientButton(
          label: actionLabel,
          onTap: onAction,
          width: 220,
          colors: [const Color(0xFF0099BB), AppColors.cyan],
        ),
      ],
    ),
  );
}

class _StickyTab extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _StickyTab(this.tabBar);
  @override
  double get minExtent => tabBar.preferredSize.height + 1;
  @override
  double get maxExtent => tabBar.preferredSize.height + 1;
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => Container(
    color: AppColors.bg,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        tabBar,
        Divider(height: 1, color: AppColors.border),
      ],
    ),
  );
  @override
  bool shouldRebuild(_StickyTab old) => false;
}

// ─────────────────────────────────────────────
//  RENTAL APPLICATIONS SHEET (REQ-01)
// ─────────────────────────────────────────────
class _RentalApplicationsSheet extends ConsumerWidget {
  final String rentalId;
  final RentalModel rental;
  final ScrollController scrollController;
  const _RentalApplicationsSheet({
    required this.rentalId,
    required this.rental,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appsAsync = ref.watch(rentalApplicationsProvider(rentalId));
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Applications', style: AppText.heading(size: 20)),
          const SizedBox(height: 16),
          appsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(
                color: AppColors.cyan,
                strokeWidth: 2,
              ),
            ),
            error: (e, _) =>
                Text('Error: $e', style: AppText.body(color: AppColors.coral)),
            data: (apps) {
              if (apps.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Center(
                    child: Column(
                      children: [
                        const Text('📭', style: TextStyle(fontSize: 40)),
                        const SizedBox(height: 12),
                        Text(
                          'No applications yet',
                          style: AppText.heading(size: 16),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return Column(
                children: apps
                    .map(
                      (app) => _RentalApplicantTile(
                        app: app,
                        rentalId: rentalId,
                        rental: rental,
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RentalApplicantTile extends ConsumerWidget {
  final ApplicationModel app;
  final String rentalId;
  final RentalModel rental;
  const _RentalApplicantTile({
    required this.app,
    required this.rentalId,
    required this.rental,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    app.applicantName.isNotEmpty
                        ? app.applicantName[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.syne(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.cyan,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(app.applicantName, style: AppText.heading(size: 14)),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 13,
                          color: AppColors.amber,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          app.applicantRating.toStringAsFixed(1),
                          style: AppText.body(
                            size: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (app.isPending)
                GestureDetector(
                  onTap: () async {
                    // Pick rental start date
                    final start = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 60)),
                      helpText: 'Select Rental Start Date',
                      builder: (ctx, child) => Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: AppColors.cyan,
                            surface: AppColors.surface,
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (start == null || !context.mounted) return;
                    // Pick rental end date
                    final end = await showDatePicker(
                      context: context,
                      initialDate: start,
                      firstDate: start,
                      lastDate: start.add(const Duration(days: 60)),
                      helpText: 'Select Rental End Date',
                      builder: (ctx, child) => Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: AppColors.cyan,
                            surface: AppColors.surface,
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (end == null || !context.mounted) return;

                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => _ConfirmDialog(
                        message:
                            'Select ${app.applicantName}?\n${start.day}/${start.month} → ${end.day}/${end.month}',
                      ),
                    );
                    if (confirm == true) {
                      await ref
                          .read(rentalServiceProvider)
                          .selectRentalApplicant(
                            rentalId: rentalId,
                            applicantUserId: app.applicantId,
                            rentalStart: start,
                            rentalEnd: end,
                          );
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0099BB), AppColors.cyan],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Select',
                      style: GoogleFonts.syne(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: app.isAccepted
                        ? AppColors.lime.withValues(alpha: 0.15)
                        : AppColors.coral.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    app.status.toUpperCase(),
                    style: AppText.label(
                      size: 10,
                      color: app.isAccepted ? AppColors.lime : AppColors.coral,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            app.message,
            style: AppText.body(
              size: 13,
              color: AppColors.textMuted,
            ).copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}

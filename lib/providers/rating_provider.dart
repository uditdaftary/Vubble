import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/rating_service.dart';

// ── Service provider ──────────────────────────────────────────────────────────

final ratingServiceProvider = Provider<RatingService>((ref) => RatingService());

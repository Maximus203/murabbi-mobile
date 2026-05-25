import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/data/repositories/niyyah_repository_provider.dart';
import 'package:murabbi_mobile/data/repositories/niyyah_suggestion_repository_provider.dart';
import 'package:murabbi_mobile/domain/use_cases/niyyah/resolve_today_niyyah_use_case.dart';
import 'package:murabbi_mobile/presentation/features/auth/providers/auth_notifier.dart';

final resolveTodayNiyyahUseCaseProvider =
    Provider<ResolveTodayNiyyahUseCase>((ref) {
  return ResolveTodayNiyyahUseCase(
    ref.watch(niyyahRepositoryProvider),
    ref.watch(niyyahSuggestionRepositoryProvider),
  );
});

/// Niyyah du jour de l'utilisateur (personnelle ou suggestion système en rotation).
///
/// `null` si aucun utilisateur authentifié ou si aucune suggestion active
/// n'est disponible.
final niyyahProvider = FutureProvider<ResolvedNiyyah?>((ref) async {
  final user = ref.watch(authNotifierProvider).valueOrNull;
  if (user == null) return null;
  return ref.watch(resolveTodayNiyyahUseCaseProvider).call(
    userId: user.id,
    referenceDate: DateTime.now(),
  );
});

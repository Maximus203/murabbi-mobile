import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/data/repositories/niyyah_repository_provider.dart';
import 'package:murabbi_mobile/data/repositories/niyyah_suggestion_repository_provider.dart';
import 'package:murabbi_mobile/domain/entities/niyyah_display_item.dart';
import 'package:murabbi_mobile/domain/use_cases/niyyah/resolve_today_niyyah_use_case.dart';
import 'package:murabbi_mobile/presentation/features/auth/providers/auth_notifier.dart';

final resolveTodayNiyyahUseCaseProvider =
    Provider<ResolveTodayNiyyahUseCase>((ref) {
  return ResolveTodayNiyyahUseCase(
    niyyahRepository: ref.watch(niyyahRepositoryProvider),
    suggestionRepository: ref.watch(niyyahSuggestionRepositoryProvider),
  );
});

/// Niyyah du jour de l'utilisateur (personnelle ou suggestion système en rotation).
///
/// `null` si aucun utilisateur authentifié.
final niyyahProvider = FutureProvider<NiyyahDisplayItem?>((ref) async {
  final user = ref.watch(authNotifierProvider).valueOrNull;
  if (user == null) return null;
  return ref.watch(resolveTodayNiyyahUseCaseProvider).call(
    user.id,
    referenceDate: DateTime.now(),
  );
});

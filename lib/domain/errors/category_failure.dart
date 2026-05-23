import 'package:equatable/equatable.dart';

/// Erreurs typées remontées par la couche `data` Categories.
///
/// Créée dans le cadre de l'issue #202 (M3) pour exposer un
/// `CategoryFailure.unauthorized()` symétrique à
/// `HabitFailure.unauthorized()` et `CollectionFailure.unauthorized()`
/// — protection de défense en profondeur côté client avant tout appel
/// réseau (la RLS Supabase reste la protection finale).
sealed class CategoryFailure extends Equatable implements Exception {
  final String? message;

  const CategoryFailure._({this.message});

  /// Défense en profondeur : `userId` demandé ≠ utilisateur authentifié.
  const factory CategoryFailure.unauthorized({String? message}) =
      CategoryUnauthorizedFailure;

  @override
  List<Object?> get props => [runtimeType, message];

  @override
  String toString() => '$runtimeType(${message ?? ''})';
}

class CategoryUnauthorizedFailure extends CategoryFailure {
  const CategoryUnauthorizedFailure({super.message}) : super._();
}

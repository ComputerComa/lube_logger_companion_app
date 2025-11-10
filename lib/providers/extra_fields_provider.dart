import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lube_logger_companion_app/data/models/extra_field_definition.dart';
import 'package:lube_logger_companion_app/providers/auth_provider.dart';
import 'package:lube_logger_companion_app/providers/auth_helpers.dart';
import 'package:lube_logger_companion_app/providers/vehicle_provider.dart';
import 'package:lube_logger_companion_app/services/cached_data_helper.dart';

final extraFieldDefinitionsProvider =
    FutureProvider<List<RecordExtraFields>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final repository = ref.watch(repositoryProvider);

  final credentials = getCredentials(authState);

  final cacheKey = CachedDataHelper.generalCacheKey(
    'extra_fields',
    credentials.serverUrl,
    credentials.username,
  );

  return CachedDataHelper.fetchWithCache<RecordExtraFields>(
    fetchFn: () => repository.getExtraFieldDefinitions(
      serverUrl: credentials.serverUrl,
      username: credentials.username,
      password: credentials.password,
    ),
    cacheKey: cacheKey,
    fromJson: (json) => RecordExtraFields.fromJson(json),
    toJson: (item) => item.toJson(),
  );
});


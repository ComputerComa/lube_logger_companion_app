import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lube_logger_companion_app/data/models/version_info.dart';
import 'package:lube_logger_companion_app/providers/auth_provider.dart';
import 'package:lube_logger_companion_app/providers/auth_helpers.dart';
import 'package:lube_logger_companion_app/providers/vehicle_provider.dart';

final serverVersionProvider = FutureProvider<VersionInfo>((ref) async {
  final authState = ref.watch(authStateProvider);
  final repository = ref.watch(repositoryProvider);

  final credentials = getCredentials(authState);

  return repository.getServerVersion(
    serverUrl: credentials.serverUrl,
    username: credentials.username,
    password: credentials.password,
    checkForUpdate: true,
  );
});


import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

abstract class WorkspaceRemoteDataSource {
  Future<List<Workspace>> getOrganisations();
}

class WorkspaceRemoteDataSourceImpl implements WorkspaceRemoteDataSource {
  final ApiBaseService apiBaseService;

  WorkspaceRemoteDataSourceImpl({required this.apiBaseService});

  @override
  Future<List<Workspace>> getOrganisations() async {
    final response = await apiBaseService.get<Map<String, dynamic>>(
      path: '/users/organisations',
    );
    final data = response.data['data'] as List<dynamic>? ?? [];

    final List<Workspace> workspaces = [];
    for (final item in data) {
      if (item is Map<String, dynamic>) {
        final rawId = item['id'];
        final id =
            rawId is String ? rawId.trim() : (rawId?.toString().trim() ?? '');
        if (id.isEmpty) {
          // Without an id the workspace cannot be selected or addressed.
          // Skipping it is better than collapsing every id-less organisation
          // onto one shared workspace id.
          AppLogger.w(
            'Skipping organisation without an id',
            tag: 'WorkspaceNotifier',
          );
          continue;
        }
        workspaces.add(
          Workspace(
            id: id,
            name: item['name'] as String? ?? 'Workspace',
            avatar: item['logo_url'] as String? ?? '',
            channelsCount: (item['channels_count'] as num?)?.toInt() ?? 0,
          ),
        );
      }
    }
    return workspaces;
  }
}

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
    for (var item in data) {
      if (item is Map<String, dynamic>) {
        workspaces.add(
          Workspace(
            id: item['id'] as String? ?? '1',
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

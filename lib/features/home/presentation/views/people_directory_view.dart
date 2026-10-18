import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

/// The Home pane that lists the workspace's people. It opens from the
/// sidebar's "View all people" button.
class PeopleDirectoryView extends ConsumerStatefulWidget {
  const PeopleDirectoryView({super.key});

  @override
  ConsumerState<PeopleDirectoryView> createState() =>
      _PeopleDirectoryViewState();
}

class _PeopleDirectoryViewState extends ConsumerState<PeopleDirectoryView> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileNotifierProvider);
    final colors = context.colors;
    final textTheme = context.textTheme;

    final query = _searchQuery.trim().toLowerCase();
    final people = profile.teamMembers.where((member) {
      if (query.isEmpty) return true;
      return (member.name ?? '').toLowerCase().contains(query) ||
          member.email.toLowerCase().contains(query);
    }).toList();

    return Material(
      color: colors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Text(
              'People',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search for people',
                hintStyle: textTheme.bodyMedium?.copyWith(
                  color: colors.textHint,
                ),
                prefixIcon: Icon(Icons.search, color: colors.textHint),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: colors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: colors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: colors.primary),
                ),
              ),
              style: textTheme.bodyMedium?.copyWith(color: colors.textPrimary),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            child: Text(
              'Showing ${people.length} of ${profile.teamMembers.length} members',
              style: textTheme.bodySmall?.copyWith(color: colors.textHint),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildBody(profile, people, colors, textTheme)),
        ],
      ),
    );
  }

  Widget _buildBody(
    UserProfileState profile,
    List<TeamMember> people,
    AppPalette colors,
    TextTheme textTheme,
  ) {
    if (profile.isLoading && profile.teamMembers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (profile.teamMembers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            profile.error ?? 'No people found.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
          ),
        ),
      );
    }
    if (people.isEmpty) {
      return Center(
        child: Text(
          'No people match your search.',
          style: textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
        ),
      );
    }
    return ListView.separated(
      itemCount: people.length,
      separatorBuilder: (_, _) => Divider(height: 1, color: colors.divider),
      itemBuilder: (context, index) => _PersonRow(member: people[index]),
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({required this.member});

  final TeamMember member;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.textTheme;
    final name = _displayName(member);
    final (statusLabel, statusColor) = switch (member.status) {
      TeamMemberStatus.active => ('Active', colors.success),
      TeamMemberStatus.pending => ('Pending', colors.textSecondary),
      TeamMemberStatus.inactive => ('Inactive', colors.textHint),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: colors.primary.withValues(alpha: 0.12),
            child: Text(
              _initials(name),
              style: TextStyle(
                color: colors.primary,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  member.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(color: colors.textHint),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            statusLabel,
            style: textTheme.bodySmall?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

String _displayName(TeamMember member) {
  final name = (member.name ?? '').trim();
  return name.isNotEmpty ? name : member.email.split('@').first;
}

String _initials(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '?';
  return trimmed.substring(0, trimmed.length > 1 ? 2 : 1).toUpperCase();
}

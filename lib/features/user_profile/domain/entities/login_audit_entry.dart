/// One sign-in event from `GET /users/{id}/login-audit`.
class LoginAuditEntry {
  const LoginAuditEntry({
    required this.id,
    required this.device,
    required this.location,
    required this.ipAddress,
    required this.isLive,
    this.loginAt,
    this.createdAt,
  });

  final String id;
  final String device;
  final String location;
  final String ipAddress;
  final DateTime? loginAt;
  final DateTime? createdAt;
  final bool isLive;
}

/// One page of the login audit, with the paging fields the backend returns.
class LoginAuditPage {
  const LoginAuditPage({
    required this.entries,
    required this.currentPage,
    required this.totalPages,
  });

  const LoginAuditPage.empty()
    : entries = const [],
      currentPage = 1,
      totalPages = 0;

  final List<LoginAuditEntry> entries;
  final int currentPage;
  final int totalPages;

  bool get hasMore => currentPage < totalPages;
}

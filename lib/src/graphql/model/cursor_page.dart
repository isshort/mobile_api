/// Cursor paginated GraphQL payload.
final class CursorPage<T> {
  /// Creates a cursor page with decoded items and page metadata.
  const CursorPage({
    required this.items,
    required this.hasNextPage,
    this.endCursor,
  });

  /// Decoded page items.
  final List<T> items;

  /// Whether another page is available.
  final bool hasNextPage;

  /// Cursor for the next page when provided by the server.
  final String? endCursor;
}

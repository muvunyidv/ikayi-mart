/// URL-safe slug used for `/store/:slug` deep links.
String slugifyStoreName(String value) {
  final slug = value
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return slug;
}

/// Store channel path. Prefers [slug]; falls back to a slugified [name].
String storePathFor({String? slug, String? name}) {
  final fromSlug = slug?.trim() ?? '';
  if (fromSlug.isNotEmpty) return '/store/$fromSlug';
  final fromName = slugifyStoreName(name ?? '');
  if (fromName.isEmpty) return '';
  return '/store/$fromName';
}

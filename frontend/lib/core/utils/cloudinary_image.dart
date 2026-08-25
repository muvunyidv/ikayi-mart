/// Cloudinary delivery helpers for marketplace product photos.
abstract final class CloudinaryImage {
  static const _uploadMarker = '/image/upload/';

  /// Square fill transform for list/card thumbnails. Leaves non-Cloudinary
  /// URLs (and already-transformed Cloudinary URLs) unchanged.
  static String thumbnail(String url, {int size = 200}) {
    if (url.isEmpty || size <= 0) return url;
    final index = url.indexOf(_uploadMarker);
    if (index < 0) return url;
    final insertAt = index + _uploadMarker.length;
    final rest = url.substring(insertAt);
    if (rest.startsWith('c_') || rest.contains('/c_fill,')) return url;
    return '${url.substring(0, insertAt)}c_fill,w_$size,h_$size,q_auto,f_auto/$rest';
  }
}

/// Parses the configured parking API URL using secure production defaults.
///
/// HTTPS is always accepted. Plain HTTP is accepted only when the caller
/// explicitly enables development access and the host is local or private.
Uri? parseParkingApiBaseUri(
  String value, {
  bool allowInsecureDevelopmentApi = false,
}) {
  final uri = Uri.tryParse(value.trim());
  if (uri == null ||
      !uri.hasAuthority ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment) {
    return null;
  }

  if (uri.scheme == 'https') return uri;
  if (uri.scheme != 'http' || !allowInsecureDevelopmentApi) return null;
  return _isDevelopmentHost(uri.host) ? uri : null;
}

bool _isDevelopmentHost(String host) {
  final normalizedHost = host.toLowerCase();
  if (normalizedHost == 'localhost' ||
      normalizedHost.endsWith('.localhost') ||
      normalizedHost == '::1' ||
      (normalizedHost.contains(':') &&
          (normalizedHost.startsWith('fc') ||
              normalizedHost.startsWith('fd') ||
              normalizedHost.startsWith('fe80:')))) {
    return true;
  }

  final octets = normalizedHost.split('.').map(int.tryParse).toList();
  if (octets.length != 4 ||
      octets.any((octet) => octet == null || octet < 0 || octet > 255)) {
    return false;
  }

  final first = octets[0]!;
  final second = octets[1]!;
  return first == 10 ||
      first == 127 ||
      (first == 169 && second == 254) ||
      (first == 172 && second >= 16 && second <= 31) ||
      (first == 192 && second == 168) ||
      (first == 100 && second >= 64 && second <= 127);
}

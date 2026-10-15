/// Converts a Windows-style wildcard pattern (* and ?) to a RegExp.
/// If the pattern contains no wildcards it matches as a substring.
RegExp wildcardToRegExp(String pattern, {bool caseSensitive = false}) {
  final hasWildcard = pattern.contains('*') || pattern.contains('?');
  final escaped = pattern.split('').map((c) {
    if (c == '*') return '.*';
    if (c == '?') return '.';
    return RegExp.escape(c);
  }).join();
  final source = hasWildcard ? '^$escaped\$' : escaped;
  return RegExp(source, caseSensitive: caseSensitive);
}

bool wildcardMatch(String pattern, String name, {bool caseSensitive = false}) =>
    wildcardToRegExp(pattern, caseSensitive: caseSensitive).hasMatch(name);

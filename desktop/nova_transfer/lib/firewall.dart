import 'dart:convert';
import 'dart:io';

/// Windows Firewall state for this exe — the most common reason a phone
/// can scan the QR yet never reach the PC: the network is marked
/// "Public" and the first-run firewall prompt was dismissed, so Windows
/// silently drops every inbound connection (a Block rule even beats any
/// Allow rule).
enum FirewallState { ok, blocked, unknown }

class FirewallHelper {
  FirewallHelper._();

  static String get _exe => Platform.resolvedExecutable;

  static String _psQuote(String s) => "'${s.replaceAll("'", "''")}'";

  static Future<ProcessResult> _ps(String script, {bool elevated = false}) {
    final encoded = base64.encode(
      // -EncodedCommand expects UTF-16LE — no quoting pitfalls.
      script.codeUnits.expand((c) => [c & 0xff, c >> 8]).toList(),
    );
    final args = elevated
        ? [
            '-NoProfile',
            '-NonInteractive',
            '-Command',
            "Start-Process powershell -Verb RunAs -Wait -WindowStyle Hidden "
                "-ArgumentList '-NoProfile','-ExecutionPolicy','Bypass',"
                "'-EncodedCommand','$encoded'",
          ]
        : [
            '-NoProfile',
            '-NonInteractive',
            '-ExecutionPolicy',
            'Bypass',
            '-EncodedCommand',
            encoded,
          ];
    return Process.run('powershell', args).timeout(const Duration(seconds: 60));
  }

  /// Checks that an enabled inbound Allow rule covers every active
  /// network category and no inbound Block rule targets this exe.
  static Future<FirewallState> check() async {
    if (!Platform.isWindows) return FirewallState.ok;
    final script =
        '''
\$p = ${_psQuote(_exe)}
\$r = @(Get-NetFirewallApplicationFilter -Program \$p -ErrorAction SilentlyContinue | Get-NetFirewallRule -ErrorAction SilentlyContinue | Where-Object { "\$(\$_.Direction)" -eq 'Inbound' -and "\$(\$_.Enabled)" -eq 'True' })
if (@(\$r | Where-Object { "\$(\$_.Action)" -eq 'Block' }).Count -gt 0) { 'blocked'; exit }
\$allow = @(\$r | Where-Object { "\$(\$_.Action)" -eq 'Allow' })
foreach (\$c in @(Get-NetConnectionProfile -ErrorAction SilentlyContinue)) {
  \$cat = "\$(\$c.NetworkCategory)" -replace 'DomainAuthenticated','Domain'
  if (-not (\$allow | Where-Object { "\$(\$_.Profile)" -eq 'Any' -or "\$(\$_.Profile)" -match \$cat })) { 'blocked'; exit }
}
'ok'
''';
    try {
      final res = await _ps(script);
      final out = '${res.stdout}'.trim().toLowerCase();
      if (out.endsWith('ok')) return FirewallState.ok;
      if (out.endsWith('blocked')) return FirewallState.blocked;
    } catch (_) {}
    return FirewallState.unknown;
  }

  /// Removes Block rules for this exe and adds one inbound Allow rule for
  /// all profiles (TCP pairing server + UDP discovery). Shows the UAC
  /// prompt; returns the state after the attempt.
  static Future<FirewallState> fix() async {
    if (!Platform.isWindows) return FirewallState.ok;
    final script =
        '''
\$p = ${_psQuote(_exe)}
Get-NetFirewallApplicationFilter -Program \$p -ErrorAction SilentlyContinue | Get-NetFirewallRule -ErrorAction SilentlyContinue | Where-Object { "\$(\$_.Action)" -eq 'Block' } | Remove-NetFirewallRule -ErrorAction SilentlyContinue
Remove-NetFirewallRule -DisplayName 'Nova Transfer' -ErrorAction SilentlyContinue
New-NetFirewallRule -DisplayName 'Nova Transfer' -Direction Inbound -Action Allow -Program \$p -Profile Any | Out-Null
''';
    try {
      await _ps(script, elevated: true);
    } catch (_) {}
    return check();
  }
}

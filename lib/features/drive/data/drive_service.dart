import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

/// Google Drive access via google_sign_in + googleapis.
/// Scope: drive.file — the smallest workable scope (the app can only see
/// files it created or the user opened via a Google picker; full-Drive
/// browsing would need the restricted drive.readonly scope).
class DriveService {
  static const _scope = drive.DriveApi.driveFileScope;

  /// google_sign_in 7.x on Android requires a Web OAuth client ID from the
  /// same Google Cloud project (used as serverClientId for Google ID
  /// resolution). The Android client itself is matched via package+SHA-1.
  static const _serverClientId =
      '1046100118640-s552g6uvdov83opjlg8kqgi6a9ck3bcb.apps.googleusercontent.com';

  final _signIn = GoogleSignIn.instance;
  GoogleSignInAccount? _account;
  drive.DriveApi? _api;
  bool _initialized = false;

  bool get isSignedIn => _api != null;
  String? get email => _account?.email;

  /// Last sign-in failure detail, shown on the sign-in page for diagnostics.
  String? lastError;

  Future<drive.DriveApi> _requireApi() async {
    if (_api == null) throw StateError('Not signed in');
    return _api!;
  }

  /// Interactive sign-in. Returns false when the user cancels.
  Future<bool> signIn() async {
    if (!_initialized) {
      await _signIn.initialize(serverClientId: _serverClientId);
      _initialized = true;
    }
    if (!_signIn.supportsAuthenticate()) return false;
    try {
      _account = await _signIn.authenticate();
      final authz = await _account!.authorizationClient.authorizeScopes([
        _scope,
      ]);
      _api = drive.DriveApi(_AuthClient(authz.accessToken));
      return true;
    } catch (e) {
      lastError = '$e';
      return false;
    }
  }

  /// Silent re-auth on app start (no UI). Returns false when unavailable.
  Future<bool> trySilentSignIn() async {
    if (!_initialized) {
      await _signIn.initialize(serverClientId: _serverClientId);
      _initialized = true;
    }
    try {
      final account = await _signIn.attemptLightweightAuthentication();
      if (account == null) return false;
      final authz = await account.authorizationClient.authorizeScopes([_scope]);
      _account = account;
      _api = drive.DriveApi(_AuthClient(authz.accessToken));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> signOut() async {
    await _signIn.signOut();
    _account = null;
    _api = null;
  }

  Future<List<drive.File>> list(String folderId) async {
    final api = await _requireApi();
    final res = await api.files.list(
      q: "'$folderId' in parents and trashed = false",
      orderBy: 'folder,name',
      $fields: 'files(id,name,mimeType,size,modifiedTime,parents)',
      pageSize: 500,
      supportsAllDrives: true,
      includeItemsFromAllDrives: true,
    );
    return res.files ?? [];
  }

  Future<String> createFolder(String name, String parentId) async {
    final api = await _requireApi();
    final f = await api.files.create(
      drive.File()
        ..name = name
        ..mimeType = 'application/vnd.google-apps.folder'
        ..parents = [parentId],
      supportsAllDrives: true,
    );
    return f.id!;
  }

  /// Downloads a file into [destDir]; returns the written path.
  Future<String> download(drive.File file, String destDir) async {
    final api = await _requireApi();
    final media = await api.files.get(
      file.id!,
      downloadOptions: drive.DownloadOptions.fullMedia,
      supportsAllDrives: true,
    ) as drive.Media;
    var out = '${destDir.replaceAll('\\', '/')}/${file.name}';
    var n = 1;
    while (File(out).existsSync()) {
      final dot = file.name!.lastIndexOf('.');
      out = dot > 0
          ? '$destDir/${file.name!.substring(0, dot)} ($n)${file.name!.substring(dot)}'
          : '$destDir/${file.name} ($n)';
      n++;
    }
    final sink = File(out).openWrite();
    await sink.addStream(media.stream);
    await sink.close();
    return out;
  }

  /// Uploads a local file into [folderId].
  Future<void> upload(String localPath, String folderId) async {
    final api = await _requireApi();
    final file = File(localPath);
    final name = localPath.substring(localPath.lastIndexOf('/') + 1);
    await api.files.create(
      drive.File()
        ..name = name
        ..parents = [folderId],
      uploadMedia: drive.Media(file.openRead(), await file.length()),
      supportsAllDrives: true,
    );
  }

  /// Moves a file/folder to another Drive folder.
  Future<void> move(drive.File file, String newParentId) async {
    final api = await _requireApi();
    await api.files.update(
      drive.File(),
      file.id!,
      addParents: newParentId,
      removeParents: file.parents?.join(','),
      supportsAllDrives: true,
    );
  }

  /// Renames a Drive item.
  Future<void> rename(drive.File file, String newName) async {
    final api = await _requireApi();
    await api.files.update(
      drive.File()..name = newName,
      file.id!,
      supportsAllDrives: true,
    );
  }

  /// Sends a Drive item to its trash.
  Future<void> trash(drive.File file) async {
    final api = await _requireApi();
    await api.files.update(
      drive.File()..trashed = true,
      file.id!,
      supportsAllDrives: true,
    );
  }

  /// Lists Drive folders anywhere (for the move-picker).
  Future<List<drive.File>> listFolders(String folderId) async {
    final api = await _requireApi();
    final res = await api.files.list(
      q: "'$folderId' in parents and mimeType = 'application/vnd.google-apps.folder' and trashed = false",
      orderBy: 'name',
      $fields: 'files(id,name)',
      pageSize: 500,
      supportsAllDrives: true,
      includeItemsFromAllDrives: true,
    );
    return res.files ?? [];
  }
}

/// Minimal authenticated HTTP client for googleapis.
class _AuthClient extends http.BaseClient {
  _AuthClient(this._token);
  final String _token;
  final _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_token';
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}

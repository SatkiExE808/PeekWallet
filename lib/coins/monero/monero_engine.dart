import 'dart:ffi';
import 'dart:io';

/// Thin wrapper around the monero_c native library — currently just
/// detects whether the .so was bundled into the APK and is loadable.
///
/// Full wallet lifecycle (create from keys, sync, balance, send) lands
/// on top of this in the next iteration. Splitting it out lets us
/// validate the native-library bundling end-to-end (CI builds → APK →
/// device opens .so) without committing to the much larger wallet
/// integration code.
class MoneroEngine {
  MoneroEngine._();
  static final I = MoneroEngine._();

  DynamicLibrary? _lib;
  String? _loadError;

  /// Tries to open libmonero_wallet2_api_c.so. Idempotent — subsequent
  /// calls return the cached state.
  EngineStatus status() {
    if (_lib != null) return const EngineStatus.loaded();
    if (_loadError != null) return EngineStatus.failed(_loadError!);

    final libName = _libNameForPlatform();
    if (libName == null) {
      _loadError = 'Unsupported platform ${Platform.operatingSystem}';
      return EngineStatus.failed(_loadError!);
    }

    try {
      _lib = DynamicLibrary.open(libName);
      return const EngineStatus.loaded();
    } catch (e) {
      // The most common failure: the .so didn't end up in jniLibs at
      // APK build time. Possible causes:
      // - scripts/prepare_monero.sh skipped this ABI
      // - The bundle's internal layout drifted (script's ARCH_MAP)
      // - Building locally without running the prepare script
      _loadError = e.toString();
      return EngineStatus.failed(_loadError!);
    }
  }

  String? _libNameForPlatform() {
    if (Platform.isAndroid) return 'libmonero_wallet2_api_c.so';
    if (Platform.isLinux) return 'libmonero_wallet2_api_c.so';
    if (Platform.isMacOS) return 'libmonero_wallet2_api_c.dylib';
    if (Platform.isWindows) return 'libmonero_wallet2_api_c.dll';
    if (Platform.isIOS) {
      // iOS links the library statically into the binary; FFI sees it
      // at the process level rather than as a .dylib file.
      return null;
    }
    return null;
  }
}

class EngineStatus {
  const EngineStatus.loaded() : loaded = true, error = null;
  const EngineStatus.failed(this.error) : loaded = false;
  final bool loaded;
  final String? error;
}

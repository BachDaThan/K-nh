import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Định danh offline: keypair trên máy, public key → short ID (không Google).
class MeshIdentity {
  static const _kPriv = 'kinh_mesh_priv_v1';
  static const _kPub = 'kinh_mesh_pub_v1';
  static const _kName = 'kinh_mesh_name_v1';

  final _storage = const FlutterSecureStorage();
  final _algo = Ed25519();

  SimpleKeyPair? _pair;
  String? publicId;
  String displayName = 'Ẩn danh';

  Future<void> loadOrCreate() async {
    displayName = (await _storage.read(key: _kName)) ?? _randomName();
    final pubB64 = await _storage.read(key: _kPub);
    final privB64 = await _storage.read(key: _kPriv);
    if (pubB64 != null && privB64 != null) {
      final pub = SimplePublicKey(base64Decode(pubB64), type: KeyPairType.ed25519);
      final priv = SimpleKeyPairData(
        base64Decode(privB64),
        publicKey: pub,
        type: KeyPairType.ed25519,
      );
      _pair = priv;
      publicId = _idFromPub(await priv.extractPublicKey());
      return;
    }
    _pair = await _algo.newKeyPair();
    final pub = await _pair!.extractPublicKey();
    final privData = await _pair!.extractPrivateKeyBytes();
    await _storage.write(key: _kPub, value: base64Encode(pub.bytes));
    await _storage.write(key: _kPriv, value: base64Encode(privData));
    await _storage.write(key: _kName, value: displayName);
    publicId = _idFromPub(pub);
  }

  Future<void> setName(String n) async {
    displayName = n.trim().isEmpty ? displayName : n.trim();
    await _storage.write(key: _kName, value: displayName);
  }

  String _idFromPub(SimplePublicKey pub) {
    final b = pub.bytes;
    var h = 0;
    for (final x in b) {
      h = (h * 31 + x) & 0x7fffffff;
    }
    return h.toRadixString(36).toUpperCase().padLeft(8, '0').substring(0, 8);
  }

  String _randomName() {
    const w = ['Fox', 'Lynx', 'Owl', 'Ray', 'Ko', 'An', 'Minh', 'Lan'];
    return '${w[Random().nextInt(w.length)]}${Random().nextInt(90) + 10}';
  }

  Future<Uint8List?> sign(Uint8List data) async {
    if (_pair == null) return null;
    final s = await _algo.sign(data, keyPair: _pair!);
    return Uint8List.fromList(s.bytes);
  }
}

final meshIdentity = MeshIdentity();

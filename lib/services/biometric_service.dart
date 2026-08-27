import 'package:local_auth/local_auth.dart';

/// Envoltura del autenticador del sistema (huella, rostro, PIN o patrón).
///
/// Ambos métodos traducen cualquier fallo a `false` en lugar de propagarlo: un
/// dispositivo sin biometría, sin enrolamiento o con el diálogo cancelado debe
/// dejar la aplicación bloqueada, no romperla.
class BiometricService {
  final LocalAuthentication _authentication = LocalAuthentication();

  Future<bool> isAvailable() async {
    try {
      return await _authentication.isDeviceSupported();
    } on Object {
      return false;
    }
  }

  Future<bool> authenticate() async {
    try {
      return await _authentication.authenticate(
        localizedReason: 'Autentícate para acceder a RootCause QR Inspector.',
        persistAcrossBackgrounding: true,
      );
    } on Object {
      return false;
    }
  }
}

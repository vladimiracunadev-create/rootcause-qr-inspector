# Lista de publicación

Esta lista describe lo necesario para llevar las aplicaciones móviles a las
tiendas. Desde 0.1.0 y hasta 0.2.0 el producto se distribuye como APK Android
directo mediante GitHub Release; Play Store, App Store e iOS instalable siguen
pendientes. El estado real de verificación está en
[`../VALIDATION.md`](../VALIDATION.md).

## Lo que falta no es trabajo de código

Los gates técnicos del APK están verdes y automatizados. Lo que bloquea las
tiendas son cuatro cosas que solo puede aportar quien es dueño del producto, y
por eso ninguna entrega las va a resolver sola:

| Bloqueo | Qué hace falta |
|---|---|
| Firma de producción Android | Un keystore propio y sus credenciales como secretos del repositorio. Hoy el APK se firma con la clave de depuración, que sirve para instalar y revisar, **no** para publicar |
| Cuenta de Play Console | Alta de desarrollador, ficha, capturas y la declaración de datos (cámara y almacenamiento local, telemetría cero) |
| Cuenta de Apple Developer y un macOS | `flutter build ipa` exige Xcode; sin host Apple no hay artefacto iOS que firmar |
| Política de privacidad publicada y correo de soporte | Ya existe [`PRIVACY_POLICY.md`](PRIVACY_POLICY.md); las tiendas la piden como URL estable, no como archivo del repositorio |

## Calidad

- [x] `flutter pub get`
- [x] `flutter analyze`
- [x] `flutter test`
- [x] `flutter build apk --release`
- [ ] `flutter build appbundle --release`
- [x] `flutter build web --release` como canal de demostración
- [ ] `flutter build ipa --release` en macOS

## Dispositivos

- [ ] Android API 24, versión actual y tres gamas de hardware.
- [ ] iPhone con Touch ID y Face ID.
- [ ] iPad y rotación.
- [ ] Cámara denegada, revocada y restaurada.
- [ ] Galería, PDF y memoria limitada.

## Banco de códigos

- [ ] Todos los formatos declarados.
- [ ] Invertidos, baja luz, pequeños, curvos, dañados y múltiples.
- [ ] URL sospechosas y esquemas bloqueados.
- [ ] Wi-Fi, OTP, vCard, VEVENT, GS1, pagos y AAMVA.
- [ ] PNG/SVG generado y relectura del resultado.

## Tiendas

- [ ] Identificador, firma y certificados.
- [ ] Íconos, splash, capturas y descripción.
- [ ] Política de privacidad final y correo de soporte.
- [ ] Declaraciones de uso de cámara, fotos, Face ID y datos.
- [ ] Revisión de dependencias y licencias.

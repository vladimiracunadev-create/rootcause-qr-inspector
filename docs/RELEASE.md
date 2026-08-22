# Lista de publicación

Esta lista describe lo necesario para llevar las aplicaciones móviles a las
tiendas. La 0.1.0 ya distribuye un APK Android directo mediante GitHub Release;
Play Store, App Store e iOS instalable siguen pendientes. El estado real de
verificación está en [`../VALIDATION.md`](../VALIDATION.md).

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

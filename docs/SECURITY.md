# Seguridad

## Modelo aplicado

1. No abrir contenido automáticamente.
2. Mostrar dominio y campos interpretados antes de actuar.
3. Elevar advertencias por señales heurísticas.
4. Exigir confirmación cuando existe riesgo o el usuario lo configuró.
5. No persistir automáticamente OTP, Wi-Fi con contraseña ni URLs con claves
   sensibles.
6. Cifrar historial e inventarios antes de escribirlos.
7. Guardar la llave de cifrado en el almacén seguro de la plataforma.
8. Permitir bloqueo local y sesión privada.

## Familias de señales

El motor declara 26 ids estables, documentados uno por uno en
[`rootcause/HEURISTICS.md`](rootcause/HEURISTICS.md):

- transporte y destino: HTTP, host vacío, IP, red privada, puerto y acortador;
- identidad: Punycode, mezcla de alfabetos, Unicode, subdominios, guiones,
  punto final y política de marca;
- ofuscación: `userinfo`, autoridad ambigua, separadores codificados, longitud,
  controles crudos/porcentuales y seguimiento excesivo;
- intención: ruta de credenciales, redirección externa, descarga, OTP, pago y
  carga binaria;
- ejecución: esquema no permitido.

Los hallazgos generan hipótesis separadas. Puntaje no significa probabilidad y
una hipótesis no es un veredicto.

## Alcance

El analizador no consulta reputación de dominios y no declara que un enlace sea seguro. Solo presenta señales locales. Una versión empresarial podría añadir una fuente de reputación opcional y explícita, con política de privacidad separada.

La evidencia redactada omite carga, campos interpretados y `effectiveUri` para
evitar una fuga secundaria. Los respaldos importados se reanalizan; no se
confían sus ids, puntajes ni decisiones.

## Reporte

No incluyas secretos, claves OTP ni documentos personales en un reporte público. Entrega una descripción mínima, plataforma, versión y pasos reproducibles.

## Consideraciones por plataforma

- Android desactiva `allowBackup` para evitar que una llave de Keystore sea restaurada sin su material criptográfico compatible.
- La PWA debe publicarse únicamente por HTTPS, con HSTS y cabeceras de seguridad apropiadas; el almacenamiento seguro web depende del origen del navegador.
- La exportación JSON, CSV y XLSX contiene datos descifrados por decisión explícita del usuario. Debe tratarse como información sensible fuera de la aplicación.

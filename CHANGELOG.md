# Changelog

Alle nennenswerten Änderungen an diesem Projekt.
Format orientiert sich an [Keep a Changelog](https://keepachangelog.com/de/).

## [Unreleased]

### Hinzugefügt
- **QR-Code-Flow:** `pwa-install.html` als QR-Ziel, die App-`index.html` als
  `start_url`; automatische Weiterleitung im App-Modus.
- **Android:** Ein-Klick-Installation über `beforeinstallprompt`.
- **iOS-Anleitung als animiertes GIF**, erzeugt mit einem **selbst geschriebenen
  GIF-Encoder** (`tools/make-gif.ps1`, inkl. LZW), da auf dem Rechner weder
  ImageMagick noch ffmpeg vorhanden war.
- **Zweites GIF für iOS 26** („Kompakt"-Layout, Weg über das •••-Menü) +
  automatische Auswahl je nach iOS-Version.
- **Blazor-WebAssembly-Variante** mit identischem Flow (JS-Interop ↔ `PwaInstall.razor`).
- **Diagnose-Feld** auf der Install-Seite (Protokoll, Service Worker, Manifest,
  erkannte Plattform/Version).
- **Wartungs-Button** „Cache leeren & neu laden" auf `index.html` und `pwa-install.html`.
- **QR-Code-Generator** (`tools/make-qr.js`) inkl. erzeugtem `qr-pwa-install.png`.
- **Doku:** Integrations-Anleitung für gehostete Blazor-WASM-Lösungen
  (Server/Client/Shared) unter `docs/`.

### Geändert
- **Service Worker von cache-first auf network-first** umgestellt, damit Updates
  (HTML/GIF) zuverlässig ankommen und nicht im Cache „kleben".
- GIF-Beschriftungen um ca. 50 % vergrößert; Titel „Meine App".

### Behoben
- **iOS-26-Erkennung trotz eingefrorenem User-Agent.** Seit iOS 26 friert Safari
  die Angabe `CPU iPhone OS` dauerhaft auf `18_6` ein (Datenschutz); die echte
  Version steht nur noch im Token `Version/26.0`. Die Erkennung las bisher `18`
  und zeigte deshalb auf jedem iOS-26-Gerät das falsche (klassische) GIF.
  **Fix:** Maximum aus `OS x_y` und `Version/xx` – der Safari-Major entspricht ab
  iOS 26 dem echten iOS-Major.

[Unreleased]: https://github.com/ari-lzkth/pwa-install-kit

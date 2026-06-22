# pwa-install-kit

<p align="center">
  <img src="qr-pwa-install.png" alt="QR-Code zur Installations-Seite" width="240" /><br />
  <sub>📱 Scannen → App installieren<br />
  <a href="https://ari-lzkth.github.io/pwa-install-kit/pwa-install.html" target="_blank" rel="noopener noreferrer">https://ari-lzkth.github.io/pwa-install-kit/pwa-install.html</a></sub>
</p>

Eine installierbare **Progressive Web App (PWA)**, die per **QR-Code** verteilt wird:
Der QR-Code führt auf eine Installations-Seite, von der aus sich die App mit
**einem Tap** (Android) bzw. einer geführten Anleitung (iOS) auf den
Startbildschirm legen lässt. Sobald die App installiert ist, startet sie direkt
in der eigentlichen App-Seite.

> **Dieses Repository enthält zwei Varianten desselben PWA-Installations-Flows:**
> eine **statische Variante** (reines HTML/JS, im Repo-Root) und eine
> **Razor/Blazor-Variante** (.NET 8, im Ordner [`Blazor/`](Blazor/)).
> **GitHub Pages** wird bewusst nur für die statische Variante genutzt.

---

## Die zwei Varianten in diesem Repo

Beide setzen denselben PWA-Installations-Flow um – einmal ohne und einmal mit
Framework:

| Variante | Ort im Repo | Technik | Hosting | Zweck |
|---|---|---|---|---|
| **Statisch** | Repo-Root (`index.html`, …) | HTML + JavaScript | **GitHub Pages** (statisch, HTTPS) | Schnelles, dependency-freies Deployment; ideal zum direkten Testen auf dem Gerät |
| **Razor/Blazor** | Ordner [`Blazor/`](Blazor/) | .NET 8 Blazor WebAssembly | Eigenes Hosting / Static-Web-App | Gleiche Funktion innerhalb einer C#/.NET-Anwendung |

Die Blazor-Variante hat im Ordner [`Blazor/`](Blazor/) eine **eigene README** mit
Details zu Build und Deployment. GitHub Pages liefert ausschließlich die statischen
Dateien aus dem Repo-Root aus – der `Blazor/`-Ordner liegt nur als Quellcode daneben.

---

## Dokumentation

- **[Integration in eine gehostete Blazor-WASM-Lösung (Server / Client / Shared)](docs/blazor-wasm-hosted-integration.md)**
  – Schritt-für-Schritt-Anleitung, wie du den PWA-Installations-Flow in eine
  bestehende Blazor-WebAssembly-Lösung mit Server-, Client- und Shared-Projekt
  einbaust (inkl. `.csproj`-, `index.html`- und Server-Anpassungen).

---

## Anwendungsfall

Mitarbeiter, Kunden oder Gäste sollen eine Web-App **ohne App-Store** und ohne
manuelle URL-Eingabe auf ihrem Smartphone/Tablet installieren können – egal mit
welchem Browser. Praktisches Szenario:

1. Ein **QR-Code** (z. B. auf einem Aushang, Flyer oder Bildschirm) zeigt auf
   `…/pwa-install.html`.
2. Der Nutzer scannt ihn und landet auf der **Installations-Seite**.
3. **Android:** Ein Button löst den nativen Installations-Dialog aus.
   **iOS:** Eine animierte Anleitung zeigt den „Zum Home-Bildschirm"-Weg.
4. Nach der Installation öffnet das App-Icon direkt die **`index.html`**
   (über `start_url` im Manifest). Die Install-Seite leitet im App-Modus
   automatisch dorthin weiter.

---

## Warum dieser Weg?

- **Warum PWA statt nativer App?** Keine App-Stores, keine Freigabeprozesse,
  keine getrennten Codebasen für iOS/Android. Eine URL, ein Code, alle Geräte.
- **Warum eine separate `pwa-install.html`?** Die Installation ist ein einmaliger
  Vorgang. Wir trennen ihn bewusst von der eigentlichen App: Der QR-Code zeigt auf
  die Install-Seite, das installierte App-Icon auf die App (`start_url`). So sieht
  der Nutzer nach der Installation nie wieder die Install-Hinweise.
- **Warum eine statische Variante?** GitHub Pages kann statische Dateien sofort
  über HTTPS ausliefern – und **HTTPS ist Pflicht** für PWA-Installation. Das macht
  diese Variante zur einfachsten Test- und Verteilungsform.

---

## Die Herausforderung

Der Wunsch war eigentlich: *„Die App soll sich per Button automatisch installieren,
egal welcher Browser."* Dabei sind wir auf eine harte Plattformgrenze gestoßen:

| Plattform | Programmatischer Install-Button? |
|---|---|
| Android (Chrome/Edge/Samsung) | ✅ Ja, über das `beforeinstallprompt`-Event |
| iOS/iPadOS (Safari) | ❌ **Nein** – Apple stellt **keine** API dafür bereit |

Auf iOS lässt sich „Zum Home-Bildschirm" **nicht** per JavaScript auslösen. Die
einzige seriöse Lösung ist, den manuellen Schritt **so deutlich wie möglich
anzuleiten**. Deshalb haben wir ein **animiertes GIF** (`ios-install.gif`) gebaut,
das mit einer wippenden Sprechblase und einem pulsierenden Ring direkt auf das
echte „Teilen"-Symbol der Safari-Leiste zeigt.

Eine zusätzliche kleine Hürde: Auf dem Entwicklungsrechner war **weder ImageMagick
noch ffmpeg** installiert. Das animierte GIF wurde daher mit einem **selbst
geschriebenen GIF-Encoder** (inkl. LZW-Kompression, `tools/make-gif.ps1`) in .NET
erzeugt – komplett ohne externe Werkzeuge.

---

## Projektstruktur

```
.
├── index.html              # Die eigentliche App (manifest start_url)
├── pwa-install.html        # QR-Ziel: Installations-Seite (+ Live-Diagnose)
├── manifest.webmanifest    # PWA-Metadaten, start_url = ./index.html
├── sw.js                   # Service Worker (Offline-Cache)
├── ios-install.gif         # Animierte iOS-Anleitung
├── icons/                  # App-Icons (192 / 512 / 512-maskable) – Platzhalter!
├── tools/
│   ├── make-gif.ps1        # Generator für ios-install.gif (eigener GIF-Encoder)
│   └── server.js           # Mini-Webserver für lokales Testen (Node)
└── Blazor/                 # Schwester-Projekt (Blazor-Variante, eigene README)
```

---

## Lokal testen

PWA-Funktionen brauchen `http://localhost` oder `https://` – **nicht** `file://`.

```bash
node tools/server.js
# -> http://localhost:8000/pwa-install.html
```

Auf der Install-Seite gibt es unten ein aufklappbares **Diagnose-Feld**, das live
anzeigt, ob Service Worker, Manifest und `beforeinstallprompt` korrekt sind.

> Hinweis: In der **DevTools-Geräte-Emulation** feuert `beforeinstallprompt`
> grundsätzlich **nicht**. Zum echten Test Desktop-Chrome (Adressleisten-Icon)
> oder ein **echtes Android-Gerät** verwenden.

---

## Auf GitHub Pages veröffentlichen

1. Repository auf GitHub anlegen und pushen.
2. **Settings → Pages → Build and deployment → Source: „Deploy from a branch"**,
   Branch `main`, Ordner `/ (root)`, speichern.
3. Nach ein paar Minuten ist die Seite unter
   `https://<dein-name>.github.io/<repo>/` erreichbar.
4. QR-Code auf `https://<dein-name>.github.io/<repo>/pwa-install.html` erzeugen.

> **Wichtig – relative Pfade:** GitHub Pages liefert Projektseiten in einem
> **Unterordner** (`/<repo>/`) aus. Dieses Projekt verwendet durchgehend
> **relative Pfade** (`./index.html`, `sw.js`, `icons/…`) und das Manifest hat
> `scope: "./"`. Dadurch funktioniert es im Unterordner ohne Anpassung. Würde man
> absolute Pfade (`/index.html`) verwenden, wäre die PWA dort kaputt.

Die mitgelieferte Datei `.nojekyll` verhindert, dass GitHubs Jekyll-Build die
Dateien anfasst.

### QR-Code

Der fertige QR-Code liegt als **[`qr-pwa-install.png`](qr-pwa-install.png)** im Repo
und zeigt auf
`https://ari-lzkth.github.io/pwa-install-kit/pwa-install.html`.

Neu erzeugen (z. B. bei geänderter URL):

```bash
npm install qrcode        # einmalig
node tools/make-qr.js     # erzeugt qr-pwa-install.png
# oder mit eigener URL:
node tools/make-qr.js "https://meine-domain/pwa-install.html" qr.png
```

---

## Auf Android testen

1. Pages-URL `…/pwa-install.html` im **Chrome auf dem Android-Gerät** öffnen.
2. Der **„App installieren"-Button** erscheint (oder im Browser-Menü
   „App installieren" / „Zum Startbildschirm hinzufügen").
3. Nach der Installation App über das Icon öffnen → es erscheint `index.html`.

---

## Vor dem Produktiveinsatz noch zu erledigen

- **Icons ersetzen:** Die `icons/*.png` sind blaue Platzhalter mit „P". Gegen das
  echte Logo (gleiche Dateinamen/Größen) tauschen.
- **Diagnose-Feld** in `pwa-install.html` (Block `<details id="diag">`) für den
  Echtbetrieb entfernen.
- **Texte/Farben** anpassen (Theme-Farbe `#0d6efd`, App-Name „Meine PWA").

---

## Lizenz

[MIT](LICENSE) – frei verwendbar, auch kommerziell. Siehe `LICENSE`.

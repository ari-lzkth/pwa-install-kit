# PWA-Installer – Blazor-Variante (.NET 8 WebAssembly)

Eine installierbare **Progressive Web App (PWA)** auf Basis von **Blazor WebAssembly**,
die per **QR-Code** verteilt wird. Der QR-Code führt auf eine Installations-Route,
von der aus sich die App mit **einem Tap** (Android) bzw. einer geführten Anleitung
(iOS) auf den Startbildschirm legen lässt. Nach der Installation startet die App
direkt in der eigentlichen App-Seite.

> Dies ist die **Blazor-Variante**. Die identische Funktion gibt es auch als
> **statische HTML/JS-Variante** (siehe unten) – diese wird über GitHub Pages
> ausgeliefert, die Blazor-Variante hier **nicht**.

---

## Die zwei Schwester-Projekte

Beide Projekte setzen denselben PWA-Installations-Flow um – einmal ohne und einmal
mit Framework:

| Projekt | Technik | Hosting | Zweck |
|---|---|---|---|
| **Statische Variante** | HTML + JavaScript | **GitHub Pages** (statisch, HTTPS) | Schnelles, dependency-freies Deployment; ideal zum direkten Testen auf dem Gerät |
| **Blazor-Variante** (dieses Repo) | .NET 8 Blazor WebAssembly | Eigenes Hosting / Static-Web-App | Gleiche Funktion innerhalb einer C#/.NET-Anwendung |

Die statische Variante liegt im übergeordneten Ordner bzw. im zugehörigen
Repository und hat eine eigene README. **GitHub Pages wird bewusst nur für die
statische Variante genutzt** (siehe „Warum dieser Weg?").

---

## Anwendungsfall

Nutzer sollen eine Web-App **ohne App-Store** auf ihrem Smartphone/Tablet
installieren können – hier eingebettet in eine .NET/Blazor-Anwendung, z. B. wenn
die App ohnehin Teil eines bestehenden C#-Backends/-Ökosystems ist.

1. Ein **QR-Code** zeigt auf die Route `…/pwa-install`.
2. Der Nutzer landet auf der **Installations-Seite** (`PwaInstall.razor`).
3. **Android:** Ein Button löst den nativen Installations-Dialog aus.
   **iOS:** Eine animierte Anleitung zeigt den „Zum Home-Bildschirm"-Weg.
4. Nach der Installation öffnet das App-Icon die Start-Route `/` (`Index.razor`),
   gesteuert über `start_url` im Manifest. Die Install-Seite leitet im App-Modus
   automatisch dorthin weiter.

---

## Warum dieser Weg?

- **Warum PWA statt nativer App?** Keine App-Stores, keine getrennten Codebasen
  für iOS/Android. Eine URL, ein Code, alle Geräte – innerhalb von .NET.
- **Warum eine separate `pwa-install`-Route?** Die Installation ist einmalig. Der
  QR-Code zeigt auf die Install-Route, das installierte App-Icon auf die App-Route
  (`start_url`). So sieht der Nutzer die Install-Hinweise nach der Installation nie
  wieder.
- **Warum GitHub Pages nur für die statische Variante?** GitHub Pages liefert nur
  statische Dateien aus. Eine Blazor-WASM-App **lässt sich** zwar grundsätzlich
  statisch hosten, benötigt dafür aber zusätzliche Schritte (korrektes `base href`
  für den Unterordner, `404.html`-Fallback für Deep-Links, `.nojekyll`). Da die
  statische Variante bereits eine reibungslose Pages-Auslieferung bietet, nutzen
  wir Pages bewusst nur dort und halten die Blazor-Variante für „richtiges" Hosting
  (ASP.NET-Host, Azure Static Web Apps o. ä.) frei.

---

## Die Herausforderung

Der ursprüngliche Wunsch: *„Die App soll sich per Button automatisch installieren,
egal welcher Browser."* Dabei sind wir auf eine harte Plattformgrenze gestoßen:

| Plattform | Programmatischer Install-Button? |
|---|---|
| Android (Chrome/Edge/Samsung) | ✅ Ja, über das `beforeinstallprompt`-Event |
| iOS/iPadOS (Safari) | ❌ **Nein** – Apple stellt **keine** API dafür bereit |

Auf iOS lässt sich „Zum Home-Bildschirm" **nicht** per Code auslösen. Deshalb haben
wir ein **animiertes GIF** (`wwwroot/ios-install.gif`) gebaut, das mit Sprechblase
und pulsierendem Ring direkt auf das echte „Teilen"-Symbol zeigt.

In Blazor kam erschwerend hinzu, dass `beforeinstallprompt` ein reines
Browser-/JS-Event ist. Wir brücken es über **JS-Interop**
(`wwwroot/js/pwa-install.js` ⇄ `PwaInstall.razor`): JavaScript fängt das Event ab
und meldet es per `DotNetObjectReference` an die C#-Komponente, die daraufhin den
Button anzeigt.

---

## Projektstruktur

```
Blazor/
├── Blazor.csproj               # .NET 8, ServiceWorkerAssetsManifest aktiviert
├── Program.cs
├── App.razor / MainLayout.razor / _Imports.razor
├── Pages/
│   ├── Index.razor             # Die App  (Route "/", manifest start_url)
│   └── PwaInstall.razor        # QR-Ziel  (Route "/pwa-install")
└── wwwroot/
    ├── index.html              # Host-Seite (bootet Blazor + registriert SW)
    ├── manifest.webmanifest    # start_url = ./
    ├── service-worker.js                 # Dev (kein Caching)
    ├── service-worker.published.js       # Release (offlinefähig, MIT/Microsoft)
    ├── ios-install.gif         # Animierte iOS-Anleitung
    ├── js/pwa-install.js       # JS-Interop-Brücke für beforeinstallprompt
    └── icons/                  # App-Icons (Platzhalter!)
```

---

## Starten & Veröffentlichen

**Entwicklung:**
```bash
cd Blazor
dotnet run
```

**Release-Build (Service Worker / Offline-Cache erst hier aktiv):**
```bash
dotnet publish -c Release
# Ergebnis: bin/Release/net8.0/publish/wwwroot/
```

Das `publish/wwwroot/`-Verzeichnis lässt sich auf jedem HTTPS-Host ausliefern
(ASP.NET-Host, Azure Static Web Apps, Nginx, …).

> **Deep-Link-Hinweis:** Damit der QR-Link `/pwa-install` direkt lädt, muss das
> Hosting alle Routen auf `index.html` zurückfallen lassen (SPA-Fallback). Bei
> einem ASP.NET-Host ist das automatisch so; bei statischem Hosting braucht es eine
> Fallback-Regel (bzw. eine `404.html`-Kopie der `index.html`).

---

## Auf Android testen

1. Die gehostete URL `…/pwa-install` im **Chrome auf dem Android-Gerät** öffnen
   (HTTPS erforderlich).
2. Der **„App installieren"-Button** erscheint (oder das Browser-Menü bietet
   „App installieren" an).
3. Nach der Installation App über das Icon öffnen → Start-Route `/`.

> In der DevTools-Geräte-Emulation feuert `beforeinstallprompt` **nicht** – immer
> auf Desktop-Chrome oder echtem Gerät testen.

---

## Vor dem Produktiveinsatz noch zu erledigen

- **Icons ersetzen** (`wwwroot/icons/*.png`, aktuell Platzhalter).
- **App-Name/Theme** in `manifest.webmanifest` und den `.razor`-Seiten anpassen.
- **HTTPS sicherstellen** – ohne gültiges Zertifikat keine PWA-Installation.

---

## Lizenz

[MIT](LICENSE) – frei verwendbar, auch kommerziell. Der mitgelieferte
`service-worker.published.js` stammt aus der MIT-lizenzierten Blazor-Vorlage von
Microsoft.

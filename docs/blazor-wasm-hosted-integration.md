# Integration in eine gehostete Blazor-WASM-Lösung (Server / Client / Shared)

Diese Anleitung beschreibt Schritt für Schritt, wie du den PWA-Installations-Flow
aus diesem Repo in eine **gehostete Blazor-WebAssembly-Lösung** einbaust, die aus
den drei klassischen Projekten besteht:

```
MeineApp.sln
├── MeineApp.Server     (ASP.NET Core – hostet die App + API)
├── MeineApp.Client     (Blazor WebAssembly – hier kommt die PWA-Logik hin!)
└── MeineApp.Shared     (gemeinsame Modelle/DTOs – bleibt unverändert)
```

> **Kernaussage:** Die gesamte PWA-/Installations-Logik gehört in das
> **Client-Projekt** (Blazor WebAssembly). Das **Server**-Projekt muss nur die
> statischen Dateien ausliefern und Deep-Links auf `index.html` zurückfallen lassen
> – das tut die Standard-Vorlage bereits. Das **Shared**-Projekt ist nicht
> beteiligt.

Da der Client echtes WebAssembly ist, funktioniert hier **auch der Offline-Betrieb**
(im Gegensatz zu Blazor Server).

---

## 1. Voraussetzungen

- .NET 8 SDK
- Eine bestehende gehostete Blazor-WASM-Lösung (z. B. erstellt mit
  `dotnet new blazorwasm --hosted`)

> Tipp: Wer von Grund auf startet, kann die PWA-Grundausstattung direkt mitgenerieren:
> `dotnet new blazorwasm --hosted --pwa`. Dann sind `manifest`, Service Worker und
> die `.csproj`-Einträge aus Schritt 3 bereits vorhanden – du ergänzt nur noch die
> **Install-Seite**, das **JS-Interop** und das **iOS-GIF** (Schritte 4–6).

---

## 2. Welche Datei kommt wohin

Alle Quelldateien findest du in diesem Repo im Ordner [`../Blazor/`](../Blazor/).

| Quelle (dieses Repo) | Ziel in deiner Lösung |
|---|---|
| `Blazor/wwwroot/manifest.webmanifest` | `MeineApp.Client/wwwroot/manifest.webmanifest` |
| `Blazor/wwwroot/icons/*` | `MeineApp.Client/wwwroot/icons/` |
| `Blazor/wwwroot/ios-install.gif` | `MeineApp.Client/wwwroot/ios-install.gif` |
| `Blazor/wwwroot/ios26-install.gif` | `MeineApp.Client/wwwroot/ios26-install.gif` |
| `Blazor/wwwroot/js/pwa-install.js` | `MeineApp.Client/wwwroot/js/pwa-install.js` |
| `Blazor/wwwroot/service-worker.js` | `MeineApp.Client/wwwroot/service-worker.js` |
| `Blazor/wwwroot/service-worker.published.js` | `MeineApp.Client/wwwroot/service-worker.published.js` |
| `Blazor/Pages/PwaInstall.razor` | `MeineApp.Client/Pages/PwaInstall.razor` |

---

## 3. Client-`.csproj` anpassen

Damit beim `dotnet publish` der Offline-Service-Worker korrekt mit dem
Asset-Manifest verknüpft wird, ergänze in **`MeineApp.Client.csproj`**:

```xml
<PropertyGroup>
  <!-- ... vorhandene Einträge ... -->
  <ServiceWorkerAssetsManifest>service-worker-assets.js</ServiceWorkerAssetsManifest>
</PropertyGroup>

<ItemGroup>
  <ServiceWorker Include="wwwroot\service-worker.js"
                 PublishedContent="wwwroot\service-worker.published.js" />
</ItemGroup>
```

> Das Client-Projekt nutzt das SDK `Microsoft.NET.Sdk.BlazorWebAssembly` – das ist
> bei der gehosteten Vorlage bereits der Fall.

---

## 4. `index.html` des Clients erweitern

In **`MeineApp.Client/wwwroot/index.html`** im `<head>` ergänzen:

```html
<!-- PWA -->
<link rel="manifest" href="manifest.webmanifest" />
<meta name="theme-color" content="#0d6efd" />

<!-- iOS / Safari -->
<meta name="apple-mobile-web-app-capable" content="yes" />
<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent" />
<meta name="apple-mobile-web-app-title" content="Meine APP" />
<link rel="apple-touch-icon" href="icons/icon-192.png" />
```

Und vor `</body>` (nach dem vorhandenen `blazor.webassembly.js`):

```html
<script src="js/pwa-install.js"></script>
<script>
  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.register('service-worker.js');
  }
</script>
```

> **Wichtig – relative Pfade:** Verwende `manifest.webmanifest`, `icons/…`,
> `service-worker.js` **ohne** führenden Schrägstrich. So bleibt die App auch
> funktionsfähig, wenn sie nicht unter dem Root-Pfad (`/`) gehostet wird.
> Passend dazu muss in `index.html` `<base href="/" />` zur Hosting-Basis passen.

---

## 5. Install-Seite + JS-Interop übernehmen

1. `PwaInstall.razor` nach **`MeineApp.Client/Pages/`** kopieren. Sie stellt die
   Route `"/pwa-install"` bereit (= Ziel des QR-Codes).
2. Prüfe die `@using`/Namespaces in deiner `_Imports.razor` – die Komponente nutzt
   `IJSRuntime` und `NavigationManager` (Standard, keine Zusatzpakete nötig).
3. `pwa-install.js` liegt bereits in `wwwroot/js/` (Schritt 2) und wird in
   `index.html` eingebunden (Schritt 4).

Der Ablauf: `pwa-install.js` fängt das Browser-Event `beforeinstallprompt` ab und
meldet es per `DotNetObjectReference` an `PwaInstall.razor`, die daraufhin den
Install-Button anzeigt. Auf iOS wird stattdessen die passende Anleitung als GIF
eingeblendet.

> **iOS 26 beachten:** Seit iOS 26 („Liquid Glass") ist das Teilen-Symbol im
> Standard-Layout („Kompakt") **nicht mehr direkt sichtbar** – es steckt hinter dem
> **•••**-Knopf. Deshalb liefert `pwa-install.js` die iOS-Hauptversion mit, und
> `PwaInstall.razor` zeigt automatisch das richtige GIF: **`ios26-install.gif`** für
> iOS ≥ 26 (Weg über •••), **`ios-install.gif`** für ältere Versionen (Teilen-Symbol
> direkt in der Leiste).

---

## 6. `start_url` und Start-Seite

In **`MeineApp.Client/wwwroot/manifest.webmanifest`** zeigt `start_url` auf den
App-Einstieg (Route `"/"`):

```json
{
  "start_url": "./",
  "scope": "./",
  "display": "standalone"
}
```

Damit öffnet das installierte App-Icon die normale Start-Route (z. B.
`Pages/Index.razor` bzw. `Pages/Home.razor`) – **nicht** die Install-Seite. Die
Install-Seite leitet im App-Modus zusätzlich automatisch dorthin weiter.

---

## 7. Server-Projekt prüfen (meist nichts zu tun)

Die gehostete Vorlage konfiguriert in **`MeineApp.Server/Program.cs`** bereits alles
Nötige. Stelle sicher, dass diese drei Zeilen vorhanden sind:

```csharp
app.UseBlazorFrameworkFiles();   // liefert _framework/* und wwwroot des Clients
app.UseStaticFiles();            // liefert manifest, icons, gif, service-worker ...
// ... app.MapControllers(); etc. ...
app.MapFallbackToFile("index.html");   // Deep-Links (z. B. /pwa-install) -> index.html
```

Der **`MapFallbackToFile`**-Eintrag ist entscheidend: Wenn der QR-Code direkt
`…/pwa-install` öffnet, liefert der Server `index.html` aus, und der Blazor-Router
zeigt die Install-Seite. Ohne diese Zeile gäbe es bei Deep-Links einen 404.

> **MIME-Typ:** ASP.NET Core kennt `.webmanifest` standardmäßig. Falls dein Host das
> Manifest dennoch nicht ausliefert, registriere den Typ explizit:
> ```csharp
> var provider = new Microsoft.AspNetCore.StaticFiles.FileExtensionContentTypeProvider();
> provider.Mappings[".webmanifest"] = "application/manifest+json";
> app.UseStaticFiles(new StaticFileOptions { ContentTypeProvider = provider });
> ```

---

## 8. Bauen & testen

**Entwicklung** (vom Server-Projekt starten – es hostet den Client):

```bash
dotnet run --project MeineApp.Server
```

> In der Entwicklung ist der Service Worker bewusst „leer" (kein Caching), damit du
> Änderungen sofort siehst.

**Release / Offline aktiv:**

```bash
dotnet publish MeineApp.Server -c Release
# Auslieferbares Ergebnis unter: MeineApp.Server/bin/Release/net8.0/publish/
```

Erst im veröffentlichten Build greift `service-worker.published.js` mit dem
Asset-Manifest – ab dann ist die App **offlinefähig** und voll installierbar.

---

## 9. Verhalten auf den Geräten (unverändert zum Repo)

- **Android (Chrome/Edge):** Auf `/pwa-install` erscheint der Button
  „App installieren" und löst den nativen Dialog aus.
- **iOS (Safari):** Kein Auto-Button möglich → das animierte `ios-install.gif`
  zeigt den Weg „Teilen → Zum Home-Bildschirm".
- **HTTPS ist Pflicht** (Ausnahme: `localhost`). Ohne gültiges Zertifikat bietet
  kein Browser die Installation an.
- **DevTools-Geräte-Emulation** feuert `beforeinstallprompt` **nicht** – immer auf
  echtem Gerät oder Desktop-Chrome testen.

---

## 10. Checkliste

- [ ] PWA-Dateien nach `MeineApp.Client/wwwroot/` kopiert (Schritt 2)
- [ ] `ServiceWorkerAssetsManifest` + `<ServiceWorker>` in der Client-`.csproj` (3)
- [ ] `index.html`: Manifest-Link, Meta-Tags, SW-Registrierung, `pwa-install.js` (4)
- [ ] `PwaInstall.razor` in `MeineApp.Client/Pages/` (5)
- [ ] `start_url`/`scope` im Manifest gesetzt (6)
- [ ] `MapFallbackToFile("index.html")` im Server vorhanden (7)
- [ ] Über HTTPS bereitgestellt und auf echtem Gerät getestet (8–9)
- [ ] Platzhalter-Icons gegen echtes Logo getauscht

---

*Teil von **pwa-install-kit** – siehe die [Haupt-README](../README.md) und die
[README der Blazor-Variante](../Blazor/README.md).*

// Erzeugt den QR-Code (PNG) fuer die Installations-Seite.
// Voraussetzung: einmalig `npm install qrcode` im Repo-Root ausfuehren.
//
// Aufruf:
//   node tools/make-qr.js
//   node tools/make-qr.js "https://andere-url" qr-name.png
const QRCode = require('qrcode');
const path = require('path');

const url = process.argv[2] ||
  'https://ari-lzkth.github.io/pwa-install-kit/pwa-install.html';
const outFile = process.argv[3] || 'qr-pwa-install.png';
const out = path.resolve(__dirname, '..', outFile);

QRCode.toFile(out, url, {
  errorCorrectionLevel: 'M',   // M = gute Balance aus Groesse/Robustheit
  margin: 2,
  width: 600,                  // 600 px Kantenlaenge -> auch fuer Druck gut
  color: { dark: '#000000ff', light: '#ffffffff' }
}, (err) => {
  if (err) { console.error('Fehler:', err); process.exit(1); }
  console.log('QR erstellt: ' + out);
  console.log('Ziel-URL   : ' + url);
});

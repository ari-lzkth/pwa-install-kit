// JS-Interop-Brücke für den PWA-Install-Prompt in Blazor
window.pwaInstall = (function () {
    let deferredPrompt = null;
    let dotNetRef = null;

    function isIos() {
        return /iphone|ipad|ipod/i.test(navigator.userAgent) ||
            (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
    }

    function isStandalone() {
        return window.matchMedia('(display-mode: standalone)').matches ||
            window.navigator.standalone === true;
    }

    // iOS-Hauptversion (z. B. 26). 0 = unbekannt.
    // WICHTIG: Seit iOS 26 friert Safari "OS x_y" dauerhaft auf 18_6 ein
    // (Datenschutz). Die echte Version steht nur noch in "Version/26.0".
    // Daher das Maximum aus beiden Signalen nehmen.
    function iosVersion() {
        var ua = navigator.userAgent;
        var v = 0;
        var os = ua.match(/OS (\d+)_/);          // bei iOS 26 eingefroren (18_6)!
        if (os) v = Math.max(v, parseInt(os[1], 10));
        var sa = ua.match(/Version\/(\d+)/);     // Safari-Major = echte iOS-Major
        if (sa) v = Math.max(v, parseInt(sa[1], 10));
        return v;
    }

    async function alreadyInstalled() {
        if ('getInstalledRelatedApps' in navigator) {
            try {
                const related = await navigator.getInstalledRelatedApps();
                return Array.isArray(related) && related.length > 0;
            } catch (_) { /* ignorieren */ }
        }
        return false;
    }

    return {
        // Wird von Blazor (PwaInstall.razor / OnAfterRenderAsync) aufgerufen
        init: async function (ref) {
            dotNetRef = ref;

            window.addEventListener('beforeinstallprompt', (e) => {
                e.preventDefault();
                deferredPrompt = e;
                dotNetRef.invokeMethodAsync('OnInstallAvailable');
            });

            window.addEventListener('appinstalled', () => {
                deferredPrompt = null;
                dotNetRef.invokeMethodAsync('OnInstalled');
            });

            return {
                standalone: isStandalone(),
                isIos: isIos(),
                iosVersion: iosVersion(),
                alreadyInstalled: await alreadyInstalled()
            };
        },

        // Öffnet das native Install-Popup, gibt true zurück wenn akzeptiert
        prompt: async function () {
            if (!deferredPrompt) return false;
            deferredPrompt.prompt();
            const { outcome } = await deferredPrompt.userChoice;
            deferredPrompt = null;
            return outcome === 'accepted';
        }
    };
})();

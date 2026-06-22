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

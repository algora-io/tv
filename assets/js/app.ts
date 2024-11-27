import "phoenix_html";
import { Socket } from "phoenix";
import { LiveSocket, type ViewHook } from "phoenix_live_view";
import topbar from "../vendor/topbar";
import { VidstackPlayer, VidstackPlayerLayout } from "vidstack/global/player";
import { isHLSProvider } from "vidstack";
import HLS from "@algora/hls.js";

// TODO: add eslint & biome
// TODO: enable strict mode
// TODO: eliminate anys

interface PhxEvent extends Event {
  target: Element;
  detail: Record<string, any>;
}

type PhxEventKey = `js:${string}` | `phx:${string}`;

declare global {
  interface Window {
    liveSocket: LiveSocket;
    addEventListener<K extends keyof WindowEventMap | PhxEventKey>(
      type: K,
      listener: (
        this: Window,
        ev: K extends keyof WindowEventMap ? WindowEventMap[K] : PhxEvent
      ) => any,
      options?: boolean | AddEventListenerOptions | undefined
    ): void;
  }
}

let isVisible = (el) =>
  !!(el.offsetWidth || el.offsetHeight || el.getClientRects().length > 0);

let execJS = (selector, attr) => {
  document
    .querySelectorAll(selector)
    .forEach((el) => liveSocket.execJS(el, el.getAttribute(attr)));
};

const Hooks = {
  Flash: {
    mounted() {
      let hide = () =>
        liveSocket.execJS(this.el, this.el.getAttribute("phx-click"));
      this.timer = setTimeout(() => hide(), 8000);
      this.el.addEventListener("phx:hide-start", () =>
        clearTimeout(this.timer)
      );
      this.el.addEventListener("mouseover", () => {
        clearTimeout(this.timer);
        this.timer = setTimeout(() => hide(), 8000);
      });
    },
    destroyed() {
      clearTimeout(this.timer);
    },
  },
  Menu: {
    getAttr(name) {
      let val = this.el.getAttribute(name);
      if (val === null) {
        throw new Error(`no ${name} attribute configured for menu`);
      }
      return val;
    },
    reset() {
      this.enabled = false;
      this.activeClass = this.getAttr("data-active-class");
      this.deactivate(this.menuItems());
      this.activeItem = null;
      window.removeEventListener("keydown", this.handleKeyDown);
    },
    destroyed() {
      this.reset();
    },
    mounted() {
      this.menuItemsContainer = document.querySelector(
        `[aria-labelledby="${this.el.id}"]`
      );
      this.reset();
      this.handleKeyDown = (e) => this.onKeyDown(e);
      this.el.addEventListener("keydown", (e) => {
        if (
          (e.key === "Enter" || e.key === " ") &&
          e.currentTarget.isSameNode(this.el)
        ) {
          this.enabled = true;
        }
      });
      this.el.addEventListener("click", (e) => {
        if (!e.currentTarget.isSameNode(this.el)) {
          return;
        }

        window.addEventListener("keydown", this.handleKeyDown);
        // disable if button clicked and click was not a keyboard event
        if (this.enabled) {
          window.requestAnimationFrame(() => this.activate(0));
        }
      });
      this.menuItemsContainer.addEventListener("phx:hide-start", () =>
        this.reset()
      );
    },
    activate(index, fallbackIndex) {
      let menuItems = this.menuItems();
      this.activeItem = menuItems[index] || menuItems[fallbackIndex];
      this.activeItem.classList.add(this.activeClass);
      this.activeItem.focus();
    },
    deactivate(items) {
      items.forEach((item) => item.classList.remove(this.activeClass));
    },
    menuItems() {
      return Array.from(
        this.menuItemsContainer.querySelectorAll("[role=menuitem]")
      );
    },
    onKeyDown(e) {
      if (e.key === "Escape") {
        document.body.click();
        this.el.focus();
        this.reset();
      } else if (e.key === "Enter" && !this.activeItem) {
        this.activate(0);
      } else if (e.key === "Enter") {
        this.activeItem.click();
      }
      if (e.key === "ArrowDown") {
        e.preventDefault();
        let menuItems = this.menuItems();
        this.deactivate(menuItems);
        this.activate(menuItems.indexOf(this.activeItem) + 1, 0);
      } else if (e.key === "ArrowUp") {
        e.preventDefault();
        let menuItems = this.menuItems();
        this.deactivate(menuItems);
        this.activate(
          menuItems.indexOf(this.activeItem) - 1,
          menuItems.length - 1
        );
      } else if (e.key === "Tab") {
        e.preventDefault();
      }
    },
  },
  VideoPlayer: {
    async mounted() {
      const backdrop = document.querySelector("#video-backdrop");
      this.playerId = this.el.id;
      this.attemptedAutoplay = false;
  
      // Create muted overlay element
      const mutedOverlay = document.createElement('div');
      mutedOverlay.id = `muted-overlay-${this.playerId}`;
      mutedOverlay.className = 'absolute inset-0 z-10 flex items-center justify-center bg-black/50 cursor-pointer';
      mutedOverlay.innerHTML = `
        <div class="rounded-full bg-white/20 p-8">
          <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M11 5L6 9H2v6h4l5 4zM22 9l-6 6M16 9l6 6"/>
          </svg>
        </div>
      `;
  
      this.player = await VidstackPlayer.create({
        target: this.el,
        viewType: "video",
        streamType: "on-demand",
        liveEdgeTolerance: 2,
        load: "eager",
        logLevel: "warn",
        crossOrigin: true,
        playsInline: true,
        layout: new VidstackPlayerLayout(),
      });
  
      this.player.subscribe(({ autoPlayError }) => {
        if (autoPlayError) {
          this.player.muted = true;
          this.player.play();
          this.attemptedAutoplay = true;
  
          // Position overlay and add to parent
          mutedOverlay.style.position = 'absolute';
          this.el.parentElement.appendChild(mutedOverlay);
  
          // Add unmute functionality
          mutedOverlay.addEventListener('click', () => {
            this.player.muted = false;
            mutedOverlay.remove();
          });
        }
      });

      const playVideo = (opts: {
        player_id: string;
        id: string;
        url: string;
        title: string;
        poster: string;
        is_live: boolean;
        player_type: string;
        current_time: number;
        channel_name: string;
        clip_start_time: number | undefined;
        clip_end_time: number | undefined;
      }) => {
        if (this.playerId !== opts.player_id) {
          return;
        }

        const setMediaSession = () => {
          if (!("mediaSession" in navigator)) {
            return;
          }
          navigator.mediaSession.metadata = new MediaMetadata({
            title: opts.title,
            artist: opts.channel_name,
            album: "Algora TV",
            artwork: [96, 128, 192, 256, 384, 512, 1024].map((px) => ({
              src: `https://console.algora.io/asset/storage/v1/object/public/images/algora-gradient-${px}px.png`,
              sizes: `${px}x${px}`,
              type: "image/png",
            })),
          });
        };

        const autoplay = (() => {
          // TODO: remove this once we have a better way to handle autoplay
          if (this.el.id.startsWith("analytics-")) {
            return false;
          }

          if (opts.player_type === "video/youtube") {
            return navigator.userActivation.isActive;
          }

          return true;
        })();

        const startTime = (() => {
          // TODO: remove this once vidstack youtube thumbnails at t=0 are fixed
          if (opts.player_type === "video/youtube") {
            return opts.current_time || 1;
          }

          return opts.current_time;
        })();

        this.player.autoplay = autoplay;
        this.player.poster = opts.poster;
        this.player.title = opts.title;
        this.player.currentTime = startTime;
        this.player.streamType = opts.is_live ? "ll-live:dvr" : "on-demand";
        this.player.src = opts.url;

        if (typeof(opts.clip_end_time) === "number"){
          this.player.clipEndTime = opts.clip_end_time;
        }
        if (typeof(opts.clip_start_time) === "number"){
          this.player.clipStartTime = opts.clip_start_time;
          this.player.play();
        }

        this.player.addEventListener("provider-change", (event) => {
          const provider = event.detail;
          if (isHLSProvider(provider)) {
            provider.library = HLS;
            provider.config = {
              targetlatency: 6, // one segment
            };
          }
        });

        setMediaSession();

        if (backdrop) {
          backdrop.classList.remove("opacity-10");
          backdrop.classList.add("opacity-20");
        }

        if (this.playerId === "video-player") {
          this.pushEventTo("#clipper", "video_loaded", { id: opts.id });
        }
      };

      this.handleEvent("play_video", playVideo);
    },
  },
  Chat: {
    mounted() {
      this.el.scrollTo(0, this.el.scrollHeight);
    },

    updated() {
      const pixelsBelowBottom =
        this.el.scrollHeight - this.el.clientHeight - this.el.scrollTop;

      if (pixelsBelowBottom < 200) {
        this.el.scrollTo(0, this.el.scrollHeight);
      }
    },
  },
  PWAInstallPrompt: {
    mounted() {
      let deferredPrompt: any;
      const installPrompt = document.getElementById("pwa-install-prompt");
      const installButton = document.getElementById("pwa-install-button");
      const closeButton = document.getElementById("pwa-close-button");
      const instructionsMobile = document.getElementById(
        "pwa-instructions-mobile"
      );
      if (
        !installPrompt ||
        !installButton ||
        !closeButton ||
        !instructionsMobile ||
        localStorage.getItem("pwaPromptShown")
      ) {
        return;
      }

      const scrollHeight =
        (document.documentElement.scrollHeight || document.body.scrollHeight) -
        document.documentElement.clientHeight;

      const isMobile =
        /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(
          navigator.userAgent
        );

      let promptShown = false;

      const showPrompt = () => {
        if (!promptShown) {
          installPrompt.classList.remove("hidden");
          if (isMobile) {
            instructionsMobile.classList.remove("hidden");
            installButton.classList.add("hidden");
          } else {
            installButton.classList.remove("hidden");
            instructionsMobile.classList.add("hidden");
          }
          promptShown = true;
        }
      };

      window.addEventListener(
        "scroll",
        () => {
          const scrollPos =
            document.documentElement.scrollTop || document.body.scrollTop;

          if (scrollPos > Math.min(500, scrollHeight / 2) && deferredPrompt) {
            showPrompt();
          }
        },
        { passive: true }
      );

      window.addEventListener("beforeinstallprompt", (e) => {
        e.preventDefault();
        deferredPrompt = e;
      });

      installButton.addEventListener("click", async () => {
        if (deferredPrompt) {
          deferredPrompt.prompt();
          deferredPrompt = null;
        }
        installPrompt.classList.add("hidden");
        localStorage.setItem("pwaPromptShown", "true");
      });

      closeButton.addEventListener("click", () => {
        installPrompt.classList.add("hidden");
        localStorage.setItem("pwaPromptShown", "true");
      });

      window.addEventListener("appinstalled", () => {
        installPrompt.classList.add("hidden");
        deferredPrompt = null;
        localStorage.setItem("pwaPromptShown", "true");
      });
    },
  },
  TimezoneDetector: {
    mounted() {
      this.pushEvent("get_timezone", {
        tz: Intl.DateTimeFormat().resolvedOptions().timeZone,
      });
    },
  },
  PopoutChat: {
    mounted() {
      this.el.addEventListener("click", (e) => {
        e.preventDefault();
        window.open(
          window.location.href + "/chat_popout",
          "newwindow",
          "width=400,height=600"
        );
      });
    },
    destroyed() {
      this.el.removeEventListener("click", this.handleClick);
    },
  },
  NavBar: {
    mounted() {
      const offset = 16;
      this.isOpaque = false;

      const onScroll = () => {
        if (!this.isOpaque && window.scrollY > offset) {
          this.isOpaque = true;
          this.el.classList.add("bg-gray-950");
          this.el.classList.remove("bg-transparent");
        } else if (this.isOpaque && window.scrollY <= offset) {
          this.isOpaque = false;
          this.el.classList.add("bg-transparent");
          this.el.classList.remove("bg-gray-950");
        }
      };

      window.addEventListener("scroll", onScroll, { passive: true });
    },
  },
  CopyToClipboard: {
    value() {
      return this.el.dataset.value;
    },
    notice() {
      return this.el.dataset.notice;
    },
    mounted() {
      this.el.addEventListener("click", () => {
        navigator.clipboard.writeText(this.value()).then(() => {
          this.pushEvent("copied_to_clipboard", { notice: this.notice() });
        });
      });
    },
  },
  LiveBillboard: {
    setup() {
      const urls = JSON.parse(this.el.dataset.urls);
      const [img1, img2] = this.el.querySelectorAll("img");
      let currentIndex = 0;
      let nextIndex = Math.min(1, urls.length - 1);
      img2.src = urls[nextIndex];

      clearInterval(this.interval);
      if (urls.length > 1) {
        this.interval = setInterval(() => {
          const nextImg = currentIndex % 2 === 0 ? img2 : img1;
          const currentImg = currentIndex % 2 === 0 ? img1 : img2;

          nextImg.src = urls[nextIndex];
          nextImg.classList.remove("opacity-0");
          currentImg.classList.add("opacity-0");

          currentIndex = nextIndex;
          nextIndex = (nextIndex + 1) % urls.length;
        }, 5000);
      }
    },
    mounted() {
      this.setup();
    },
    updated() {
      this.setup();
    },
  },
} satisfies Record<string, Partial<ViewHook> & Record<string, unknown>>;

// Accessible focus handling
let Focus = {
  focusMain() {
    let target =
      document.querySelector<HTMLElement>("main h1") ||
      document.querySelector<HTMLElement>("main");
    if (target) {
      let origTabIndex = target.tabIndex;
      target.tabIndex = -1;
      target.focus();
      target.tabIndex = origTabIndex;
    }
  },
  // Subject to the W3C Software License at https://www.w3.org/Consortium/Legal/2015/copyright-software-and-document
  isFocusable(el) {
    if (
      el.tabIndex > 0 ||
      (el.tabIndex === 0 && el.getAttribute("tabIndex") !== null)
    ) {
      return true;
    }
    if (el.disabled) {
      return false;
    }

    switch (el.nodeName) {
      case "A":
        return !!el.href && el.rel !== "ignore";
      case "INPUT":
        return el.type != "hidden" && el.type !== "file";
      case "BUTTON":
      case "SELECT":
      case "TEXTAREA":
        return true;
      default:
        return false;
    }
  },
  // Subject to the W3C Software License at https://www.w3.org/Consortium/Legal/2015/copyright-software-and-document
  attemptFocus(el) {
    if (!el) {
      return;
    }
    if (!this.isFocusable(el)) {
      return false;
    }
    try {
      el.focus();
    } catch (e) {}

    return document.activeElement === el;
  },
  // Subject to the W3C Software License at https://www.w3.org/Consortium/Legal/2015/copyright-software-and-document
  focusFirstDescendant(el) {
    for (let i = 0; i < el.childNodes.length; i++) {
      let child = el.childNodes[i];
      if (this.attemptFocus(child) || this.focusFirstDescendant(child)) {
        return true;
      }
    }
    return false;
  },
  // Subject to the W3C Software License at https://www.w3.org/Consortium/Legal/2015/copyright-software-and-document
  focusLastDescendant(element) {
    for (let i = element.childNodes.length - 1; i >= 0; i--) {
      let child = element.childNodes[i];
      if (this.attemptFocus(child) || this.focusLastDescendant(child)) {
        return true;
      }
    }
    return false;
  },
};

let csrfToken = document
  .querySelector("meta[name='csrf-token']")!
  .getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {
  hooks: Hooks,
  params: { _csrf_token: csrfToken },
  dom: {
    onNodeAdded(node) {
      if (node instanceof HTMLElement && node.autofocus) {
        node.focus();
      }
      return node;
    },
  },
});

let routeUpdated = () => {
  // TODO: uncomment
  // Focus.focusMain();
};

// Show progress bar on live navigation and form submits
topbar.config({
  barColors: { 0: "rgba(79, 70, 229, 1)" },
  shadowColor: "rgba(0, 0, 0, .3)",
});
window.addEventListener("phx:page-loading-start", (info) =>
  topbar.delayedShow(200)
);
window.addEventListener("phx:page-loading-stop", (info) => topbar.hide());

// Accessible routing
window.addEventListener("phx:page-loading-stop", routeUpdated);

window.addEventListener("phx:js-exec", ({ detail }) => {
  document.querySelectorAll(detail.to).forEach((el) => {
    liveSocket.execJS(el, el.getAttribute(detail.attr));
  });
});

window.addEventListener("js:exec", (e) =>
  e.target[e.detail.call](...e.detail.args)
);
window.addEventListener("js:focus", (e) => {
  let parent = document.querySelector(e.detail.parent);
  if (parent && isVisible(parent)) {
    (e.target as any).focus();
  }
});
window.addEventListener("js:focus-closest", (e) => {
  let el = e.target;
  let sibling = el.nextElementSibling;
  while (sibling) {
    if (isVisible(sibling) && Focus.attemptFocus(sibling)) {
      return;
    }
    sibling = sibling.nextElementSibling;
  }
  sibling = el.previousElementSibling;
  while (sibling) {
    if (isVisible(sibling) && Focus.attemptFocus(sibling)) {
      return;
    }
    sibling = sibling.previousElementSibling;
  }
  Focus.attemptFocus((el as any).parent) || Focus.focusMain();
});
window.addEventListener("phx:remove-el", (e) =>
  document.getElementById(e.detail.id)?.remove()
);

// connect if there are any LiveViews on the page
liveSocket.getSocket().onOpen(() => execJS("#connection-status", "js-hide"));
liveSocket.getSocket().onError(() => execJS("#connection-status", "js-show"));
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
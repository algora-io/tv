import "phoenix_html";
import { Socket } from "phoenix";
import { LiveSocket, ViewHook } from "phoenix_live_view";
import topbar from "../vendor/topbar";
import videojs from "../vendor/video";
import "../vendor/videojs-youtube";

// Define a more specific type for the event handlers
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
      options?: boolean | AddEventListenerOptions
    ): void;
  }
}


const isVisible = (el: Element): boolean => {
  const element = el as HTMLElement; // Cast Element to HTMLElement
  return !!(element.offsetWidth || element.offsetHeight || element.getClientRects().length > 0);
};

const execJS = (selector: string, attr: string) => {
  document
    .querySelectorAll(selector)
    .forEach((el) => liveSocket.execJS(el as HTMLElement, el.getAttribute(attr) || ''));
};

const Hooks: Record<string, Partial<ViewHook> & Record<string, unknown>> = {
  Flash: {
    mounted() {
      let hide = () =>
        liveSocket.execJS(this.el, this.el.getAttribute("phx-click") || '');
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
    getAttr(name: string): string {
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
      ) as HTMLElement;
      this.reset();
      this.handleKeyDown = (e: KeyboardEvent) => this.onKeyDown(e);
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
        if (this.enabled) {
          window.requestAnimationFrame(() => this.activate(0));
        }
      });
      this.menuItemsContainer.addEventListener("phx:hide-start", () =>
        this.reset()
      );
    },
    activate(index: number, fallbackIndex?: number) {
      let menuItems = this.menuItems();
      this.activeItem = menuItems[index] || menuItems[fallbackIndex || 0];
      if (this.activeItem) {
        this.activeItem.classList.add(this.activeClass);
        this.activeItem.focus();
      }
    },
    deactivate(items: HTMLElement[]) {
      items.forEach((item) => item.classList.remove(this.activeClass));
    },
    menuItems(): HTMLElement[] {
      return Array.from(
        this.menuItemsContainer.querySelectorAll("[role=menuitem]")
      );
    },
    onKeyDown(e: KeyboardEvent) {
      if (e.key === "Escape") {
        document.body.click();
        this.el.focus();
        this.reset();
      } else if (e.key === "Enter" && !this.activeItem) {
        this.activate(0);
      } else if (e.key === "Enter") {
        this.activeItem?.click();
      }
      if (e.key === "ArrowDown") {
        e.preventDefault();
        let menuItems = this.menuItems();
        this.deactivate(menuItems);
        this.activate(menuItems.indexOf(this.activeItem || menuItems[0]) + 1, 0);
      } else if (e.key === "ArrowUp") {
        e.preventDefault();
        let menuItems = this.menuItems();
        this.deactivate(menuItems);
        this.activate(
          menuItems.indexOf(this.activeItem || menuItems[menuItems.length - 1]) - 1,
          menuItems.length - 1
        );
      } else if (e.key === "Tab") {
        e.preventDefault();
      }
    },
  },
  VideoPlayer: {
    mounted() {
      const backdrop = document.querySelector("#video-backdrop") as HTMLElement;

      this.playerId = this.el.id;

      const autoplay = this.el.id.startsWith("analytics-") ? false : "any";

      this.player = videojs(this.el, {
        autoplay: autoplay,
        liveui: true,
        html5: {
          vhs: {
            llhls: true,
          },
        },
      });

      const playVideo = (opts: {
        player_id: string;
        id: string;
        url: string;
        title: string;
        player_type: string;
        current_time?: number;
        channel_name: string;
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

        this.player.options({
          techOrder: [
            opts.player_type === "video/youtube" ? "youtube" : "html5",
          ],
          ...(opts.current_time && opts.player_type === "video/youtube"
            ? { youtube: { customVars: { start: opts.current_time } } }
            : {}),
        });
        this.player.src({ src: opts.url, type: opts.player_type });

        setMediaSession();

        if (opts.current_time) {
          if (opts.player_type === "video/youtube") {
            setTimeout(() => {
              this.player.currentTime(opts.current_time);
            }, 2000);
          } else {
            this.player.currentTime(opts.current_time);
          }
        }

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
  TimezoneDetector: {
    mounted() {
      this.pushEvent("get_timezone", {
        tz: Intl.DateTimeFormat().resolvedOptions().timeZone,
      });
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
};

const Focus = {
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
  isFocusable(el: HTMLElement): boolean {
    if (
      el.tabIndex > 0 ||
      (el.tabIndex === 0 && el.getAttribute("tabIndex") !== null)
    ) {
      return true;
    }
    switch (el.tagName) {
      case "A":
      case "BUTTON":
      case "INPUT":
      case "TEXTAREA":
      case "SELECT":
        return true;
      default:
        return false;
    }
  },
  handleFocus() {
    let focusable = Array.from(
      document.querySelectorAll<HTMLElement>(
        "main a, main button, main input, main textarea, main select"
      )
    );
    if (focusable.length > 0) {
      focusable[0].focus();
    }
  },
};

let hooks = Hooks;
let csrfToken = document
  .querySelector<HTMLMetaElement>("meta[name='csrf-token']")
  ?.getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  hooks: hooks,
});

window.addEventListener("phx:page-loading-start", () => topbar.show());
window.addEventListener("phx:page-loading-stop", () => topbar.hide());

window.addEventListener("keydown", (e: KeyboardEvent) => {
  if (e.key === "Escape") {
    Focus.handleFocus();
  }
});

window.addEventListener("focus", Focus.focusMain, { capture: true });

liveSocket.connect();

window.liveSocket = liveSocket;

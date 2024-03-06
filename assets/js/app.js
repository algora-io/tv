import "phoenix_html";
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import Chat from "./user_socket";
import topbar from "../vendor/topbar";
import videojs from "../vendor/video";
import "../vendor/videojs-youtube";

let isVisible = (el) =>
  !!(el.offsetWidth || el.offsetHeight || el.getClientRects().length > 0);

let execJS = (selector, attr) => {
  document
    .querySelectorAll(selector)
    .forEach((el) => liveSocket.execJS(el, el.getAttribute(attr)));
};

let Hooks = {};

Hooks.Flash = {
  mounted() {
    let hide = () =>
      liveSocket.execJS(this.el, this.el.getAttribute("phx-click"));
    this.timer = setTimeout(() => hide(), 8000);
    this.el.addEventListener("phx:hide-start", () => clearTimeout(this.timer));
    this.el.addEventListener("mouseover", () => {
      clearTimeout(this.timer);
      this.timer = setTimeout(() => hide(), 8000);
    });
  },
  destroyed() {
    clearTimeout(this.timer);
  },
};

Hooks.Menu = {
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
};

Hooks.VideoPlayer = {
  mounted() {
    const backdrop = document.querySelector("#video-backdrop");

    this.player = videojs("video-player", {
      autoplay: true,
      liveui: true,
      html5: {
        vhs: {
          llhls: true,
        },
      },
    });

    const playVideo = ({ detail }) => {
      const { player } = detail;
      this.player.options({
        techOrder: [player.type === "video/youtube" ? "youtube" : "html5"],
      });
      this.player.src({ src: player.src, type: player.type });
      this.player.play();
      this.player.el().parentElement.classList.remove("hidden");
      this.player.el().parentElement.classList.add("flex");
      backdrop.classList.remove("opacity-0");
      backdrop.classList.add("opacity-20");
      window.scrollTo(0, 0);
    };

    window.addEventListener("js:play_video", playVideo);
    this.handleEvent("js:play_video", playVideo);

    this.handleEvent("join_chat", Chat.join);
  },
};

Hooks.NavBar = {
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
};

// Accessible focus handling
let Focus = {
  focusMain() {
    let target =
      document.querySelector("main h1") || document.querySelector("main");
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
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {
  hooks: Hooks,
  params: { _csrf_token: csrfToken },
  dom: {
    onNodeAdded(node) {
      if (node instanceof HTMLElement && node.autofocus) {
        node.focus();
      }
    },
  },
});

let routeUpdated = () => {
  // TODO: uncomment
  // Focus.focusMain();
};

// Show progress bar on live navigation and form submits
topbar.config({
  barColors: { 0: "rgba(147, 51, 234, 1)" },
  shadowColor: "rgba(0, 0, 0, .3)",
});
window.addEventListener("phx:page-loading-start", (info) =>
  topbar.delayedShow(200)
);
window.addEventListener("phx:page-loading-stop", (info) => topbar.hide());

// Accessible routing
window.addEventListener("phx:page-loading-stop", routeUpdated);

window.addEventListener("js:exec", (e) =>
  e.target[e.detail.call](...e.detail.args)
);
window.addEventListener("js:focus", (e) => {
  let parent = document.querySelector(e.detail.parent);
  if (parent && isVisible(parent)) {
    e.target.focus();
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
  Focus.attemptFocus(el.parent) || Focus.focusMain();
});
window.addEventListener("phx:remove-el", (e) =>
  document.getElementById(e.detail.id).remove()
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

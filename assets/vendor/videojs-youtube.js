(function (root, factory) {
  if (typeof exports === "object" && typeof module !== "undefined") {
    var videojs = require("./video");
    module.exports = factory(videojs.default || videojs);
  } else if (typeof define === "function" && define.amd) {
    define(["videojs"], function (videojs) {
      return (root.Youtube = factory(videojs));
    });
  } else {
    root.Youtube = factory(root.videojs);
  }
})(this, function (videojs) {
  "use strict";
  var _isOnMobile = videojs.browser.IS_IOS || videojs.browser.IS_NATIVE_ANDROID;
  var Tech = videojs.getTech("Tech");
  class Youtube extends Tech {
    constructor(options, ready) {
      super(options, ready);
      this.setPoster(options.poster);
      this.setSrc(this.options_.source, true);
      this.setTimeout(
        function () {
          if (this.el_) {
            this.el_.parentNode.className += " vjs-youtube";
            if (_isOnMobile) {
              this.el_.parentNode.className += " vjs-youtube-mobile";
            }
            if (Youtube.isApiReady) {
              this.initYTPlayer();
            } else {
              Youtube.apiReadyQueue.push(this);
            }
          }
        }.bind(this)
      );
    }
    dispose() {
      if (this.ytPlayer) {
        if (this.ytPlayer.stopVideo) {
          this.ytPlayer.stopVideo();
        }
        if (this.ytPlayer.destroy) {
          this.ytPlayer.destroy();
        }
      } else {
        var index = Youtube.apiReadyQueue.indexOf(this);
        if (index !== -1) {
          Youtube.apiReadyQueue.splice(index, 1);
        }
      }
      this.ytPlayer = null;
      this.el_.parentNode.className = this.el_.parentNode.className
        .replace(" vjs-youtube", "")
        .replace(" vjs-youtube-mobile", "");
      this.el_.parentNode.removeChild(this.el_);
      Tech.prototype.dispose.call(this);
    }
    createEl() {
      var div = document.createElement("div");
      div.setAttribute("id", this.options_.techId);
      div.setAttribute(
        "style",
        "width:100%;height:100%;top:0;left:0;position:absolute"
      );
      div.setAttribute("class", "vjs-tech");
      var divWrapper = document.createElement("div");
      divWrapper.appendChild(div);
      if (!_isOnMobile && !this.options_.ytControls) {
        var divBlocker = document.createElement("div");
        divBlocker.setAttribute("class", "vjs-iframe-blocker");
        divBlocker.setAttribute(
          "style",
          "position:absolute;top:0;left:0;width:100%;height:100%"
        );
        divBlocker.onclick = function () {
          this.pause();
        }.bind(this);
        divWrapper.appendChild(divBlocker);
      }
      return divWrapper;
    }
    initYTPlayer() {
      var playerVars = {
        controls: 0,
        modestbranding: 1,
        rel: 0,
        showinfo: 0,
        loop: this.options_.loop ? 1 : 0,
      };
      if (typeof this.options_.autohide !== "undefined") {
        playerVars.autohide = this.options_.autohide;
      }
      if (typeof this.options_["cc_load_policy"] !== "undefined") {
        playerVars["cc_load_policy"] = this.options_["cc_load_policy"];
      }
      if (typeof this.options_.ytControls !== "undefined") {
        playerVars.controls = this.options_.ytControls;
      }
      if (typeof this.options_.disablekb !== "undefined") {
        playerVars.disablekb = this.options_.disablekb;
      }
      if (typeof this.options_.color !== "undefined") {
        playerVars.color = this.options_.color;
      }
      if (!playerVars.controls) {
        playerVars.fs = 0;
      } else if (typeof this.options_.fs !== "undefined") {
        playerVars.fs = this.options_.fs;
      }
      if (this.options_.source.src.indexOf("end=") !== -1) {
        var srcEndTime = this.options_.source.src.match(/end=([0-9]*)/);
        this.options_.end = parseInt(srcEndTime[1]);
      }
      if (typeof this.options_.end !== "undefined") {
        playerVars.end = this.options_.end;
      }
      if (typeof this.options_.hl !== "undefined") {
        playerVars.hl = this.options_.hl;
      } else if (typeof this.options_.language !== "undefined") {
        playerVars.hl = this.options_.language.substr(0, 2);
      }
      if (typeof this.options_["iv_load_policy"] !== "undefined") {
        playerVars["iv_load_policy"] = this.options_["iv_load_policy"];
      }
      if (typeof this.options_.list !== "undefined") {
        playerVars.list = this.options_.list;
      } else if (this.url && typeof this.url.listId !== "undefined") {
        playerVars.list = this.url.listId;
      }
      if (typeof this.options_.listType !== "undefined") {
        playerVars.listType = this.options_.listType;
      }
      if (typeof this.options_.modestbranding !== "undefined") {
        playerVars.modestbranding = this.options_.modestbranding;
      }
      if (typeof this.options_.playlist !== "undefined") {
        playerVars.playlist = this.options_.playlist;
      }
      if (typeof this.options_.playsinline !== "undefined") {
        playerVars.playsinline = this.options_.playsinline;
      }
      if (typeof this.options_.rel !== "undefined") {
        playerVars.rel = this.options_.rel;
      }
      if (typeof this.options_.showinfo !== "undefined") {
        playerVars.showinfo = this.options_.showinfo;
      }
      if (this.options_.source.src.indexOf("start=") !== -1) {
        var srcStartTime = this.options_.source.src.match(/start=([0-9]*)/);
        this.options_.start = parseInt(srcStartTime[1]);
      }
      if (typeof this.options_.start !== "undefined") {
        playerVars.start = this.options_.start;
      }
      if (typeof this.options_.theme !== "undefined") {
        playerVars.theme = this.options_.theme;
      }
      if (typeof this.options_.customVars !== "undefined") {
        var customVars = this.options_.customVars;
        Object.keys(customVars).forEach(function (key) {
          playerVars[key] = customVars[key];
        });
      }
      this.activeVideoId = this.url ? this.url.videoId : null;
      this.activeList = playerVars.list;
      var playerConfig = {
        videoId: this.activeVideoId,
        playerVars: playerVars,
        events: {
          onReady: this.onPlayerReady.bind(this),
          onPlaybackQualityChange:
            this.onPlayerPlaybackQualityChange.bind(this),
          onPlaybackRateChange: this.onPlayerPlaybackRateChange.bind(this),
          onStateChange: this.onPlayerStateChange.bind(this),
          onVolumeChange: this.onPlayerVolumeChange.bind(this),
          onError: this.onPlayerError.bind(this),
        },
      };
      if (
        typeof this.options_.enablePrivacyEnhancedMode !== "undefined" &&
        this.options_.enablePrivacyEnhancedMode
      ) {
        playerConfig.host = "https://www.youtube-nocookie.com";
      }
      this.ytPlayer = new YT.Player(this.options_.techId, playerConfig);
    }
    onPlayerReady() {
      if (this.options_.muted) {
        this.ytPlayer.mute();
      }
      var playbackRates = this.ytPlayer.getAvailablePlaybackRates();
      if (playbackRates.length > 1) {
        this.featuresPlaybackRate = true;
      }
      this.playerReady_ = true;
      this.triggerReady();
      if (this.playOnReady) {
        this.play();
      } else if (this.cueOnReady) {
        this.cueVideoById_(this.url.videoId);
        this.activeVideoId = this.url.videoId;
      }
    }
    onPlayerPlaybackQualityChange() {}
    onPlayerPlaybackRateChange() {
      this.trigger("ratechange");
    }
    onPlayerStateChange(e) {
      var state = e.data;
      if (state === this.lastState || this.errorNumber) {
        return;
      }
      this.lastState = state;
      switch (state) {
        case -1:
          this.trigger("loadstart");
          this.trigger("loadedmetadata");
          this.trigger("durationchange");
          this.trigger("ratechange");
          break;
        case YT.PlayerState.ENDED:
          this.trigger("ended");
          break;
        case YT.PlayerState.PLAYING:
          this.trigger("timeupdate");
          this.trigger("durationchange");
          this.trigger("playing");
          this.trigger("play");
          if (this.isSeeking) {
            this.onSeeked();
          }
          break;
        case YT.PlayerState.PAUSED:
          this.trigger("canplay");
          if (this.isSeeking) {
            this.onSeeked();
          } else {
            this.trigger("pause");
          }
          break;
        case YT.PlayerState.BUFFERING:
          this.player_.trigger("timeupdate");
          this.player_.trigger("waiting");
          break;
      }
    }
    onPlayerVolumeChange() {
      this.trigger("volumechange");
    }
    onPlayerError(e) {
      this.errorNumber = e.data;
      this.trigger("pause");
      this.trigger("error");
    }
    error() {
      var code = 1e3 + this.errorNumber;
      switch (this.errorNumber) {
        case 5:
          return {
            code: code,
            message: "Error while trying to play the video",
          };
        case 2:
        case 100:
          return { code: code, message: "Unable to find the video" };
        case 101:
        case 150:
          return {
            code: code,
            message:
              "Playback on other Websites has been disabled by the video owner.",
          };
      }
      return {
        code: code,
        message: "YouTube unknown error (" + this.errorNumber + ")",
      };
    }
    loadVideoById_(id) {
      var options = { videoId: id };
      if (this.options_.start) {
        options.startSeconds = this.options_.start;
      }
      if (this.options_.end) {
        options.endSeconds = this.options_.end;
      }
      this.ytPlayer.loadVideoById(options);
    }
    cueVideoById_(id) {
      var options = { videoId: id };
      if (this.options_.start) {
        options.startSeconds = this.options_.start;
      }
      if (this.options_.end) {
        options.endSeconds = this.options_.end;
      }
      this.ytPlayer.cueVideoById(options);
    }
    src(src) {
      if (src) {
        this.setSrc({ src: src });
      }
      return this.source;
    }
    poster() {
      if (_isOnMobile) {
        return null;
      }
      return this.poster_;
    }
    setPoster(poster) {
      this.poster_ = poster;
    }
    setSrc(source) {
      if (!source || !source.src) {
        return;
      }
      delete this.errorNumber;
      this.source = source;
      this.url = Youtube.parseUrl(source.src);
      if (!this.options_.poster) {
        if (this.url.videoId) {
          this.poster_ =
            "https://img.youtube.com/vi/" + this.url.videoId + "/0.jpg";
          this.trigger("posterchange");
          this.checkHighResPoster();
        }
      }
      if (this.options_.autoplay && !_isOnMobile) {
        if (this.isReady_) {
          this.play();
        } else {
          this.playOnReady = true;
        }
      } else if (this.activeVideoId !== this.url.videoId) {
        if (this.isReady_) {
          this.cueVideoById_(this.url.videoId);
          this.activeVideoId = this.url.videoId;
        } else {
          this.cueOnReady = true;
        }
      }
    }
    autoplay() {
      return this.options_.autoplay;
    }
    setAutoplay(val) {
      this.options_.autoplay = val;
    }
    loop() {
      return this.options_.loop;
    }
    setLoop(val) {
      this.options_.loop = val;
    }
    play() {
      if (!this.url || !this.url.videoId) {
        return;
      }
      this.wasPausedBeforeSeek = false;
      if (this.isReady_) {
        if (this.url.listId) {
          if (this.activeList === this.url.listId) {
            this.ytPlayer.playVideo();
          } else {
            this.ytPlayer.loadPlaylist(this.url.listId);
            this.activeList = this.url.listId;
          }
        }
        if (this.activeVideoId === this.url.videoId) {
          this.ytPlayer.playVideo();
        } else {
          this.loadVideoById_(this.url.videoId);
          this.activeVideoId = this.url.videoId;
        }
      } else {
        this.trigger("waiting");
        this.playOnReady = true;
      }
    }
    pause() {
      if (this.ytPlayer) {
        this.ytPlayer.pauseVideo();
      }
    }
    paused() {
      return this.ytPlayer
        ? this.lastState !== YT.PlayerState.PLAYING &&
            this.lastState !== YT.PlayerState.BUFFERING
        : true;
    }
    currentTime() {
      return this.ytPlayer ? this.ytPlayer.getCurrentTime() : 0;
    }
    setCurrentTime(seconds) {
      if (this.lastState === YT.PlayerState.PAUSED) {
        this.timeBeforeSeek = this.currentTime();
      }
      if (!this.isSeeking) {
        this.wasPausedBeforeSeek = this.paused();
      }
      this.ytPlayer.seekTo(seconds, true);
      this.trigger("timeupdate");
      this.trigger("seeking");
      this.isSeeking = true;
      if (
        this.lastState === YT.PlayerState.PAUSED &&
        this.timeBeforeSeek !== seconds
      ) {
        clearInterval(this.checkSeekedInPauseInterval);
        this.checkSeekedInPauseInterval = setInterval(
          function () {
            if (this.lastState !== YT.PlayerState.PAUSED || !this.isSeeking) {
              clearInterval(this.checkSeekedInPauseInterval);
            } else if (this.currentTime() !== this.timeBeforeSeek) {
              this.trigger("timeupdate");
              this.onSeeked();
            }
          }.bind(this),
          250
        );
      }
    }
    seeking() {
      return this.isSeeking;
    }
    seekable() {
      if (!this.ytPlayer) {
        return videojs.createTimeRange();
      }
      return videojs.createTimeRange(0, this.ytPlayer.getDuration());
    }
    onSeeked() {
      clearInterval(this.checkSeekedInPauseInterval);
      this.isSeeking = false;
      if (this.wasPausedBeforeSeek) {
        this.pause();
      }
      this.trigger("seeked");
    }
    playbackRate() {
      return this.ytPlayer ? this.ytPlayer.getPlaybackRate() : 1;
    }
    setPlaybackRate(suggestedRate) {
      if (!this.ytPlayer) {
        return;
      }
      this.ytPlayer.setPlaybackRate(suggestedRate);
    }
    duration() {
      return this.ytPlayer ? this.ytPlayer.getDuration() : 0;
    }
    currentSrc() {
      return this.source && this.source.src;
    }
    ended() {
      return this.ytPlayer ? this.lastState === YT.PlayerState.ENDED : false;
    }
    volume() {
      return this.ytPlayer ? this.ytPlayer.getVolume() / 100 : 1;
    }
    setVolume(percentAsDecimal) {
      if (!this.ytPlayer) {
        return;
      }
      this.ytPlayer.setVolume(percentAsDecimal * 100);
    }
    muted() {
      return this.ytPlayer ? this.ytPlayer.isMuted() : false;
    }
    setMuted(mute) {
      if (!this.ytPlayer) {
        return;
      } else {
        this.muted(true);
      }
      if (mute) {
        this.ytPlayer.mute();
      } else {
        this.ytPlayer.unMute();
      }
      this.setTimeout(function () {
        this.trigger("volumechange");
      }, 50);
    }
    buffered() {
      if (!this.ytPlayer || !this.ytPlayer.getVideoLoadedFraction) {
        return videojs.createTimeRange();
      }
      var bufferedEnd =
        this.ytPlayer.getVideoLoadedFraction() * this.ytPlayer.getDuration();
      return videojs.createTimeRange(0, bufferedEnd);
    }
    preload() {}
    load() {}
    reset() {}
    networkState() {
      if (!this.ytPlayer) {
        return 0;
      }
      switch (this.ytPlayer.getPlayerState()) {
        case -1:
          return 0;
        case 3:
          return 2;
        default:
          return 1;
      }
    }
    readyState() {
      if (!this.ytPlayer) {
        return 0;
      }
      switch (this.ytPlayer.getPlayerState()) {
        case -1:
          return 0;
        case 5:
          return 1;
        case 3:
          return 2;
        default:
          return 4;
      }
    }
    supportsFullScreen() {
      return (
        document.fullscreenEnabled ||
        document.webkitFullscreenEnabled ||
        document.mozFullScreenEnabled ||
        document.msFullscreenEnabled
      );
    }
    checkHighResPoster() {
      var uri =
        "https://img.youtube.com/vi/" + this.url.videoId + "/maxresdefault.jpg";
      try {
        var image = new Image();
        image.onload = function () {
          if ("naturalHeight" in image) {
            if (image.naturalHeight <= 90 || image.naturalWidth <= 120) {
              return;
            }
          } else if (image.height <= 90 || image.width <= 120) {
            return;
          }
          this.poster_ = uri;
          this.trigger("posterchange");
        }.bind(this);
        image.onerror = function () {};
        image.src = uri;
      } catch (e) {}
    }
  }
  Youtube.isSupported = function () {
    return true;
  };
  Youtube.canPlaySource = function (e) {
    return Youtube.canPlayType(e.type);
  };
  Youtube.canPlayType = function (e) {
    return e === "video/youtube";
  };
  Youtube.parseUrl = function (url) {
    var result = { videoId: null };
    var regex =
      /^.*(youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=|\&v=)([^#\&\?]*).*/;
    var match = url.match(regex);
    if (match && match[2].length === 11) {
      result.videoId = match[2];
    }
    var regPlaylist = /[?&]list=([^#\&\?]+)/;
    match = url.match(regPlaylist);
    if (match && match[1]) {
      result.listId = match[1];
    }
    return result;
  };
  function apiLoaded() {
    YT.ready(function () {
      Youtube.isApiReady = true;
      for (var i = 0; i < Youtube.apiReadyQueue.length; ++i) {
        Youtube.apiReadyQueue[i].initYTPlayer();
      }
    });
  }
  function loadScript(src, callback) {
    var loaded = false;
    var tag = document.createElement("script");
    var firstScriptTag = document.getElementsByTagName("script")[0];
    if (!firstScriptTag) {
      return;
    }
    firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);
    tag.onload = function () {
      if (!loaded) {
        loaded = true;
        callback();
      }
    };
    tag.onreadystatechange = function () {
      if (
        !loaded &&
        (this.readyState === "complete" || this.readyState === "loaded")
      ) {
        loaded = true;
        callback();
      }
    };
    tag.src = src;
  }
  function injectCss() {
    var css =
      ".vjs-youtube .vjs-iframe-blocker { display: none; }" +
      ".vjs-youtube.vjs-user-inactive .vjs-iframe-blocker { display: block; }" +
      ".vjs-youtube .vjs-poster { background-size: cover; }" +
      ".vjs-youtube-mobile .vjs-big-play-button { display: none; }";
    var head = document.head || document.getElementsByTagName("head")[0];
    var style = document.createElement("style");
    style.type = "text/css";
    if (style.styleSheet) {
      style.styleSheet.cssText = css;
    } else {
      style.appendChild(document.createTextNode(css));
    }
    head.appendChild(style);
  }
  Youtube.apiReadyQueue = [];
  if (typeof document !== "undefined") {
    loadScript("https://www.youtube.com/iframe_api", apiLoaded);
    injectCss();
  }
  if (typeof videojs.registerTech !== "undefined") {
    videojs.registerTech("Youtube", Youtube);
  } else {
    videojs.registerComponent("Youtube", Youtube);
  }
});

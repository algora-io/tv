# Script for populating the database. You can run it as:
#
#     env $(cat .env | xargs -L 1) mix run priv/repo/seeds.exs

alias Algora.{Repo, Accounts}
alias Algora.Accounts.User
alias Algora.Library.Video
alias Algora.Shows.Show

user =
  case Accounts.get_user_by(handle: "algora") do
    nil ->
      Repo.insert!(%User{
        handle: "algora",
        name: "Algora",
        avatar_url: "https://fly.storage.tigris.dev/algora/test/algora.png",
        email: "algora@example.com",
        visibility: :public,
        is_live: true
      })

    existing_user ->
      existing_user
  end

Repo.insert!(%Video{
  user_id: user.id,
  url: "https://stream.mux.com/v69RSHhFelSm4701snP22dYz2jICy4E4FUyk02rW4gxRM.m3u8",
  title:
    "Low-Latency HLS sample of Big Buck Bunny loop and a timer. Restarts every 12 hours. (fMP4 segments)",
  thumbnail_url: "https://fly.storage.tigris.dev/algora/test/big-buck-bunny-llhls.png",
  format: :hls,
  type: :livestream,
  visibility: :public,
  is_live: true,
  uuid: Ecto.UUID.generate()
})

Repo.insert!(%Video{
  user_id: user.id,
  url: "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8",
  title: "Big Buck Bunny - adaptive qualities",
  thumbnail_url: "https://fly.storage.tigris.dev/algora/test/big-buck-bunny-adaptive.png",
  format: :hls,
  type: :vod,
  duration: 634,
  visibility: :public,
  uuid: Ecto.UUID.generate()
})

Repo.insert!(%Video{
  user_id: user.id,
  url: "https://test-streams.mux.dev/tos_ismc/main.m3u8",
  title: "Tears of Steel, HLS with IMSC Captions",
  thumbnail_url: "https://fly.storage.tigris.dev/algora/test/tears-of-steel.png",
  format: :hls,
  type: :vod,
  duration: 734,
  visibility: :public,
  uuid: Ecto.UUID.generate()
})

Repo.insert!(%Video{
  user_id: user.id,
  url: "https://test-streams.mux.dev/dai-discontinuity-deltatre/manifest.m3u8",
  title: "Deltatre/BT DAI discontinuity",
  thumbnail_url: "https://fly.storage.tigris.dev/algora/test/dai-discontinuity-deltatre.png",
  format: :hls,
  type: :vod,
  duration: 266,
  visibility: :public,
  uuid: Ecto.UUID.generate()
})

Repo.insert!(%Video{
  user_id: user.id,
  url: "https://test-streams.mux.dev/pts_shift/master.m3u8",
  title: "DK Turntable, PTS shifted by 2.3s",
  thumbnail_url: "https://fly.storage.tigris.dev/algora/test/dk-turntable-pts-shifted.png",
  format: :hls,
  type: :vod,
  duration: 165,
  visibility: :public,
  uuid: Ecto.UUID.generate()
})

Repo.insert!(%Video{
  user_id: user.id,
  url:
    "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_adv_example_hevc/master.m3u8",
  title: "Advanced stream (HEVC/H.264, AC-3/AAC, WebVTT, fMP4 segments)",
  thumbnail_url: "https://fly.storage.tigris.dev/algora/test/advanced-stream.png",
  format: :hls,
  type: :vod,
  duration: 600,
  visibility: :public,
  uuid: Ecto.UUID.generate()
})

Repo.insert!(%Video{
  user_id: user.id,
  url: "https://www.youtube.com/watch?v=_cMxraX_5RE",
  title: "Sprite Fright (YouTube)",
  thumbnail_url: "https://i.ytimg.com/vi/_cMxraX_5RE/maxresdefault.jpg",
  format: :youtube,
  type: :vod,
  duration: 629,
  visibility: :public,
  uuid: Ecto.UUID.generate()
})

[
  %{
    handle: "glommer",
    name: "Glauber Costa",
    avatar_url: "https://avatars.githubusercontent.com/u/331197?v=4",
    channel_tagline: "The Save File Ep. 15"
  },
  %{
    handle: "spirodonfl",
    name: "Spiro Floropoulos",
    avatar_url: "https://avatars.githubusercontent.com/u/314869?v=4",
    channel_tagline:
      "X_TECH_LEAD-- = Videogame work, content, Laravel/HTMX, so much #zig #webassembly"
  },
  %{
    handle: "heyandras",
    name: "Andras Bacsai",
    avatar_url: "https://avatars.githubusercontent.com/u/5845193?v=4",
    channel_tagline: "Hangout, coding & open-source"
  },
  %{
    handle: "danielroe",
    name: "Daniel Roe",
    avatar_url: "https://avatars.githubusercontent.com/u/28706372?v=4",
    channel_tagline: "🚦 nitro + nuxt ecosystem testing"
  },
  %{
    handle: "cmgriffing",
    name: "cmgriffing",
    avatar_url: "https://avatars.githubusercontent.com/u/1195435?v=4",
    channel_tagline: "🔐 Rolling my own auth: 2FA"
  },
  %{
    handle: "LLCoolChris_",
    name: "Christopher N. KATOYI",
    avatar_url: "https://avatars.githubusercontent.com/u/16650656?v=4",
    channel_tagline:
      "🥸 [FR/EN] 24H OCaml with Codecrafters & Exercism | Some Wukong Gaming | Stuff"
  },
  %{
    handle: "PeerRich",
    name: "Peer Richelsen",
    avatar_url: "https://avatars.githubusercontent.com/u/8019099?v=4",
    channel_tagline: "COSS Office Hours with @peer_rich from Cal.com"
  },
  %{
    handle: "rfc",
    name: "Andreas Klinger",
    avatar_url: "https://avatars.githubusercontent.com/u/245833?v=4",
    channel_tagline: "🇪🇺 Let's talk eu/acc! 🔴 LIVE - Chat @ rfc.to 🎉"
  },
  %{
    handle: "McPizza0",
    name: "McPizza",
    avatar_url: "https://avatars.githubusercontent.com/u/17185737?v=4",
    channel_tagline: "Working through some business features"
  },
  %{
    handle: "jehrhardt",
    name: "Jan Ehrhardt",
    avatar_url: "https://avatars.githubusercontent.com/u/59441?v=4",
    channel_tagline: "Building Cozy Auth - Elixir Rewrite and going wild on Claude AI 🚀"
  },
  %{
    handle: "zachdaniel",
    name: "Zach Daniel",
    avatar_url: "https://avatars.githubusercontent.com/u/5722339?v=4",
    channel_tagline: "Writing rad Elixir"
  },
  %{
    handle: "midday",
    name: "Midday",
    avatar_url: "https://avatars.githubusercontent.com/u/655158?v=4",
    channel_tagline: "Midday Product Hunt Launch"
  }
]
|> Enum.each(fn user_data ->
  case Accounts.get_user_by(handle: user_data.handle) do
    nil ->
      Repo.insert!(%User{
        handle: user_data.handle,
        name: user_data.name,
        avatar_url: user_data.avatar_url,
        email: "#{user_data.handle}@example.com",
        visibility: :public,
        is_live: false,
        channel_tagline: user_data.channel_tagline
      })

    existing_user ->
      existing_user
  end
end)

[
  %{
    title: "Build in public",
    slug: "buildinpublic",
    image_url: "https://fly.storage.tigris.dev/algora/shows/7/cover/1717089683"
  },
  %{
    title: "Solving bounties live",
    slug: "bounties",
    image_url: "https://fly.storage.tigris.dev/algora/shows/5/cover/1717077107"
  },
  %{
    title: "COSS Founder Podcast",
    slug: "coss-founder-podcast",
    image_url: "https://fly.storage.tigris.dev/algora/shows/4/cover/1717076436"
  },
  %{
    title: "eu/acc - Update :)",
    slug: "eu-acc",
    scheduled_for: ~N[2024-05-31 16:00:00],
    image_url: "https://fly.storage.tigris.dev/algora/shows/2/cover/1716648718"
  },
  %{
    title: "The Save File",
    slug: "the_savefile",
    scheduled_for: ~N[2024-06-21 17:30:00],
    image_url: "https://fly.storage.tigris.dev/algora/shows/8/cover/1717155673"
  },
  %{
    title: "RFC 007 - Demos!",
    slug: "rfc",
    image_url: "https://fly.storage.tigris.dev/algora/shows/1/cover/1716648933"
  },
  %{
    title: "COSS Office Hours",
    slug: "coss",
    image_url: "https://fly.storage.tigris.dev/algora/shows/3/cover/1716657591"
  },
  %{
    title: "The TSPerf Challenge",
    slug: "tsperf",
    image_url: "https://fly.storage.tigris.dev/algora/shows/6/cover/1717861791"
  }
]
|> Enum.with_index(1)
|> Enum.each(fn {show_data, index} ->
  case Repo.get_by(Show, slug: show_data.slug) do
    nil ->
      Repo.insert!(%Show{
        user_id: user.id,
        title: show_data.title,
        slug: show_data.slug,
        scheduled_for: Map.get(show_data, :scheduled_for),
        image_url: show_data.image_url,
        ordering: index
      })

    existing_show ->
      existing_show
  end
end)

# Script for populating the database. You can run it as:
#
#     env $(cat .env | xargs -L 1) mix run priv/repo/seeds.exs

alias Algora.Repo
alias Algora.Accounts.User
alias Algora.Library.Video

user =
  Repo.insert!(%User{
    handle: "algora",
    name: "Algora",
    avatar_url: "https://fly.storage.tigris.dev/algora/test/algora.png",
    email: "algora@example.com",
    visibility: :public,
    is_live: true
  })

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

defmodule AlgoraWeb.PartnerLive do
  use AlgoraWeb, :live_view
  require Logger

  alias AlgoraWeb.LayoutComponent
  alias Algora.Contact
  alias Algora.Contact.Info

  def render(assigns) do
    ~H"""
    <div class="bg-gray-950 font-display">
      <main>
        <!-- Hero section -->
        <div class="relative isolate overflow-hidden">
          <svg
            class="absolute inset-0 -z-10 h-full w-full stroke-white/10 [mask-image:radial-gradient(100%_100%_at_top_right,white,transparent)]"
            aria-hidden="true"
          >
            <defs>
              <pattern
                id="983e3e4c-de6d-4c3f-8d64-b9761d1534cc"
                width="200"
                height="200"
                x="50%"
                y="-1"
                patternUnits="userSpaceOnUse"
              >
                <path d="M.5 200V.5H200" fill="none" />
              </pattern>
            </defs>
            <svg x="50%" y="-1" class="overflow-visible fill-gray-800/20">
              <path
                d="M-200 0h201v201h-201Z M600 0h201v201h-201Z M-400 600h201v201h-201Z M200 800h201v201h-201Z"
                stroke-width="0"
              />
            </svg>
            <rect
              width="100%"
              height="100%"
              stroke-width="0"
              fill="url(#983e3e4c-de6d-4c3f-8d64-b9761d1534cc)"
            />
          </svg>
          <div
            class="absolute left-[calc(50%-4rem)] top-10 -z-10 transform blur-3xl sm:left-[calc(50%-18rem)] lg:left-48 lg:top-[calc(50%-30rem)] xl:left-[calc(50%-24rem)]"
            aria-hidden="true"
          >
            <div
              class="aspect-[1108/632] w-[69.25rem] bg-gradient-to-r from-[#80caff] to-[#4f46e5] opacity-20"
              style="clip-path: polygon(73.6% 51.7%, 91.7% 11.8%, 100% 46.4%, 97.4% 82.2%, 92.5% 84.9%, 75.7% 64%, 55.3% 47.5%, 46.5% 49.4%, 45% 62.9%, 50.3% 87.2%, 21.3% 64.1%, 0.1% 100%, 5.4% 51.1%, 21.4% 63.9%, 58.9% 0.2%, 73.6% 51.7%)"
            >
            </div>
          </div>
          <div class="mx-auto px-6 pb-24 pt-10 sm:pb-40 lg:flex lg:px-20 lg:pt-40 gap-8">
            <div class="mx-auto max-w-3xl flex-shrink-0 lg:mx-0 lg:ml-auto lg:max-w-lg lg:pt-8">
              <.logo />

              <h1 class="mt-10 text-4xl font-bold tracking-tight text-white sm:text-5xl">
                Your most successful<br class="hidden sm:inline" />
                <span class="text-green-300">ad campaign</span>
                is just<br class="hidden sm:inline" /> a few livestreams away
              </h1>
              <p class="mt-6 text-xl leading-8 tracking-tight text-gray-300">
                In-video livestream ads that help you stand out<br class="hidden sm:inline" />
                in front of millions on Twitch, YouTube and X.
              </p>
              <div class="hidden lg:mt-10 lg:flex items-center gap-x-6">
                <a
                  href="#contact-form"
                  class="rounded-md bg-indigo-500 px-3.5 py-2.5 text-lg font-semibold text-white shadow-sm hover:bg-indigo-400 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-400"
                >
                  Get started
                </a>
              </div>
            </div>
            <div class="mx-auto max-w-2xl xl:max-w-3xl aspect-video w-full h-full flex-shrink-0 mt-12 flex lg:mt-6 xl:mt-0">
              <.link
                class="cursor-pointer truncate w-full"
                href="https://www.youtube.com/watch?v=te6k6EfHjnI"
                rel="noopener"
                target="_blank"
              >
                <div class="relative flex items-center justify-center overflow-hidden aspect-[16/9] bg-gray-800 rounded-sm">
                  <img
                    src={~p"/images/live-billboard.png"}
                    alt="Algora Live Billboards"
                    class="absolute w-full h-full object-cover z-10"
                  />
                  <div class="absolute font-medium text-xs px-2 py-0.5 rounded-xl bottom-1 bg-gray-950/90 text-white right-1 z-20">
                    2:27
                  </div>
                </div>
              </.link>
            </div>
          </div>
        </div>
        <!-- Feature section -->
        <div class="mt-16 sm:mt-28">
          <div class="mx-auto max-w-7xl px-6 lg:px-8">
            <div class="mx-auto max-w-4xl sm:text-center">
              <h2 class="mt-2 text-4xl font-bold tracking-tight text-white sm:text-5xl">
                Influencer Marketing on Autopilot
              </h2>
              <p class="mt-6 text-xl sm:text-2xl leading-8 tracking-tight text-gray-300">
                Distribute your ad creatives to the most engaged tech audience in-video and measure success with our comprehensive analytics
              </p>
            </div>
          </div>
          <div class="relative overflow-hidden pt-16">
            <div class="mx-auto max-w-7xl px-6 lg:px-8">
              <img
                src={~p"/images/analytics.png"}
                alt="Analytics"
                class="rounded-xl shadow-2xl ring-1 ring-white/10"
                width="1648"
                height="800"
              />
              <div class="relative" aria-hidden="true">
                <div class="absolute -inset-x-20 bottom-0 bg-gradient-to-t from-gray-950 pt-[20%]">
                </div>
              </div>
            </div>
          </div>
          <div class="mx-auto mt-16 max-w-7xl px-6 sm:mt-20 md:mt-24 lg:px-8">
            <dl class="mx-auto grid max-w-2xl grid-cols-1 gap-x-6 gap-y-10 text-base leading-7 text-gray-300 sm:grid-cols-2 lg:mx-0 lg:max-w-none lg:grid-cols-3 lg:gap-x-8 lg:gap-y-16">
              <div class="relative pl-9">
                <dt class="inline font-semibold text-white">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    width="24"
                    height="24"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    stroke-width="2"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    class="absolute left-0 top-0 h-6 w-6 text-indigo-500"
                  >
                    <path stroke="none" d="M0 0h24v24H0z" fill="none" /><path d="M4 17v2a2 2 0 0 0 2 2h12a2 2 0 0 0 2 -2v-2" /><path d="M7 9l5 -5l5 5" /><path d="M12 4l0 12" />
                  </svg>
                  Easy Upload
                </dt>
                <dd class="inline">
                  Upload your ad creatives quickly and easily through our intuitive interface.
                </dd>
              </div>
              <div class="relative pl-9">
                <dt class="inline font-semibold text-white">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    width="24"
                    height="24"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    stroke-width="2"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    class="absolute left-0 top-0 h-6 w-6 text-indigo-500"
                  >
                    <path stroke="none" d="M0 0h24v24H0z" fill="none" /><path d="M12 12m-1 0a1 1 0 1 0 2 0a1 1 0 1 0 -2 0" /><path d="M12 7a5 5 0 1 0 5 5" /><path d="M13 3.055a9 9 0 1 0 7.941 7.945" /><path d="M15 6v3h3l3 -3h-3v-3z" /><path d="M15 9l-3 3" />
                  </svg>
                  Targeted Audience Reach
                </dt>
                <dd class="inline">
                  Connect with a highly engaged, tech-focused audience across multiple streaming platforms.
                </dd>
              </div>
              <div class="relative pl-9">
                <dt class="inline font-semibold text-white">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    width="24"
                    height="24"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    stroke-width="2"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    class="absolute left-0 top-0 h-6 w-6 text-indigo-500"
                  >
                    <path stroke="none" d="M0 0h24v24H0z" fill="none" /><path d="M5 5m0 1a1 1 0 0 1 1 -1h12a1 1 0 0 1 1 1v12a1 1 0 0 1 -1 1h-12a1 1 0 0 1 -1 -1z" /><path d="M9 9h6v6h-6z" /><path d="M3 10h2" /><path d="M3 14h2" /><path d="M10 3v2" /><path d="M14 3v2" /><path d="M21 10h-2" /><path d="M21 14h-2" /><path d="M14 21v-2" /><path d="M10 21v-2" />
                  </svg>
                  Automated Placement
                </dt>
                <dd class="inline">
                  Our system automatically places your ads in relevant tech content.
                </dd>
              </div>
              <div class="relative pl-9">
                <dt class="inline font-semibold text-white">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    width="24"
                    height="24"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    stroke-width="2"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    class="absolute left-0 top-0 h-6 w-6 text-indigo-500"
                  >
                    <path stroke="none" d="M0 0h24v24H0z" fill="none" /><path d="M10 13a2 2 0 1 0 4 0a2 2 0 0 0 -4 0" /><path d="M8 21v-1a2 2 0 0 1 2 -2h4a2 2 0 0 1 2 2v1" /><path d="M15 5a2 2 0 1 0 4 0a2 2 0 0 0 -4 0" /><path d="M17 10h2a2 2 0 0 1 2 2v1" /><path d="M5 5a2 2 0 1 0 4 0a2 2 0 0 0 -4 0" /><path d="M3 13v-1a2 2 0 0 1 2 -2h2" />
                  </svg>
                  Wide Reach
                </dt>
                <dd class="inline">
                  Access a vast network of tech-savvy viewers through our platform.
                </dd>
              </div>
              <div class="relative pl-9">
                <dt class="inline font-semibold text-white">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    width="24"
                    height="24"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    stroke-width="2"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    class="absolute left-0 top-0 h-6 w-6 text-indigo-500"
                  >
                    <path stroke="none" d="M0 0h24v24H0z" fill="none" /><path d="M3 3v18h18" /><path d="M20 18v3" /><path d="M16 16v5" /><path d="M12 13v8" /><path d="M8 16v5" /><path d="M3 11c6 0 5 -5 9 -5s3 5 9 5" />
                  </svg>
                  Detailed Analytics
                </dt>
                <dd class="inline">
                  Get comprehensive insights into your ad performance with our powerful analytics tools.
                </dd>
              </div>
              <div class="relative pl-9">
                <dt class="inline font-semibold text-white">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    width="24"
                    height="24"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    stroke-width="2"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    class="absolute left-0 top-0 h-6 w-6 text-indigo-500"
                  >
                    <path stroke="none" d="M0 0h24v24H0z" fill="none" /><path d="M17 8v-3a1 1 0 0 0 -1 -1h-10a2 2 0 0 0 0 4h12a1 1 0 0 1 1 1v3m0 4v3a1 1 0 0 1 -1 1h-12a2 2 0 0 1 -2 -2v-12" /><path d="M20 12v4h-4a2 2 0 0 1 0 -4h4" />
                  </svg>
                  Smart Spending
                </dt>
                <dd class="inline">
                  Get more bang for your buck with our clever, targeted ad approach.
                </dd>
              </div>
            </dl>
          </div>
        </div>
      </main>

      <div class="py-12">
        <div class="mx-auto max-w-7xl px-4">
          <div class="mx-auto mt-16 max-w-2xl rounded-3xl bg-white/5 ring-2 ring-purple-500 sm:mt-20 lg:mx-0 lg:flex lg:max-w-none">
            <div class="p-8 sm:p-10 lg:flex-auto">
              <h3 class="text-3xl font-bold tracking-tight text-white">
                Become an Algora TV Partner
              </h3>
              <p class="mt-6 text-lg leading-7 text-gray-200">
                We only partner with 5 devtool companies every month
              </p>
              <div class="mt-10 flex items-center gap-x-4">
                <h4 class="flex-none text-base font-semibold leading-6 text-indigo-300">
                  What's included
                </h4>
                <div class="h-px flex-auto bg-indigo-400/40"></div>
              </div>
              <ul
                role="list"
                class="mt-8 grid grid-cols-1 gap-4 text-base leading-6 text-gray-200 sm:grid-cols-2 sm:gap-6"
              >
                <li class="flex gap-x-3">
                  <svg
                    class="h-6 w-5 flex-none text-purple-300"
                    viewBox="0 0 20 20"
                    fill="currentColor"
                    aria-hidden="true"
                  >
                    <path
                      fill-rule="evenodd"
                      d="M16.704 4.153a.75.75 0 01.143 1.052l-8 10.5a.75.75 0 01-1.127.075l-4.5-4.5a.75.75 0 011.06-1.06l3.894 3.893 7.48-9.817a.75.75 0 011.05-.143z"
                      clip-rule="evenodd"
                    />
                  </svg>
                  5 streamer airtime
                </li>
                <li class="flex gap-x-3">
                  <svg
                    class="h-6 w-5 flex-none text-purple-300"
                    viewBox="0 0 20 20"
                    fill="currentColor"
                    aria-hidden="true"
                  >
                    <path
                      fill-rule="evenodd"
                      d="M16.704 4.153a.75.75 0 01.143 1.052l-8 10.5a.75.75 0 01-1.127.075l-4.5-4.5a.75.75 0 011.06-1.06l3.894 3.893 7.48-9.817a.75.75 0 011.05-.143z"
                      clip-rule="evenodd"
                    />
                  </svg>
                  50 ad appearances
                </li>
                <li class="flex gap-x-3">
                  <svg
                    class="h-6 w-5 flex-none text-purple-300"
                    viewBox="0 0 20 20"
                    fill="currentColor"
                    aria-hidden="true"
                  >
                    <path
                      fill-rule="evenodd"
                      d="M16.704 4.153a.75.75 0 01.143 1.052l-8 10.5a.75.75 0 01-1.127.075l-4.5-4.5a.75.75 0 011.06-1.06l3.894 3.893 7.48-9.817a.75.75 0 011.05-.143z"
                      clip-rule="evenodd"
                    />
                  </svg>
                  5 live reactions
                </li>
                <li class="flex gap-x-3">
                  <svg
                    class="h-6 w-5 flex-none text-purple-300"
                    viewBox="0 0 20 20"
                    fill="currentColor"
                    aria-hidden="true"
                  >
                    <path
                      fill-rule="evenodd"
                      d="M16.704 4.153a.75.75 0 01.143 1.052l-8 10.5a.75.75 0 01-1.127.075l-4.5-4.5a.75.75 0 011.06-1.06l3.894 3.893 7.48-9.817a.75.75 0 011.05-.143z"
                      clip-rule="evenodd"
                    />
                  </svg>
                  5 weeks completion
                </li>
              </ul>
            </div>
            <div class="-mt-2 p-2 lg:mt-0 lg:w-full lg:max-w-md lg:flex-shrink-0 h-full">
              <div class="rounded-2xl bg-gray-900/50 py-10 text-center ring-1 ring-inset ring-white/5 lg:flex lg:flex-col lg:justify-center lg:py-28">
                <div class="mx-auto max-w-xs px-8">
                  <p class="text-xl font-semibold text-gray-300">Get started now</p>
                  <.link
                    href="https://cal.com/ioannisflo"
                    class="mt-6 block w-full rounded-md bg-indigo-600 px-3 py-2 text-center text-lg font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
                  >
                    Launch campaign
                  </.link>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="py-12">
        <div class="mx-auto max-w-7xl px-4">
          <div class="mx-auto max-w-2xl sm:max-w-5xl">
            <h2 class="text-3xl font-bold tracking-tight text-white sm:text-4xl text-center">
              Get your product in front of millions
            </h2>
            <p class="mt-2 text-lg leading-8 text-gray-300 text-center">
              Reach a highly engaged, tech-focused audience across multiple platforms
            </p>
            <div class="mt-16 space-y-20 lg:mt-20 lg:space-y-20">
              <article class="relative isolate flex flex-col gap-8 lg:flex-row">
                <div class="relative aspect-video lg:w-[30rem] lg:shrink-0">
                  <img
                    src={~p"/images/in-video-ad.png"}
                    alt=""
                    class="absolute inset-0 h-full w-full rounded-sm bg-gray-900 object-cover"
                  />
                  <div class="absolute inset-0 rounded-2xl ring-1 ring-inset ring-gray-50/10"></div>
                </div>
                <div>
                  <div class="relative max-w-md">
                    <h3 class="mt-3 text-2xl font-semibold leading-6 text-white">
                      <span class="absolute inset-0"></span> In-video ads
                    </h3>
                    <p class="mt-5 text-lg leading-6 text-gray-200">
                      Get your message across during live streams. Simple, effective, and memorable.
                    </p>
                  </div>
                </div>
              </article>
              <article class="relative isolate flex flex-col gap-8 lg:flex-row">
                <div class="relative aspect-video lg:w-[30rem] lg:shrink-0">
                  <img
                    src="https://fly.storage.tigris.dev/algora/blurbs/4c519741-476c-4b74-ad50-fa72c2bddb1b.png"
                    alt=""
                    class="absolute inset-0 h-full w-full rounded-sm bg-gray-900 object-cover"
                  />
                  <div class="absolute inset-0 rounded-2xl ring-1 ring-inset ring-gray-50/10"></div>
                </div>
                <div>
                  <div class="relative max-w-md">
                    <h3 class="mt-3 text-2xl font-semibold leading-6 text-white">
                      <span class="absolute inset-0"></span> Live reactions
                    </h3>
                    <p class="mt-5 text-lg leading-6 text-gray-200">
                      Watch tech streamers try your product live. Real reactions, real engagement.
                    </p>
                  </div>
                </div>
              </article>
              <article class="relative isolate flex flex-col gap-8 lg:flex-row">
                <div class="relative aspect-video lg:w-[30rem] lg:shrink-0">
                  <img
                    src={~p"/images/sponsored-stream.png"}
                    alt=""
                    class="absolute inset-0 h-full w-full rounded-sm bg-gray-900 object-cover"
                  />
                  <div class="absolute inset-0 rounded-2xl ring-1 ring-inset ring-gray-50/10"></div>
                </div>
                <div>
                  <div class="relative max-w-md">
                    <h3 class="mt-3 text-2xl font-semibold leading-6 text-white">
                      <span class="absolute inset-0"></span> Sponsored streams
                    </h3>
                    <p class="mt-5 text-lg leading-6 text-gray-200">
                      Full-length streams showcasing and building with your product. Reach millions across Twitch, YouTube, and X.
                    </p>
                  </div>
                </div>
              </article>
            </div>
          </div>
        </div>
      </div>

      <section class="isolate overflow-hidden px-4">
        <div class="relative mx-auto max-w-2xl py-12 lg:max-w-5xl">
          <figure class="grid grid-cols-1 items-center gap-x-6 gap-y-4 lg:gap-x-8">
            <div class="relative col-span-2 lg:col-start-1 lg:row-start-2">
              <svg
                viewBox="0 0 162 128"
                fill="none"
                aria-hidden="true"
                class="absolute -top-12 left-0 -z-10 h-32 stroke-gray-100/10"
              >
                <path
                  id="b56e9dab-6ccb-4d32-ad02-6b4bb5d9bbeb"
                  d="M65.5697 118.507L65.8918 118.89C68.9503 116.314 71.367 113.253 73.1386 109.71C74.9162 106.155 75.8027 102.28 75.8027 98.0919C75.8027 94.237 75.16 90.6155 73.8708 87.2314C72.5851 83.8565 70.8137 80.9533 68.553 78.5292C66.4529 76.1079 63.9476 74.2482 61.0407 72.9536C58.2795 71.4949 55.276 70.767 52.0386 70.767C48.9935 70.767 46.4686 71.1668 44.4872 71.9924L44.4799 71.9955L44.4726 71.9988C42.7101 72.7999 41.1035 73.6831 39.6544 74.6492C38.2407 75.5916 36.8279 76.455 35.4159 77.2394L35.4047 77.2457L35.3938 77.2525C34.2318 77.9787 32.6713 78.3634 30.6736 78.3634C29.0405 78.3634 27.5131 77.2868 26.1274 74.8257C24.7483 72.2185 24.0519 69.2166 24.0519 65.8071C24.0519 60.0311 25.3782 54.4081 28.0373 48.9335C30.703 43.4454 34.3114 38.345 38.8667 33.6325C43.5812 28.761 49.0045 24.5159 55.1389 20.8979C60.1667 18.0071 65.4966 15.6179 71.1291 13.7305C73.8626 12.8145 75.8027 10.2968 75.8027 7.38572C75.8027 3.6497 72.6341 0.62247 68.8814 1.1527C61.1635 2.2432 53.7398 4.41426 46.6119 7.66522C37.5369 11.6459 29.5729 17.0612 22.7236 23.9105C16.0322 30.6019 10.618 38.4859 6.47981 47.558L6.47976 47.558L6.47682 47.5647C2.4901 56.6544 0.5 66.6148 0.5 77.4391C0.5 84.2996 1.61702 90.7679 3.85425 96.8404L3.8558 96.8445C6.08991 102.749 9.12394 108.02 12.959 112.654L12.959 112.654L12.9646 112.661C16.8027 117.138 21.2829 120.739 26.4034 123.459L26.4033 123.459L26.4144 123.465C31.5505 126.033 37.0873 127.316 43.0178 127.316C47.5035 127.316 51.6783 126.595 55.5376 125.148L55.5376 125.148L55.5477 125.144C59.5516 123.542 63.0052 121.456 65.9019 118.881L65.5697 118.507Z"
                />
                <use href="#b56e9dab-6ccb-4d32-ad02-6b4bb5d9bbeb" x="86" />
              </svg>
              <blockquote class="text-xl font-semibold leading-8 text-white sm:text-3xl sm:leading-9">
                <p>
                  Every time Tigris partnered with Algora for live media & distribution we saw more developers try Tigris and experienced increased inbound from prospective customers.
                </p>
              </blockquote>
            </div>
            <div class="col-end-1 w-16 lg:row-span-4 lg:w-56">
              <img
                class="rounded-xl lg:rounded-3xl w-full h-full"
                src="https://avatars.githubusercontent.com/u/1632658?v=4"
                alt=""
              />
            </div>
            <figcaption class="text-lg sm:text-2xl lg:col-start-1 lg:row-start-3">
              <div class="flex items-center gap-2">
                <div class="font-semibold text-white">Ovais Tariq</div>
                <div class="text-gray-300">/</div>
                <div class="text-[#7ceec0]">Co-Founder & CEO at Tigris Data</div>
              </div>
              <.link
                target="_blank"
                rel="noopener"
                class="mt-2 flex h-full flex-1 text-white no-underline hover:no-underline"
                href="https://tigrisdata.com"
              >
                <img
                  src="https://assets-global.website-files.com/657988158c7fb30f4d9ef37b/657990b61fd3a5d674cf2298_tigris-logo.svg"
                  alt="Tigris"
                  class="h-8 w-auto"
                />
              </.link>
            </figcaption>
          </figure>
        </div>
      </section>

      <footer aria-labelledby="footer-heading" class="relative">
        <h2 id="footer-heading" class="sr-only">Footer</h2>
        <div class="mx-auto max-w-7xl px-6 pb-12 pt-4 lg:px-8">
          <div class="border-t border-white/10 pt-12 md:flex md:items-center md:justify-between">
            <div class="flex space-x-6 md:order-2">
              <a href="https://twitter.com/algoraio" class="text-gray-500 hover:text-gray-400">
                <span class="sr-only">X</span>
                <svg class="h-6 w-6" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                  <path d="M13.6823 10.6218L20.2391 3H18.6854L12.9921 9.61788L8.44486 3H3.2002L10.0765 13.0074L3.2002 21H4.75404L10.7663 14.0113L15.5685 21H20.8131L13.6819 10.6218H13.6823ZM11.5541 13.0956L10.8574 12.0991L5.31391 4.16971H7.70053L12.1742 10.5689L12.8709 11.5655L18.6861 19.8835H16.2995L11.5541 13.096V13.0956Z" />
                </svg>
              </a>
              <a href="https://github.com/algora-io/tv" class="text-gray-500 hover:text-gray-400">
                <span class="sr-only">GitHub</span>
                <svg class="h-6 w-6" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                  <path
                    fill-rule="evenodd"
                    d="M12 2C6.477 2 2 6.484 2 12.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.531 1.032 1.531 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0112 6.844c.85.004 1.705.115 2.504.337 1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.202 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.943.359.309.678.92.678 1.855 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688.482A10.019 10.019 0 0022 12.017C22 6.484 17.522 2 12 2z"
                    clip-rule="evenodd"
                  />
                </svg>
              </a>
              <a href="https://www.youtube.com/@algora-io" class="text-gray-500 hover:text-gray-400">
                <span class="sr-only">YouTube</span>
                <svg class="h-6 w-6" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                  <path
                    fill-rule="evenodd"
                    d="M19.812 5.418c.861.23 1.538.907 1.768 1.768C21.998 8.746 22 12 22 12s0 3.255-.418 4.814a2.504 2.504 0 0 1-1.768 1.768c-1.56.419-7.814.419-7.814.419s-6.255 0-7.814-.419a2.505 2.505 0 0 1-1.768-1.768C2 15.255 2 12 2 12s0-3.255.417-4.814a2.507 2.507 0 0 1 1.768-1.768C5.744 5 11.998 5 11.998 5s6.255 0 7.814.418ZM15.194 12 10 15V9l5.194 3Z"
                    clip-rule="evenodd"
                  />
                </svg>
              </a>
            </div>
            <div class="mt-8 md:mt-0 md:order-1">
              <.logo />
              <p class="mt-2 text-lg leading-5 text-gray-200 tracking-tight">
                We work with elite tech startups to provide elite advertising.
              </p>
            </div>
          </div>
        </div>
      </footer>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:form, to_form(Contact.change_info(%Info{})))}
  end

  def handle_event("save", %{"info" => info_params}, socket) do
    case Contact.create_info(info_params) do
      {:ok, _info} ->
        {:noreply,
         socket
         |> put_flash(:info, "Thank you for your interest. We'll be in touch soon!")
         |> assign(:form, to_form(Contact.change_info(%Info{})))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  def handle_params(params, _url, socket) do
    LayoutComponent.hide_modal()
    {:noreply, socket |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :show, _params) do
    socket
    |> assign(:page_title, "Partner")
    |> assign(
      :page_description,
      "In-video livestream ads that help you stand out in front of millions on Twitch, YouTube and X."
    )
    |> assign(:page_image, "#{AlgoraWeb.Endpoint.url()}/images/og/partner.png")
  end
end

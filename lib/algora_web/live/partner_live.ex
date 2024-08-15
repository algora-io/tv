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
            <div class="mx-auto max-w-2xl xl:max-w-3xl aspect-[1456/756] w-full h-full flex-shrink-0 mt-12 flex lg:mt-6 xl:mt-0">
              <img
                src={~p"/images/partner-demo.png"}
                alt="Demo"
                class="w-full h-full shrink-0 rounded-xl shadow-2xl ring-1 ring-white/10"
              />
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
        <!-- Contact form -->
        <div class="isolate px-6 pt-24 sm:pt-32 pb-12 lg:px-8">
          <div
            id="contact-form"
            class="mx-auto relative px-12 py-12 ring-1 ring-purple-400 max-w-4xl rounded-xl shadow-lg overflow-hidden bg-white/5"
          >
            <div
              class="absolute inset-x-0 -z-10 transform overflow-hidden blur-3xl"
              aria-hidden="true"
            >
              <div
                class="relative -z-10 aspect-[1155/678] w-[36.125rem] max-w-none rotate-[30deg] bg-gradient-to-tr from-[#80caff] to-[#4f46e5] opacity-10 sm:w-[72.1875rem]"
                style="clip-path: polygon(74.1% 44.1%, 100% 61.6%, 97.5% 26.9%, 85.5% 0.1%, 80.7% 2%, 72.5% 32.5%, 60.2% 62.4%, 52.4% 68.1%, 47.5% 58.3%, 45.2% 34.5%, 27.5% 76.7%, 0.1% 64.9%, 17.9% 100%, 27.6% 76.8%, 76.1% 97.7%, 74.1% 44.1%)"
              >
              </div>
            </div>
            <div class="text-center">
              <h2 class="text-4xl font-bold tracking-tight text-white sm:text-5xl">Work With Us</h2>
              <div class="w-96 h-0.5 mx-auto my-4 bg-gradient-to-r from-[#120f22] via-purple-400 to-[#120f22]">
              </div>
              <p class="mt-2 text-xl sm:text-2xl tracking-tight leading-8 text-gray-300">
                We only partner with 1-2 new clients per month. Your application reaches our CEO's inbox faster than the speed of light.
              </p>
            </div>
            <.form for={@form} phx-submit="save" action="#" class="pt-8">
              <div class="grid grid-cols-1 gap-x-8 gap-y-6 sm:grid-cols-2">
                <div class="sm:col-span-2">
                  <.input field={@form[:email]} type="email" label="What is your email address?" />
                </div>
                <div class="sm:col-span-2">
                  <.input field={@form[:website_url]} type="text" label="What is your website?" />
                </div>
                <div class="sm:col-span-2">
                  <.input field={@form[:revenue]} type="text" label="What is your revenue?" />
                </div>
                <div class="sm:col-span-2">
                  <.input
                    field={@form[:company_location]}
                    type="text"
                    label="Where is your company based?"
                  />
                </div>
              </div>
              <div class="mt-10">
                <.button
                  phx-disable-with="Sending..."
                  class=" w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-purple-600 hover:bg-purple-600 active:text-white focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-400"
                >
                  Let's talk
                </.button>
              </div>
            </.form>
          </div>
        </div>
      </main>
      <!-- Footer -->
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

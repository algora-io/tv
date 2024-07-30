defmodule AlgoraWeb.PartnerLive do
  use AlgoraWeb, :live_view
  require Logger

  alias AlgoraWeb.LayoutComponent

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
            <div class="mx-auto max-w-2xl flex-shrink-0 lg:mx-0 lg:max-w-lg lg:pt-8">
              <.logo />

              <h1 class="mt-10 text-4xl font-bold tracking-tight text-white sm:text-5xl">
                Your most successful <br /><span class="text-green-300">ad campaign</span>
                is just <br />a few livestreams away
              </h1>
              <p class="mt-6 text-lg leading-8 text-gray-300">
                In-video livestream ads that help you stand out<br />
                in front of millions on Twitch, YouTube and X.
              </p>
              <div class="mt-10 flex items-center gap-x-6">
                <a
                  href="#contact-form"
                  class="rounded-md bg-indigo-500 px-3.5 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-indigo-400 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-400"
                >
                  Get started
                </a>
              </div>
            </div>
            <div class="mx-auto mt-16 flex sm:mt-24 lg:mt-0 w-full aspect-[1456/756]">
              <img
                src={~p"/images/ads.png"}
                alt="Ads Demo"
                width="1456"
                height="756"
                class="w-full rounded-xl shadow-2xl ring-1 ring-white/10"
              />
            </div>
          </div>
        </div>
        <!-- Feature section -->
        <div class="mt-16 sm:mt-28">
          <div class="mx-auto max-w-7xl px-6 lg:px-8">
            <div class="mx-auto max-w-2xl sm:text-center">
              <h2 class="mt-2 text-3xl font-bold tracking-tight text-white sm:text-4xl">
                Influencer Marketing on Autopilot
              </h2>
              <p class="mt-6 text-lg leading-8 text-gray-300">
                Distribute your ad creatives to the most engaged tech audience in-video
              </p>
              <p class="text-lg leading-8 text-gray-300">
                Measure success with our comprehensive analytics
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
                    class="absolute left-1 top-1 h-5 w-5 text-indigo-500"
                    viewBox="0 0 20 20"
                    fill="currentColor"
                    aria-hidden="true"
                  >
                    <path
                      fill-rule="evenodd"
                      d="M5.5 17a4.5 4.5 0 01-1.44-8.765 4.5 4.5 0 018.302-3.046 3.5 3.5 0 014.504 4.272A4 4 0 0115 17H5.5zm3.75-2.75a.75.75 0 001.5 0V9.66l1.95 2.1a.75.75 0 101.1-1.02l-3.25-3.5a.75.75 0 00-1.1 0l-3.25 3.5a.75.75 0 101.1 1.02l1.95-2.1v4.59z"
                      clip-rule="evenodd"
                    />
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
                    class="absolute left-1 top-1 h-5 w-5 text-indigo-500"
                    viewBox="0 0 20 20"
                    fill="currentColor"
                    aria-hidden="true"
                  >
                    <path
                      fill-rule="evenodd"
                      d="M10 1a4.5 4.5 0 00-4.5 4.5V9H5a2 2 0 00-2 2v6a2 2 0 002 2h10a2 2 0 002-2v-6a2 2 0 00-2-2h-.5V5.5A4.5 4.5 0 0010 1zm3 8V5.5a3 3 0 10-6 0V9h6z"
                      clip-rule="evenodd"
                    />
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
                    class="absolute left-1 top-1 h-5 w-5 text-indigo-500"
                    viewBox="0 0 20 20"
                    fill="currentColor"
                    aria-hidden="true"
                  >
                    <path
                      fill-rule="evenodd"
                      d="M15.312 11.424a5.5 5.5 0 01-9.201 2.466l-.312-.311h2.433a.75.75 0 000-1.5H3.989a.75.75 0 00-.75.75v4.242a.75.75 0 001.5 0v-2.43l.31.31a7 7 0 0011.712-3.138.75.75 0 00-1.449-.39zm1.23-3.723a.75.75 0 00.219-.53V2.929a.75.75 0 00-1.5 0V5.36l-.31-.31A7 7 0 003.239 8.188a.75.75 0 101.448.389A5.5 5.5 0 0113.89 6.11l.311.31h-2.432a.75.75 0 000 1.5h4.243a.75.75 0 00.53-.219z"
                      clip-rule="evenodd"
                    />
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
                    class="absolute left-1 top-1 h-5 w-5 text-indigo-500"
                    viewBox="0 0 20 20"
                    fill="currentColor"
                    aria-hidden="true"
                  >
                    <path
                      fill-rule="evenodd"
                      d="M10 2.5c-1.31 0-2.526.386-3.546 1.051a.75.75 0 01-.82-1.256A8 8 0 0118 9a22.47 22.47 0 01-1.228 7.351.75.75 0 11-1.417-.49A20.97 20.97 0 0016.5 9 6.5 6.5 0 0010 2.5zM4.333 4.416a.75.75 0 01.218 1.038A6.466 6.466 0 003.5 9a7.966 7.966 0 01-1.293 4.362.75.75 0 01-1.257-.819A6.466 6.466 0 002 9c0-1.61.476-3.11 1.295-4.365a.75.75 0 011.038-.219zM10 6.12a3 3 0 00-3.001 3.041 11.455 11.455 0 01-2.697 7.24.75.75 0 01-1.148-.965A9.957 9.957 0 005.5 9c0-.028.002-.055.004-.082a4.5 4.5 0 018.996.084V9.15l-.005.297a.75.75 0 11-1.5-.034c.003-.11.004-.219.005-.328a3 3 0 00-3-2.965zm0 2.13a.75.75 0 01.75.75c0 3.51-1.187 6.745-3.181 9.323a.75.75 0 11-1.186-.918A13.687 13.687 0 009.25 9a.75.75 0 01.75-.75zm3.529 3.698a.75.75 0 01.584.885 18.883 18.883 0 01-2.257 5.84.75.75 0 11-1.29-.764 17.386 17.386 0 002.078-5.377.75.75 0 01.885-.584z"
                      clip-rule="evenodd"
                    />
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
                    class="absolute left-1 top-1 h-5 w-5 text-indigo-500"
                    viewBox="0 0 20 20"
                    fill="currentColor"
                    aria-hidden="true"
                  >
                    <path
                      fill-rule="evenodd"
                      d="M7.84 1.804A1 1 0 018.82 1h2.36a1 1 0 01.98.804l.331 1.652a6.993 6.993 0 011.929 1.115l1.598-.54a1 1 0 011.186.447l1.18 2.044a1 1 0 01-.205 1.251l-1.267 1.113a7.047 7.047 0 010 2.228l1.267 1.113a1 1 0 01.206 1.25l-1.18 2.045a1 1 0 01-1.187.447l-1.598-.54a6.993 6.993 0 01-1.929 1.115l-.33 1.652a1 1 0 01-.98.804H8.82a1 1 0 01-.98-.804l-.331-1.652a6.993 6.993 0 01-1.929-1.115l-1.598.54a1 1 0 01-1.186-.447l-1.18-2.044a1 1 0 01.205-1.251l1.267-1.114a7.05 7.05 0 010-2.227L1.821 7.773a1 1 0 01-.206-1.25l1.18-2.045a1 1 0 011.187-.447l1.598.54A6.993 6.993 0 017.51 3.456l.33-1.652zM10 13a3 3 0 100-6 3 3 0 000 6z"
                      clip-rule="evenodd"
                    />
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
                    class="absolute left-1 top-1 h-5 w-5 text-indigo-500"
                    viewBox="0 0 20 20"
                    fill="currentColor"
                    aria-hidden="true"
                  >
                    <path
                      d="M4.632 3.533A2 2 0 016.577 2h6.846a2 2 0 011.945 1.533l.331 1.652a6.993 6.993 0 011.929 1.115l1.598-.54a1 1 0 011.186.447l1.18 2.044a1 1 0 01-.205 1.251l-1.267 1.113a7.047 7.047 0 010 2.228l1.267 1.113a1 1 0 01.206 1.25l-1.18 2.045a1 1 0 01-1.187.447l-1.598-.54a6.993 6.993 0 01-1.929 1.115l-.33 1.652a1 1 0 01-.98.804H8.82a1 1 0 01-.98-.804l-.331-1.652a6.993 6.993 0 01-1.929-1.115l-1.598.54a1 1 0 01-1.186-.447l-1.18-2.044a1 1 0 01.205-1.251l1.267-1.114a7.05 7.05 0 010-2.227L1.821 7.773a1 1 0 01-.206-1.25l1.18-2.045a1 1 0 011.187-.447l1.598.54A6.993 6.993 0 017.51 3.456l.33-1.652zM10 13a3 3 0 100-6 3 3 0 000 6z"
                      clip-rule="evenodd"
                    />
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
            class="mx-auto relative px-12 py-12 ring-1 ring-purple-400 max-w-2xl rounded-xl shadow-lg overflow-hidden bg-white/5"
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
              <h2 class="text-3xl font-bold tracking-tight text-white sm:text-4xl">Work with us</h2>
              <div class="w-96 h-0.5 mx-auto my-4 bg-gradient-to-r from-[#120f22] via-purple-400 to-[#120f22]">
              </div>
              <p class="mt-2 text-lg leading-8 text-gray-300">
                We only partner with 1-2 new clients per month. Your application reaches our CEO's inbox faster than the speed of light.
              </p>
            </div>
            <.form for={@form} phx-submit="save" action="#" class="px-6 pt-8">
              <div class="grid grid-cols-1 gap-x-8 gap-y-6 sm:grid-cols-2">
                <div class="sm:col-span-2">
                  <.input field={@form[:email]} type="email" label="What is your email address?" />
                </div>
                <div class="sm:col-span-2">
                  <.input field={@form[:website]} type="url" label="What is your website?" />
                </div>
                <div class="sm:col-span-2">
                  <.input field={@form[:revenue]} type="text" label="What is your revenue?" />
                </div>
                <div class="sm:col-span-2">
                  <.input field={@form[:location]} type="text" label="Where is your company based?" />
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
              <p class="mt-2 text-lg leading-5 text-gray-200">
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
    {:ok, socket |> assign(:form, to_form(%{}, as: :partner))}
  end

  def handle_event("save", %{"partner" => partner_params}, socket) do
    case validate_and_save_partner(partner_params) do
      {:ok, _partner} ->
        {:noreply,
         socket
         |> put_flash(:info, "Thank you for your interest. We'll be in touch soon!")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp validate_and_save_partner(params) do
    changeset =
      %{}
      |> Ecto.Changeset.cast(params, [:email, :website, :revenue, :location])
      |> Ecto.Changeset.validate_required([:email, :website])

    case Ecto.Changeset.apply_action(changeset, :insert) do
      :ok ->
        dbg(params)
        {:ok, params}

      {:error, changes} ->
        {:error, changes}
    end
  end

  def handle_params(params, _url, socket) do
    LayoutComponent.hide_modal()
    {:noreply, socket |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :show, _params) do
    socket
    |> assign(:page_title, "Algora Ads")
    |> assign(
      :page_description,
      "In-video livestream ads that help you stand out in front of millions on Twitch, YouTube and X."
    )
  end
end

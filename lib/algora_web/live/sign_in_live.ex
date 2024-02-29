defmodule AlgoraWeb.SignInLive do
  use AlgoraWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-900 flex flex-col justify-center py-12 sm:px-6 lg:px-8">
      <div class="sm:mx-auto sm:w-full sm:max-w-sm">
        <h2 class="mt-6 text-center text-3xl font-extrabold text-gray-50">
          Algora TV
        </h2>
        <a
          href={Algora.Github.authorize_url()}
          class="mt-8 w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-purple-600 hover:bg-purple-500 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-400"
        >
          Sign in with GitHub
        </a>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end

defmodule AlgoraWeb.ApiSpec do
  @moduledoc false
  @behaviour OpenApiSpex.OpenApi

  alias OpenApiSpex.{Components, Info, License, Paths, Schema, SecurityScheme}

  # OpenAPISpex master specification

  @impl OpenApiSpex.OpenApi
  def spec() do
    %OpenApiSpex.OpenApi{
      info: %Info{
        title: "Algora TV",
        version: "0.1.0",
        license: %License{
          name: "Apache 2.0",
          url: "https://www.apache.org/licenses/LICENSE-2.0"
        }
      },
      paths: Paths.from_router(AlgoraWeb.Router),
      components: %Components{
        securitySchemes: %{"authorization" => %SecurityScheme{type: "http", scheme: "bearer"}}
      }
    }
    |> OpenApiSpex.resolve_schema_modules()
  end

  @spec data(String.t(), Schema.t()) :: {String.t(), String.t(), Schema.t()}
  def data(description, schema) do
    {description, "application/json", schema}
  end

  @spec error(String.t()) :: {String.t(), String.t(), module()}
  def error(description) do
    {description, "application/json", AlgoraWeb.ApiSpec.Error}
  end
end

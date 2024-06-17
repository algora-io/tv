defmodule AlgoraWeb.ApiSpec.HLS do
  require OpenApiSpex

  defmodule Params do
    @moduledoc false

    defmodule HlsMsn do
      @moduledoc false

      OpenApiSpex.schema(%{
        type: :integer,
        minimum: 0,
        example: 10,
        description: "Segment sequence number",
        nullable: true
      })
    end

    defmodule HlsPart do
      @moduledoc false

      OpenApiSpex.schema(%{
        type: :integer,
        minimum: 0,
        example: 10,
        description: "Partial segment sequence number",
        nullable: true
      })
    end

    defmodule HlsSkip do
      @moduledoc false

      OpenApiSpex.schema(%{
        type: :string,
        example: "YES",
        description: "Set to \"YES\" if delta manifest should be requested",
        nullable: true
      })
    end
  end

  defmodule Response do
    @moduledoc false

    OpenApiSpex.schema(%{
      title: "HlsResponse",
      description: "Requested file",
      type: :string
    })
  end
end

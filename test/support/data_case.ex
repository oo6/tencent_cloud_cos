defmodule COS.DataCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  using do
    quote do
      import Tesla.Mock

      def xml(body, opts \\ []) do
        response = text(body, opts)

        headers = [
          {"content-type", "application/xml"}
          | Enum.reject(response.headers, &(elem(&1, 1) == "content-type"))
        ]

        %{response | headers: headers}
      end
    end
  end
end

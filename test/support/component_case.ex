defmodule ComponentCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Phoenix.LiveViewTest
      import Phoenix.LiveView.Helpers
      import Phoenix.Component
    end
  end
end

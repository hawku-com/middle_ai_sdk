defmodule MiddleAi.MixProject do
  use Mix.Project

  def project do
    [
      app: :middle_ai,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      applications: [
        opentelemetry_exporter: :permanent,
        opentelemetry: :temporary,
        middle_ai: :permanent
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {MiddleAi.Application, []},
      extra_applications: [:logger, :tls_certificate_check]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:opentelemetry, "~> 1.3"},
      {:opentelemetry_api, "~> 1.2"},
      {:opentelemetry_exporter, "~> 1.6"}
    ]
  end
end

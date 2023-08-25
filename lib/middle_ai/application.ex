defmodule MiddleAi.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    setup_opentelemetry()

    opts = [strategy: :one_for_one, name: MiddleAi.Supervisor]
    Supervisor.start_link([], opts)
  end

  defp setup_opentelemetry do
    endpoint = Application.get_env(:middle_ai, :endpoint, "http://localhost:4318")
    api_key = Application.get_env(:middle_ai, :api_key, "")

    resource = :otel_resource.create([{"provider", "middle_ai"}])

    :otel_tracer_provider_sup.start(
      :middle_ai_provider,
      resource,
      %{
        id_generator: :otel_id_generator,
        sampler: {:otel_sampler_always_on, []},
        processors: [
          {:otel_batch_processor,
           %{
             name: :middle_ai_batch_processor,
             exporter:
               {:opentelemetry_exporter,
                %{endpoints: [endpoint], headers: [{"x-middle-ai-api-key", api_key}]}}
           }}
        ],
        deny_list: []
      }
    )
  end
end

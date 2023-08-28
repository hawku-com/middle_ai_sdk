defmodule MiddleAi do
  alias OpenTelemetry.Span

  @spec start_trace(String.t(), String.t(), map(), String.t(), String.t()) ::
          OpenTelemetry.span_ctx()
  def start_trace(name, model, model_params, user, prompt) do
    model_params = parse_model_params(model_params)
    attributes = Map.merge(%{"model" => model, "user" => user, "prompt" => prompt}, model_params)

    :middle_ai_provider
    |> :otel_tracer_provider.get_tracer(:middle_ai, "", "")
    |> :otel_tracer.start_span(
      name,
      %{attributes: attributes}
    )
  end

  @spec end_trace(OpenTelemetry.span_ctx(), nil | String.t()) :: OpenTelemetry.span_ctx()
  def end_trace(trace, output \\ nil)

  def end_trace(trace, nil) do
    Span.end_span(trace)
  end

  def end_trace(trace, output) do
    Span.set_attribute(trace, :output, output)
    Span.end_span(trace)
  end

  defp parse_model_params(model_params) do
    Enum.into(model_params, %{}, fn {key, value} ->
      {"model_param:#{key}", value}
    end)
  end
end

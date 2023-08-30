defmodule MiddleAi do
  alias OpenTelemetry.Span

  @spec start_trace(String.t(), String.t(), map(), String.t(), String.t()) ::
          OpenTelemetry.span_ctx()
  def start_trace(name, model, model_params, user, prompt) do
    model_params = parse_model_params(model_params)

    attributes =
      Map.merge(
        %{"llm_model" => model, "enduser_id" => user, "user_prompt" => prompt},
        model_params
      )

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
    Span.set_attribute(trace, "llm_output", output)
    Span.end_span(trace)
  end

  defp parse_model_params(model_params) do
    Enum.reduce(model_params, %{}, fn {key, value}, acc ->
      key
      |> extract_keys_leaf_value(value)
      |> Enum.into(acc, fn {keys, value} ->
        {"model_param." <> keys, value}
      end)
    end)
  end

  defp extract_keys_leaf_value(key, value) when is_map(value) do
    Enum.map(value, fn {k, v} ->
      k
      |> extract_keys_leaf_value(v)
      |> Enum.map(fn {keys, value} ->
        {"#{key}.#{keys}", value}
      end)
    end)
    |> List.flatten()
  end

  defp extract_keys_leaf_value(key, value) do
    [{key, value}]
  end
end

defmodule MiddleAi.Tracer do
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      alias OpenTelemetry.Span

      @type feedback_type() :: :emoji | :thumbs | :scale

      @tracer_ref Keyword.fetch!(opts, :tracer_ref)

      @spec start_trace(String.t(), String.t(), map(), String.t(), String.t(), String.t()) ::
              OpenTelemetry.span_ctx()
      def start_trace(name, model, model_params, user, prompt, thread_id \\ "") do
        model_params = parse_model_params(model_params)

        attributes =
          Map.merge(
            %{
              "llm_model" => model,
              "enduser_id" => user,
              "user_prompt" => prompt,
              "thread_id" => thread_id,
              "application_ref" => @tracer_ref
            },
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

      @spec send_feedback(String.t(), String.t(), feedback_type(), String.t()) ::
              {:ok, any()} | {:error, any()}
      def send_feedback(thread_id, user, type, feedback) do
        endpoint = Application.get_env(:middle_ai, :endpoint, "http://localhost:4001")
        api_key = Application.get_env(:middle_ai, :api_key, "")

        url = to_charlist(endpoint <> "/v1/traces/feedback")
        headers = [{~c"x-middle-ai-api-key", to_charlist(api_key)}]
        content_type = ~c"application/json"

        body =
          %{
            thread_id: thread_id,
            application_ref: @tracer_ref,
            enduser_id: cast_to_string(user),
            feedback_type: type,
            feedback_value: feedback
          }
          |> Jason.encode!()
          |> to_charlist()

        :httpc.request(:post, {url, headers, content_type, body}, [], [])
      end

      defp parse_model_params(model_params) do
        Enum.reduce(model_params, %{}, fn {key, value}, acc ->
          key
          |> extract_keys_leaf_value(value)
          |> Enum.into(acc, fn {keys, value} ->
            {"model_param.#{keys}", value}
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

      defp cast_to_string(value) when is_binary(value), do: value
      defp cast_to_string(value), do: to_string(value)
    end
  end
end

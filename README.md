# Middle AI SDK

This is the Elixir SDK for Middle AI.
It provides functions to track your users LLM usage.

## Configuration

Set your API key in your application configuration:

```elixir
config :middle_ai, api_key: <YOUR_API_KEY>
```

## Usage

Wrap your LLM calls the following way

```elixir
trace = MiddleAi.start_trace("trace_name", model, %{max_tokens: max_tokens, temperature: temperature}, user_id, prompt)

{:ok, output} = OpenAI.completions(
    model: model,
    prompt: prompt,
    max_tokens: max_tokens,
    temperature: temperature,
    ...
  )

MiddleAi.end_trance(trace, output)
```

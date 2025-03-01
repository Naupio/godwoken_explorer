defmodule GodwokenExplorer.Counters.AddressTokenTransfersCounter do
  @moduledoc """
  Caches Address token transfers counter.
  """
  use GenServer

  alias Ecto.Changeset
  alias GodwokenExplorer.{Chain, Repo}

  @cache_name :address_token_transfers_counter
  @last_update_key "last_update"

  @ets_opts [
    :set,
    :named_table,
    :public,
    read_concurrency: true
  ]

  @enable_consolidation false

  @spec start_link(term()) :: GenServer.on_start()
  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    create_cache_table()

    {:ok, %{consolidate?: enable_consolidation?()}, {:continue, :ok}}
  end

  @impl true
  def handle_continue(:ok, %{consolidate?: true} = state) do
    {:noreply, state}
  end

  @impl true
  def handle_continue(:ok, state) do
    {:noreply, state}
  end

  @impl true
  def handle_info(:consolidate, state) do
    {:noreply, state}
  end

  def fetch(address) do
    if cache_expired?(address) do
      update_cache(address)
    end

    address_hash_string = to_string(address.eth_address)
    fetch_from_cache("hash_#{address_hash_string}")
  end

  def cache_name, do: @cache_name

  defp cache_expired?(address) do
    cache_period = address_token_transfers_counter_cache_period()
    address_hash_string = to_string(address.eth_address)
    updated_at = fetch_from_cache("hash_#{address_hash_string}_#{@last_update_key}")

    cond do
      is_nil(updated_at) -> true
      current_time() - updated_at > cache_period -> true
      true -> false
    end
  end

  defp update_cache(address) do
    address_hash_string = to_string(address.eth_address)
    put_into_cache("hash_#{address_hash_string}_#{@last_update_key}", current_time())
    new_data = Chain.address_to_token_transfer_count(address.eth_address)
    put_into_cache("hash_#{address_hash_string}", new_data)
    put_into_db(address, new_data)
  end

  defp fetch_from_cache(key) do
    case :ets.lookup(@cache_name, key) do
      [{_, value}] ->
        value

      [] ->
        0
    end
  end

  defp put_into_cache(key, value) do
    :ets.insert(@cache_name, {key, value})
  end

  defp current_time do
    utc_now = DateTime.utc_now()

    DateTime.to_unix(utc_now, :millisecond)
  end

  def create_cache_table do
    if :ets.whereis(@cache_name) == :undefined do
      :ets.new(@cache_name, @ets_opts)
    end
  end

  def enable_consolidation?, do: @enable_consolidation

  defp address_token_transfers_counter_cache_period do
    :timer.hours(1)
  end

  defp put_into_db(address, value) do
    address
    |> Changeset.change(%{token_transfer_count: value})
    |> Repo.update()
  end
end

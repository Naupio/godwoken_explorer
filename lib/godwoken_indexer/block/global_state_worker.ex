defmodule GodwokenIndexer.Block.GlobalStateWorker do
  use GenServer

  import Godwoken.MoleculeParser, only: [parse_global_state: 1]

  alias GodwokenRPC.CKBIndexer.FetchedCells
  alias GodwokenExplorer.{Block, Account}
  alias GodwokenRPC.HTTP

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state)
  end

  @impl true
  def init(state) do
    # Schedule work to be performed on start
    schedule_work()

    {:ok, state}
  end

  @impl true
  def handle_info(:finalized_work, state) do
    # Do the desired work here
    fetch_and_update()

    # Reschedule once more
    schedule_work()

    {:noreply, state}
  end

  defp fetch_and_update do
    with {:ok, latest_finalized_block_number, global_state} <- fetch_global_state_info() do
      Block.update_blocks_finalized(latest_finalized_block_number)
      Account.update_meta_contract(global_state)
    end
  end

  defp fetch_global_state_info do
    options = Application.get_env(:godwoken_explorer, :ckb_indexer_named_arguments)
    state_validator_lock = Application.get_env(:godwoken_explorer, :state_validator_lock)

    with {:ok, response} <-
           FetchedCells.request(state_validator_lock, "lock") |> HTTP.json_rpc(options),
         %{"output_data" => "0x" <> global_state} <- response["objects"] |> List.first() do
      {
        :ok,
        latest_finalized_block_number,
        reverted_block_root,
        {l2_block_count, block_merkle_root},
        {account_count, account_merkle_root},
        status
      } = global_state |> parse_global_state()

      parsed_status =
        if status == "00" do
          "running"
        else
          "halting"
        end

      {
        :ok,
        latest_finalized_block_number,
        %{
          account_merkle_state: %{
            account_merkle_root: "0x" <> account_merkle_root,
            account_count: account_count
          },
          block_merkle_state: %{
            block_merkle_root: "0x" <> block_merkle_root,
            block_count: l2_block_count
          },
          reverted_block_root: reverted_block_root,
          last_finalized_block_number: latest_finalized_block_number,
          status: parsed_status
        }
      }
    end
  end

  defp schedule_work do
    Process.send_after(self(), :finalized_work, 30 * 1000)
  end
end

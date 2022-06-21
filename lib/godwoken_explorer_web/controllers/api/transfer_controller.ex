defmodule GodwokenExplorerWeb.API.TransferController do
  use GodwokenExplorerWeb, :controller

  alias GodwokenExplorer.{Account, Chain, Repo, TokenTransfer}

  action_fallback(GodwokenExplorerWeb.API.FallbackController)

  def index(conn, %{"eth_address" => "0x" <> _, "udt_address" => "0x" <> _} = params) do
    with %Account{eth_address: eth_address} <-
           Account |> Repo.get_by(eth_address: String.downcase(params["eth_address"])),
         %Account{eth_address: udt_address} <-
           Repo.get_by(Account, eth_address: String.downcase(params["udt_address"])) do
      results =
        TokenTransfer.list(
          %{eth_address: eth_address, udt_address: udt_address},
          %{
            page: conn.params["page"] || 1,
            page_size: conn.assigns.page_size
          }
        )

      json(conn, results)
    else
      _ ->
        {:error, :not_found}
    end
  end

  def index(conn, %{"eth_address" => "0x" <> _} = params) do
    with {:ok, address_hash} <-
           Chain.string_to_address_hash(params["eth_address"]),
         %Account{eth_address: eth_address} <-
           Repo.get_by(Account, eth_address: address_hash) do
      results =
        TokenTransfer.list(%{eth_address: eth_address}, %{
          page: conn.params["page"] || 1,
          page_size: conn.assigns.page_size
        })

      json(conn, results)
    else
      nil ->
        results =
          TokenTransfer.list(%{eth_address: String.downcase(params["eth_address"])}, %{
            page: conn.params["page"] || 1,
            page_size: conn.assigns.page_size
          })

        json(conn, results)
    end
  end

  def index(conn, %{"udt_address" => "0x" <> _} = params) do
    case Repo.get_by(Account, eth_address: String.downcase(params["udt_address"])) do
      %Account{eth_address: udt_address} ->
        results =
          TokenTransfer.list(%{udt_address: udt_address}, %{
            page: conn.params["page"] || 1,
            page_size: conn.assigns.page_size
          })

        json(conn, results)

      nil ->
        {:error, :not_found}
    end
  end

  def index(conn, %{"tx_hash" => "0x" <> _} = params) do
    results =
      TokenTransfer.list(%{tx_hash: params["tx_hash"]}, %{
        page: conn.params["page"] || 1,
        page_size: conn.assigns.page_size
      })

    json(conn, results)
  end

  def index(_conn, _) do
    {:error, :not_found}
  end
end

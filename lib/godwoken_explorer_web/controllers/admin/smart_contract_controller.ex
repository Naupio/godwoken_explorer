defmodule GodwokenExplorerWeb.Admin.SmartContractController do
  use GodwokenExplorerWeb, :controller

  alias GodwokenExplorer.Admin.SmartContract, as: Admin
  alias GodwokenExplorer.{Account, Chain, Repo, SmartContract}

  plug(:put_root_layout, {GodwokenExplorerWeb.LayoutView, "torch.html"})
  plug(:put_layout, false)

  def index(conn, params) do
    case Admin.paginate_smart_contracts(params) do
      {:ok, assigns} ->
        render(conn, "index.html", assigns)

      error ->
        conn
        |> put_flash(:error, "There was an error rendering Smart contracts. #{inspect(error)}")
        |> redirect(to: Routes.admin_smart_contract_path(conn, :index))
    end
  end

  def new(conn, _params) do
    changeset = Admin.change_smart_contract(%SmartContract{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"smart_contract" => smart_contract_params}) do
    with {:ok, address_hash} <-
           Chain.string_to_address_hash(smart_contract_params["eth_address"]),
         %Account{id: id, type: :polyjuice_contract} <-
           Repo.get_by(Account, eth_address: address_hash) do
      if smart_contract_params["abi"] != "" do
        case Admin.create_smart_contract(
               smart_contract_params
               |> Map.merge(%{
                 "account_id" => id,
                 "abi" => Jason.decode!(smart_contract_params["abi"])
               })
             ) do
          {:ok, smart_contract} ->
            conn
            |> put_flash(:info, "Smart contract created successfully.")
            |> redirect(to: Routes.admin_smart_contract_path(conn, :show, smart_contract))

          {:error, %Ecto.Changeset{} = changeset} ->
            render(conn, "new.html", changeset: changeset)
        end
      else
        Admin.verify_smart_contract(
          smart_contract_params
          |> Map.merge(%{
            "address_hash" => to_string(address_hash),
            "account_id" => id,
            "optimization" => false
          })
        )

        conn
        |> put_flash(:info, "Smart contract is under verified")
        |> redirect(to: Routes.admin_smart_contract_path(conn, :index))
      end
  else
      _ ->
        changeset = Admin.change_smart_contract(%SmartContract{})
        changeset = Ecto.Changeset.add_error(changeset, :eth_address, "can't find this account")
        render(conn, "new.html", changeset: %{changeset | action: :create})
    end
  end

  def show(conn, %{"id" => id}) do
    smart_contract = Admin.get_smart_contract!(id)
    render(conn, "show.html", smart_contract: smart_contract)
  end

  def edit(conn, %{"id" => id}) do
    smart_contract = Admin.get_smart_contract!(id)

    changeset =
      Admin.change_smart_contract(smart_contract)
      |> Ecto.Changeset.put_change(:eth_address, to_string(smart_contract.account.eth_address))
      |> Ecto.Changeset.put_change(
        :deployment_tx_hash,
        to_string(smart_contract.deployment_tx_hash)
      )

    render(conn, "edit.html", smart_contract: smart_contract, changeset: changeset)
  end

  def update(conn, %{"id" => id, "smart_contract" => smart_contract_params}) do
    smart_contract = Admin.get_smart_contract!(id)

    with {:ok, address_hash} <-
           Chain.string_to_address_hash(smart_contract_params["eth_address"]),
         %Account{id: id, type: :polyjuice_contract} <-
           Repo.get_by(Account, eth_address: address_hash) do
      case Admin.update_smart_contract(
             smart_contract,
             smart_contract_params
             |> Map.merge(%{
               "account_id" => id,
               "abi" => Jason.decode!(smart_contract_params["abi"])
             })
           ) do
        {:ok, smart_contract} ->
          conn
          |> put_flash(:info, "Smart contract updated successfully.")
          |> redirect(to: Routes.admin_smart_contract_path(conn, :show, smart_contract))

        {:error, %Ecto.Changeset{} = changeset} ->
          render(conn, "edit.html", smart_contract: smart_contract, changeset: changeset)
      end
    else
      _ ->
        changeset =
          Admin.change_smart_contract(smart_contract)
          |> Ecto.Changeset.put_change(:eth_address, smart_contract.account.eth_address)
          |> Ecto.Changeset.add_error(:eth_address, "can't find this account")

        render(conn, "edit.html",
          smart_contract: smart_contract,
          changeset: %{changeset | action: :update}
        )
    end
  end
end

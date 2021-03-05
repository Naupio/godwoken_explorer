defmodule GodwokenExplorer.Transaction do
  use GodwokenExplorer, :schema

  import Ecto.Changeset

  @primary_key {:hash, :binary, autogenerate: false}
  schema "transactions" do
    field :args, :binary
    field :from_account_id, :integer
    field :nonce, :integer
    field :status, Ecto.Enum, values: [:unfinalized, :finalized], default: :unfinalized
    field :to_account_id, :integer
    field :type, Ecto.Enum, values: [:sudt, :polyjuice_creator, :polyjuice, :withdrawal]
    field :block_number, :integer
    field :block_hash, :binary

    belongs_to(:block, Block, foreign_key: :block_hash, references: :hash, define_field: false)

    timestamps()
  end

  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [:hash, :block_hash, :type, :from_account_id, :to_account_id, :nonce, :args, :status, :block_number])
    |> validate_required([:hash, :from_account_id, :to_account_id, :nonce, :args, :status, :block_number])
  end

  def create_transaction(%{type: :sudt} = attrs) do
    %Transaction{}
    |> Transaction.changeset(attrs)
    |> Ecto.Changeset.put_change(:block_hash, attrs[:block_hash])
    |> Repo.insert()
    UDTTransfer.create_udt_transfer(attrs)
  end

  def create_transaction(%{type: :polyjuice_creator} = attrs) do
    %Transaction{}
    |> Transaction.changeset(attrs)
    |> Ecto.Changeset.put_change(:block_hash, attrs[:block_hash])
    |> Repo.insert()
    PolyjuiceCreator.create_polyjuice_creator(attrs)
  end

  def create_transaction(%{type: :withdrawal} = attrs) do
    %Transaction{}
    |> Transaction.changeset(attrs)
    |> Repo.insert()
    Withdrawal.create_withdrawal(attrs)
  end

  def create_transaction(%{type: :polyjuice} = attrs) do
    %Transaction{}
    |> Transaction.changeset(attrs)
    |> Repo.insert()
    Polyjuice.create_polyjuice(attrs)
  end

  def latest_10_records do
    query = from(t in Transaction, join: b in Block, on: [hash: t.block_hash],
          select: %{hash: t.hash, timestamp: b.timestamp, from: t.from_account_id, to: t.to_account_id, type: t.type},
          order_by: [desc: t.block_number, desc: t.inserted_at],
          limit: 10
          )

    Repo.all(query)
  end

  def find_by_hash(hash) do
    tx = from(t in Transaction,
              join: b in Block, on: [hash: t.block_hash],
              where: t.hash == ^hash,
              select: %{
                hash: t.hash,
                block_number: t.block_number,
                timestamp: b.timestamp,
                from: t.from_account_id,
                to: t.to_account_id,
                type: t.type,
                status: t.status,
                nonce: t.nonce,
                args: t.args
              }
          ) |> Repo.one()
    args = join_args(tx) || %{}
    tx |> Map.merge(args)
  end

  def join_args(%{type: :polyjuice, hash: tx_hash}) do
    from(p in Polyjuice,
         where: p.tx_hash == ^tx_hash,
         select: %{gas_price: p.gas_price}
    ) |> Repo.one()
  end

  def join_args(_) do %{} end
end

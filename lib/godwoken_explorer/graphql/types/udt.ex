defmodule GodwokenExplorer.Graphql.Types.UDT do
  use Absinthe.Schema.Notation
  alias GodwokenExplorer.Graphql.Resolvers, as: Resolvers
  alias GodwokenExplorer.Graphql.Middleware.TermRange, as: MTermRange

  object :udt_querys do
    @desc """
    function: get udt by contract address

    request-example:
    query {
      udt(input: {script_hash: "0x64050AF0D25C38DDF9455B8108654F7C5CC30FE6D871A303D83B1020EDDDD7A7"}){
        id
        name
        type
        supply
        account{
          eth_address
        }
      }
    }

    result-example:
    {
      "data": {
        "udt": {
          "account": {
            "eth_address": null
          },
          "id": "80",
          "name": null,
          "supply": null,
          "type": "BRIDGE"
        }
      }
    }
    """
    field :udt, :udt do
      arg(:input, non_null(:smart_contract_input))
      resolve(&Resolvers.UDT.udt/3)
    end

    @desc """
    function: get udt by contract address

    request-example:
    query {
      get_udt_by_account_id(input: {account_id: 80}){
        id
        name
        type
        supply
        account{
          eth_address
        }
      }
    }

    {
      "data": {
        "get_udt_by_account_id": {
          "account": {
            "eth_address": null
          },
          "id": "80",
          "name": "USD Coin",
          "supply": "9999999999",
          "type": "BRIDGE"
        }
      }
    }
    """
    field :get_udt_by_account_id, :udt do
      arg(:input, non_null(:account_id_input))
      resolve(&Resolvers.UDT.get_udt_by_account_id/3)
    end

    @desc """
    function: get list of udts

    request-example:
    query {
      udts(input: {page: 1, page_size: 2, sort_type: ASC}){
        id
        name
        type
        supply
        account{
          eth_address
          script_hash
        }
      }
    }

    result-example:
    {
      "data": {
        "udts": [
          {
            "account": {
              "eth_address": null,
              "script_hash": "0xbf1f27daea43849b67f839fd101569daaa321e2c"
            },
            "id": "1",
            "name": "Nervos Token",
            "supply": "693247799.35570027",
            "type": "BRIDGE"
          },
          {
            "account": {
              "eth_address": null,
              "script_hash": "0x21ad25fab1d759da1a419a589c0f36dee5e7fe3d"
            },
            "id": "17",
            "name": null,
            "supply": "400000002840",
            "type": "BRIDGE"
          }
        ]
      }
    }
    """
    field :udts, list_of(:udt) do
      arg(:input, :udts_input,
        default_value: %{type: :bridge, page: 1, page_size: 10, sort_type: :asc}
      )

      middleware(MTermRange, MTermRange.page_and_size_default_config())
      resolve(&Resolvers.UDT.udts/3)
    end
  end

  object :udt do
    field :id, :string
    field :decimal, :integer
    field :name, :string
    field :symbol, :string
    field :icon, :string
    field :supply, :decimal
    field :type_script, :json
    field :script_hash, :hash_full
    field :description, :string
    field :official_site, :string
    field :value, :decimal
    field :price, :decimal
    field :bridge_account_id, :integer
    field :type, :udt_type

    field :account, :account do
      resolve(&Resolvers.UDT.account/3)
    end
  end

  enum :udt_type do
    value(:bridge)
    value(:native)
  end

  input_object :account_id_input do
    field :account_id, :integer
  end

  input_object :udts_input do
    field :type, :udt_type
    import_fields(:page_and_size_input)
    import_fields(:sort_type_input)
  end
end

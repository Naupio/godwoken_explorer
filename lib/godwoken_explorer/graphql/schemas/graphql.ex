defmodule GodwokenExplorer.Graphql.Schemas.Graphql do
  alias GodwokenExplorer.Graphql.Middleware.NullFilter
  alias GodwokenExplorer.Graphql.Dataloader.GraphqlEcto

  use Absinthe.Schema
  import_types(GodwokenExplorer.Graphql.Types.Custom)
  import_types(GodwokenExplorer.Graphql.Types.Custom.JSON)
  import_types(GodwokenExplorer.Graphql.Types.Custom.UUID4)
  import_types(GodwokenExplorer.Graphql.Types.Custom.Money)
  import_types(GodwokenExplorer.Graphql.Types.Custom.BigInt)
  import_types(GodwokenExplorer.Graphql.Types.Custom.HashFull)
  import_types(GodwokenExplorer.Graphql.Types.Custom.HashAddress)
  import_types(GodwokenExplorer.Graphql.Types.Custom.ChainData)

  import_types(GodwokenExplorer.Graphql.Types.Common)
  import_types(GodwokenExplorer.Graphql.Types.AccountUDT)
  import_types(GodwokenExplorer.Graphql.Types.Account)
  import_types(GodwokenExplorer.Graphql.Types.Address)
  import_types(GodwokenExplorer.Graphql.Types.Block)
  import_types(GodwokenExplorer.Graphql.Types.History)
  import_types(GodwokenExplorer.Graphql.Types.Log)
  import_types(GodwokenExplorer.Graphql.Types.Polyjuice)
  import_types(GodwokenExplorer.Graphql.Types.Search)
  import_types(GodwokenExplorer.Graphql.Types.SmartContract)
  import_types(GodwokenExplorer.Graphql.Types.Sourcify)
  import_types(GodwokenExplorer.Graphql.Types.Statistic)
  import_types(GodwokenExplorer.Graphql.Types.TokenApproval)
  import_types(GodwokenExplorer.Graphql.Types.TokenTransfer)
  import_types(GodwokenExplorer.Graphql.Types.Tracker)
  import_types(GodwokenExplorer.Graphql.Types.Transaction)
  import_types(GodwokenExplorer.Graphql.Types.UDT)
  import_types(GodwokenExplorer.Graphql.Types.TokenInstance)
  import_types(GodwokenExplorer.Graphql.Types.TokenExchangeRate)

  def middleware(middleware, _field, _object) do
    [NullFilter] ++ middleware
  end

  def context(ctx) do
    loader =
      Dataloader.new()
      |> Dataloader.add_source(:graphql, GraphqlEcto.data())

    Map.put(ctx, :loader, loader)
  end

  def plugins do
    [Absinthe.Middleware.Dataloader] ++ Absinthe.Plugin.defaults()
  end

  query do
    import_fields(:account_udt_querys)
    import_fields(:account_querys)
    import_fields(:address_querys)
    import_fields(:block_querys)
    # import_fields(:history_querys)
    import_fields(:log_querys)
    # import_fields(:search_querys)
    import_fields(:smart_contract_querys)
    import_fields(:sourcify_querys)
    # import_fields(:statistic_querys)
    import_fields(:token_approval_querys)
    import_fields(:token_transfer_querys)
    # import_fields(:tracker_querys)
    import_fields(:transaction_querys)
    import_fields(:udt_querys)
    import_fields(:search_querys)
    import_fields(:history_querys)
  end

  mutation do
    import_fields(:sourcify_mutations)
    import_fields(:token_exchange_rate_mutations)
  end

  # subscription do
  # end
end

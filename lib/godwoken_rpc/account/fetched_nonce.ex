defmodule GodwokenRPC.Account.FetchedNonce do
  def request(%{account_id: account_id}) do
    GodwokenRPC.request(%{id: account_id, method: "gw_getScriptNonce", params: [account_id]})
  end
end

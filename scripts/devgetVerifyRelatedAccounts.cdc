import FindRelatedAccounts from "../contracts/FindRelatedAccounts.cdc"

access(all) fun main(user: Address, network: String, address: String) : Bool {
    let account = getAccount(user)
    let ref= account.capabilities.borrow<&FindRelatedAccounts.Accounts>(FindRelatedAccounts.publicPath)!
    return ref.verify(network: network, address: address)

}

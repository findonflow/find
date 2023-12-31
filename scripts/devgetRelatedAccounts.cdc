import FindRelatedAccounts from "../contracts/FindRelatedAccounts.cdc"

access(all) fun main(user: Address, network: String) : {String : [String]} {
    let account = getAccount(user)
    let ref= account.capabilities.borrow<&FindRelatedAccounts.Accounts>(FindRelatedAccounts.publicPath)!
    return ref.getRelatedAccounts(network)

}

import FindRelatedAccounts from "../contracts/FindRelatedAccounts.cdc"

access(all) fun main(user: Address) : {String : {String : [String]}} {
    let account = getAccount(user)
    let cap= account.capabilities.borrow<&FindRelatedAccounts.Accounts>(FindRelatedAccounts.publicPath)!
    return cap.getAllRelatedAccounts()

}

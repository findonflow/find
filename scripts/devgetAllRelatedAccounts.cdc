import "FindRelatedAccounts"

access(all) fun main(user: Address) : {String : {String : [String]}} {
    let account = getAccount(user)
    let cap= account.capabilities.borrow<&FindRelatedAccounts.Accounts>(FindRelatedAccounts.publicPath)!
    return cap.getAllRelatedAccounts()

}

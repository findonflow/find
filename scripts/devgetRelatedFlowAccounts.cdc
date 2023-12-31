import FindRelatedAccounts from "../contracts/FindRelatedAccounts.cdc"

access(all)fun  main(user: Address) : {String : [Address]} {
    let account = getAccount(user)
    let ref= account.capabilities.borrow<&FindRelatedAccounts.Accounts>(FindRelatedAccounts.publicPath)!
    return ref.getFlowAccounts()

}

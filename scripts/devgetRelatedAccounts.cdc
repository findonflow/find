import FindRelatedAccounts from "../contracts/FindRelatedAccounts.cdc"

pub fun main(user: Address, network: String) : {String : [String]} {
	let account = getAccount(user)
	let cap= account.getCapability<&FindRelatedAccounts.Accounts{FindRelatedAccounts.Public}>(FindRelatedAccounts.publicPath)
	let ref = cap.borrow()! 
	return ref.getRelatedAccounts(network)

}

import FindRelatedAccounts from "../contracts/FindRelatedAccounts.cdc"

pub fun main(user: Address, name: String, network: String, address: String) : String {
	let account = getAccount(user)
	let cap= account.getCapability<&FindRelatedAccounts.Accounts{FindRelatedAccounts.Public}>(FindRelatedAccounts.publicPath)
	let ref = cap.borrow()! 
	return ref.getIdentifier(name: name, network: network, address: address)

}

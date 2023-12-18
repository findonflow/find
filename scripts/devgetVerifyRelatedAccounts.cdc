import FindRelatedAccounts from "../contracts/FindRelatedAccounts.cdc"

access(all) main(user: Address, network: String, address: String) : Bool {
	let account = getAccount(user)
	let cap= account.getCapability<&FindRelatedAccounts.Accounts{FindRelatedAccounts.Public}>(FindRelatedAccounts.publicPath)
	let ref = cap.borrow()! 
	return ref.verify(network: network, address: address)

}

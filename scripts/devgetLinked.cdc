import FindRelatedAccounts from "../contracts/FindRelatedAccounts.cdc"

pub fun main(user: Address, name: String, address: Address) : Bool {
	let cap = FindRelatedAccounts.getCapability(user)
	return cap.borrow()!.linked(name: name, network: "Flow", address: address)

}

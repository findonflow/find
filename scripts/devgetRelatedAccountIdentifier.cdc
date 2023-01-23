import FindRelatedAccounts from "../contracts/FindRelatedAccounts.cdc"

pub fun main(user: Address, name: String, network: String, address: String) : String {
	return FindRelatedAccounts.getIdentifier(name: name, network: network, address: address)

}

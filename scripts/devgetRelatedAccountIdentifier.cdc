import "FindRelatedAccounts"

access(all) fun main(user: Address, name: String, network: String, address: String) : String {
    return FindRelatedAccounts.getIdentifier(name: name, network: network, address: address)

}

import FindMarket from "../contracts/FindMarket.cdc" 

access(all) fun main() : {String : [String] } {
	let mapping : {String : [String] } = {}

	let findAddress=FindMarket.getFindTenantAddress()
	let tenantCap = FindMarket.getTenantCapability(findAddress)!
	let tenantRef = tenantCap.borrow() ?? panic("This tenant is not set up. Tenant : ".concat(tenantCap.address.toString()))
	let marketTypes = FindMarket.getSaleItemTypes()
	for marketType in marketTypes {
		let list : [String] = []
		for type in tenantRef.getBlockedNFT(marketType: marketType) {
			list.append(type.identifier)
		}
		mapping[FindMarket.getMarketOptionFromType(marketType)] = list
	}

return mapping
}

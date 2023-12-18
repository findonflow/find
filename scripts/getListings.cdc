import FindMarket from "../contracts/FindMarket.cdc"
import FIND from "../contracts/FIND.cdc"

access(all) main(user: String) : {String : FindMarket.SaleItemCollectionReport} {
    let resolveAddress = FIND.resolve(user)
	let marketplace = FindMarket.getFindTenantAddress()
    if resolveAddress == nil { return {}}
    let address = resolveAddress!
		return FindMarket.getSaleItemReport(tenant:marketplace, address: address, getNFTInfo:false)
}

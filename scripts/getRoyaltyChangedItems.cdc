import FindMarket from "../contracts/FindMarket.cdc"
import FIND from "../contracts/FIND.cdc"

access(all) fun main(user: String) : {String : FindMarket.SaleItemCollectionReport} {
    if let address = FIND.resolve(user){
		let marketplace = FindMarket.getFindTenantAddress()
        return FindMarket.getRoyaltiesChangedItems(tenant:marketplace, address: address)
    }
    return {}
}


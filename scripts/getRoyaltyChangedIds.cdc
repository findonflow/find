import "FindMarket"
import "FIND"

access(all) fun main(user: String) : {String : [UInt64]} {
    if let address = FIND.resolve(user){
		let marketplace = FindMarket.getFindTenantAddress()
        return FindMarket.getRoyaltiesChangedIds(tenant:marketplace, address: address)
    }
    return {}
}


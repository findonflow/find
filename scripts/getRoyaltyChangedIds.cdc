import FindMarket from "../contracts/FindMarket.cdc"
import FIND from "../contracts/FIND.cdc"

access(all) main(user: String) : {String : [UInt64]} {
    if let address = FIND.resolve(user){
		let marketplace = FindMarket.getFindTenantAddress()
        return FindMarket.getRoyaltiesChangedIds(tenant:marketplace, address: address)
    }
    return {}
}


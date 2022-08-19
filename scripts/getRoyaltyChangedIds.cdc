import FindMarket from "../contracts/FindMarket.cdc"
import FIND from "../contracts/FIND.cdc"

pub fun main(marketplace: Address, user: String) : {String : [UInt64]} {
    if let address = FIND.resolve(user){
        return FindMarket.getRoyaltiesChangedIds(tenant:marketplace, address: address)
    }
    return {}
}


import FindMarket from "../contracts/FindMarket.cdc"
import FIND from "../contracts/FIND.cdc"

pub fun main(marketplace: Address, user: String) : {String : FindMarket.SaleItemCollectionReport} {
    if let address = FIND.resolve(user){
        return FindMarket.getRoyaltiesChangedItems(tenant:marketplace, address: address)
    }
    return {}
}


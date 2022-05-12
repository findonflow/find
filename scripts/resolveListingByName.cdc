import FindMarketOptions from "../contracts/FindMarketOptions.cdc" 
import FindMarket from "../contracts/FindMarket.cdc" 
import FIND from "../contracts/FIND.cdc" 

pub fun main(name: String, id: UInt64) : {String : FindMarket.SaleItemCollectionReport} {
    let status=FIND.status(name)
    if status.owner == nil {
        return {}
    }
    let address = status.owner! 
    return FindMarketOptions.getFindSaleItems(address: address, id: id)
}
 
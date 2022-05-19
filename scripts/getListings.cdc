import FindMarketOptions from "../contracts/FindMarketOptions.cdc" 
import FindMarket from "../contracts/FindMarket.cdc" 
import FIND from "../contracts/FIND.cdc" 

pub fun main(user: String) : {String : FindMarket.SaleItemCollectionReport} {
    let resolveAddress = FIND.resolve(user)
    if resolveAddress == nil { return {}}
    let address = resolveAddress!
    return FindMarketOptions.getFindSaleItemReport(address: address)
}
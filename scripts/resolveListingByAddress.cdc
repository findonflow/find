import FindMarketOptions from "../contracts/FindMarketOptions.cdc" 
import FindMarket from "../contracts/FindMarket.cdc" 

pub fun main(address: Address, id: UInt64) : {String : FindMarket.SaleItemCollectionReport} {
    return FindMarketOptions.getFindSaleItems(address: address, id: id) 
}
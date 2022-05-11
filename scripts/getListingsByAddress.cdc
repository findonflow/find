import FindMarketOptions from "../contracts/FindMarketOptions.cdc" 
import FindMarket from "../contracts/FindMarket.cdc" 

pub fun main(address: Address) : {String : FindMarket.SaleItemCollectionReport} {
    return FindMarketOptions.getFindSaleItemReport(address: address)
}
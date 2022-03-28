import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketSale from "../contracts/FindMarketSale.cdc"

pub fun main(address: Address) : [FindMarket.SaleItemInformation] {
	return FindMarketSale.getFindSaleItemCapability(address)!.borrow()!.getItemsForSale()
}

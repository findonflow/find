import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketSale from "../contracts/FindMarketSale.cdc"
import FindMarketDirectOfferEscrow from "../contracts/FindMarketDirectOfferEscrow.cdc"

pub fun main(address: Address) : [FindMarket.SaleItemInformation] {

	let items : [FindMarket.SaleItemInformation] = []
	items.appendAll(FindMarketSale.getFindSaleItemCapability(address)!.borrow()!.getItemsForSale())
	items.appendAll(FindMarketDirectOfferEscrow.getFindSaleItemCapability(address)!.borrow()!.getItemsForSale())

	return items
}

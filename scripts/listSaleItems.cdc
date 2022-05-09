import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketSale from "../contracts/FindMarketSale.cdc"
import FindMarketDirectOfferEscrow from "../contracts/FindMarketDirectOfferEscrow.cdc"
import FindMarketAuctionEscrow from "../contracts/FindMarketAuctionEscrow.cdc"
import FindMarketAuctionSoft from "../contracts/FindMarketAuctionSoft.cdc"
import FindMarketDirectOfferSoft from "../contracts/FindMarketDirectOfferSoft.cdc"

pub fun main(address: Address) : [FindMarket.SaleItemInformation] {

	let items : [FindMarket.SaleItemInformation] = []
	items.appendAll(FindMarketSale.getFindSaleItemCapability(address)!.borrow()!.getItemsForSale())
	items.appendAll(FindMarketDirectOfferEscrow.getFindSaleItemCapability(address)!.borrow()!.getItemsForSale())
	items.appendAll(FindMarketAuctionEscrow.getFindSaleItemCapability(address)!.borrow()!.getItemsForSale())
	items.appendAll(FindMarketAuctionSoft.getFindSaleItemCapability(address)!.borrow()!.getItemsForSale())
	items.appendAll(FindMarketDirectOfferSoft.getFindSaleItemCapability(address)!.borrow()!.getItemsForSale())

	return items
}

import FindMarket from "../contracts/FindMarket.cdc"

pub fun main(address: Address) : [FindMarket.SaleItemInformation] {
	return FindMarket.getFindSaleItemCapability(address)!.borrow()!.getItemsForSale()
}

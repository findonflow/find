import FindMarket from "../contracts/FindMarket.cdc"

pub fun main(address: Address) : {UInt64 :FindMarket.SaleItemInformation} {
	
	let account=getAccount(address)
	let saleItemCap= account.getCapability<&FindMarket.SaleItemCollection{FindMarket.SaleItemCollectionPublic}>(FindMarket.SaleItemCollectionPublicPath)

	return saleItemCap.borrow()!.getItemsForSale()
}

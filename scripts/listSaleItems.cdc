import Market from "../contracts/Market.cdc"

pub fun main(address: Address) : {UInt64 :Market.SaleItemInformation} {
	
	let account=getAccount(address)
	let saleItemCap= account.getCapability<&Market.SaleItemCollection{Market.SaleItemCollectionPublic}>(Market.SaleItemCollectionPublicPath)

	return saleItemCap.borrow()!.getItemsForSale()
}

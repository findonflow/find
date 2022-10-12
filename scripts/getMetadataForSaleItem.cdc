import FindMarketSale from "../contracts/FindMarketSale.cdc"

pub struct PurchaseData {
	pub let id: UInt64
	pub let name: String
	pub let amount: UFix64
	pub let description: String
	pub let imageURL: String

	init(id: UInt64, name: String, amount: UFix64, description: String, imageURL: String) {
		self.id = id
		self.name = name
		self.amount = amount
		self.description = description
		self.imageURL = imageURL
	}
}
pub fun main(merchantAddress: Address, marketplace:Address, address: Address, id: UInt64, amount: UFix64) : PurchaseData{
	let saleItemsCap= FindMarketSale.getSaleItemCapability(marketplace: marketplace, user:address) ?? panic("cannot find sale item cap")
	let saleItemCollection = saleItemsCap.borrow()!
	let item = saleItemCollection.borrowSaleItem(id)

	let display = item.getDisplay()

	var thumbnail = replacePrefix(display.thumbnail.uri(), prefix: "ipfs://", replace:"https://find.mypinata.clloud/ipfs/")
	return PurchaseData(
		id: id, 
		name: display.name, 
		amount: amount,
		description: display.description, 
		imageURL: thumbnail
	)
}

pub fun replacePrefix(_ original: String, prefix:String, replace:String) : String {
	if original.length < prefix.length  {
		return original
	}
	let oprefix = original.slice(from:0, upTo:prefix.length)
	if oprefix != prefix {
		return original
	}
	let rest = original.slice(from:prefix.length, upTo: original.length)
	return replace.concat(rest)
}

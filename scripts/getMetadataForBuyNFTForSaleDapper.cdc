import "FindMarket"
import "FindMarketSale"

access(all) fun main(address: Address, id: UInt64, amount: UFix64) : PurchaseData {

	let marketplace = FindMarket.getFindTenantAddress()
	let marketOption = FindMarket.getMarketOptionFromType(Type<@FindMarketSale.SaleItemCollection>())
	let item= FindMarket.assertOperationValid(tenant: marketplace, address: address, marketOption: marketOption, id: id)
	let display = item.getDisplay()
	let itemID = item.getItemID()
	let amount = item.getBalance()


	return PurchaseData(
		id: itemID,
		name: display.name,
		amount: amount,
		description: display.description,
		imageURL: display.thumbnail.uri(), 
		paymentVaultTypeID: item.getFtType(),
	)
}

access(all) struct PurchaseData {
	access(all) let id: UInt64
	access(all) let name: String
	access(all) let amount: UFix64
	access(all) let description: String
	access(all) let imageURL: String
  access(all) let paymentVaultTypeID: Type

	init(id: UInt64, name: String, amount: UFix64, description: String, imageURL: String, paymentVaultTypeID: Type) {
		self.id = id
		self.name = name
		self.amount = amount
		self.description = description
		self.imageURL = imageURL
		self.paymentVaultTypeID=paymentVaultTypeID
	}
}

import FindMarket from "../contracts/FindMarket.cdc"
import FIND from "../contracts/FIND.cdc"
import Profile from "../contracts/Profile.cdc"
import DapperUtilityCoin from "../contracts/standard/DapperUtilityCoin.cdc"
import FindLeaseMarketSale from "../contracts/FindLeaseMarketSale.cdc"
import FindLeaseMarket from "../contracts/FindLeaseMarket.cdc"

access(all) fun main(sellerAccount: Address, leaseName: String, amount: UFix64) :PurchaseData{

	let address = FIND.resolve(leaseName) ?? panic("The address input is not a valid name nor address. Input : ".concat(leaseName))
	let leaseMarketplace = FindMarket.getFindTenantAddress()
	let leaseTenant = FindMarket.getTenant(leaseMarketplace)
	let storagePath = leaseTenant.getStoragePath(Type<@FindLeaseMarketSale.SaleItemCollection>())
	let saleItemRef = getAuthAccount(address).borrow<&FindLeaseMarketSale.SaleItemCollection>(from: storagePath) ?? panic("Cannot borrow reference to sale item")
	let saleItem = saleItemRef.borrow(leaseName)

	let description = "Name :".concat(leaseName).concat(" for DUC ").concat(amount.toString())
	let imageURL = "https://i.imgur.com/8W8NoO1.png"

	return PurchaseData(
			id: saleItem.getId(),
			name: leaseName,
			amount: amount,
			description: description,
			imageURL: imageURL
			)
}

access(all) struct PurchaseData {
	access(all) let id: UInt64
	access(all) let name: String
	access(all) let amount: UFix64
	access(all) let description: String
	access(all) let imageURL: String

	init(id: UInt64, name: String, amount: UFix64, description: String, imageURL: String) {
		self.id = id
		self.name = name
		self.amount = amount
		self.description = description
		self.imageURL = imageURL
	}
}

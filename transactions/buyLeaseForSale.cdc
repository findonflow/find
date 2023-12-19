import FindMarket from "../contracts/FindMarket.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FIND from "../contracts/FIND.cdc"
import FindLeaseMarketSale from "../contracts/FindLeaseMarketSale.cdc"
import FindLeaseMarket from "../contracts/FindLeaseMarket.cdc"

transaction(leaseName: String, amount: UFix64) {

	let walletReference : &FungibleToken.Vault

	let saleItemsCap: Capability<&FindLeaseMarketSale.SaleItemCollection{FindLeaseMarketSale.SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic}>
	let buyer: Address

	prepare(account: auth(BorrowValue) &Account) {

		let resolveAddress = FIND.resolve(leaseName)
		if resolveAddress == nil {
			panic("The address input is not a valid name nor address. Input : ".concat(leaseName))
		}
		let address = resolveAddress!
		let leaseMarketplace = FindMarket.getFindTenantAddress()
		let leaseTenantCapability= FindMarket.getTenantCapability(leaseMarketplace)!
		let leaseTenant = leaseTenantCapability.borrow()!

		let leaseSaleItemType= Type<@FindLeaseMarketSale.SaleItemCollection>()
		let leasePublicPath=leaseTenant.getPublicPath(leaseSaleItemType)
		let leaseStoragePath= leaseTenant.getStoragePath(leaseSaleItemType)
		let leaseSaleItemCap= account.getCapability<&FindLeaseMarketSale.SaleItemCollection{FindLeaseMarketSale.SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic}>(leasePublicPath)
		if !leaseSaleItemCap.check() {
			//The link here has to be a capability not a tenant, because it can change.
			account.storage.save<@FindLeaseMarketSale.SaleItemCollection>(<- FindLeaseMarketSale.createEmptySaleItemCollection(leaseTenantCapability), to: leaseStoragePath)
			account.link<&FindLeaseMarketSale.SaleItemCollection{FindLeaseMarketSale.SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic}>(leasePublicPath, target: leaseStoragePath)
		}

		self.saleItemsCap= getAccount(address).getCapability<&FindLeaseMarketSale.SaleItemCollection{FindLeaseMarketSale.SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic}>(leasePublicPath)
		let marketOption = FindMarket.getMarketOptionFromType(Type<@FindLeaseMarketSale.SaleItemCollection>())

		let item= FindLeaseMarket.assertOperationValid(tenant: leaseMarketplace, name: leaseName, marketOption: marketOption)

		let ft = FTRegistry.getFTInfoByTypeIdentifier(item.getFtType().identifier) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(item.getFtType().identifier))

		self.walletReference = account.storage.borrow<&FungibleToken.Vault>(from: ft.vaultPath) ?? panic("No suitable wallet linked for this account")
		self.buyer = account.address
	}

	pre {
		self.walletReference.balance > amount : "Your wallet does not have enough funds to pay for this item"
	}

	execute {
		let vault <- self.walletReference.withdraw(amount: amount)
		self.saleItemsCap.borrow()!.buy(name:leaseName, vault: <- vault, to: self.buyer)
	}
}


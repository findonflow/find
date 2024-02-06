import "FindMarket"
import "FTRegistry"
import "FungibleToken"
import "FIND"
import "FindLeaseMarketSale"
import "FindLeaseMarket"

transaction(leaseName: String, amount: UFix64) {

	let walletReference : auth(FungibleToken.Withdraw) &{FungibleToken.Vault}

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
		let leaseSaleItemCap= account.capabilities.get<&FindLeaseMarketSale.SaleItemCollection{FindLeaseMarketSale.SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic}>(leasePublicPath)
		if leaseSaleItemCap == nil {
			//The link here has to be a capability not a tenant, because it can change.
			account.storage.save<@FindLeaseMarketSale.SaleItemCollection>(<- FindLeaseMarketSale.createEmptySaleItemCollection(leaseTenantCapability), to: leaseStoragePath)
			account.link<&FindLeaseMarketSale.SaleItemCollection{FindLeaseMarketSale.SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic}>(leasePublicPath, target: leaseStoragePath)
		}

		self.saleItemsCap= getAccount(address).capabilities.get<&FindLeaseMarketSale.SaleItemCollection{FindLeaseMarketSale.SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic}>(leasePublicPath)!
		let marketOption = FindMarket.getMarketOptionFromType(Type<@FindLeaseMarketSale.SaleItemCollection>())

		let item= FindLeaseMarket.assertOperationValid(tenant: leaseMarketplace, name: leaseName, marketOption: marketOption)

		let ft = FTRegistry.getFTInfoByTypeIdentifier(item.getFtType().identifier) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(item.getFtType().identifier))

		self.walletReference = account.storage.borrow<auth(FungibleToken.Withdraw) &FungibleToken.Vault>(from: ft.vaultPath) ?? panic("No suitable wallet linked for this account")
		self.buyer = account.address
	}

	pre {
		self.walletReference.getBalance() > amount : "Your wallet does not have enough funds to pay for this item"
	}

	execute {
		let vault <- self.walletReference.withdraw(amount: amount)
		self.saleItemsCap.borrow()!.buy(name:leaseName, vault: <- vault, to: self.buyer)
	}
}


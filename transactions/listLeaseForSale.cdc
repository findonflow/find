import FindMarket from "../contracts/FindMarket.cdc"
import FIND from "../contracts/FIND.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FindLeaseMarketSale from "../contracts/FindLeaseMarketSale.cdc"
import FindLeaseMarket from "../contracts/FindLeaseMarket.cdc"

transaction(leaseName: String, ftAliasOrIdentifier: String, directSellPrice:UFix64, validUntil: UFix64?) {

	let saleItems : &FindLeaseMarketSale.SaleItemCollection?
	let pointer : FindLeaseMarket.AuthLeasePointer
	let vaultType : Type

	prepare(account: AuthAccount) {

		// Get the salesItemRef from tenant
		let leaseMarketplace = FindMarket.getTenantAddress("findLease")!
		let leaseTenantCapability= FindMarket.getTenantCapability(leaseMarketplace)!
		let leaseTenant = leaseTenantCapability.borrow()!

		let leaseSaleItemType= Type<@FindLeaseMarketSale.SaleItemCollection>()
		let leasePublicPath=FindMarket.getPublicPath(leaseSaleItemType, name: "findLease")
		let leaseStoragePath= FindMarket.getStoragePath(leaseSaleItemType, name:"findLease")
		let leaseSaleItemCap= account.getCapability<&FindLeaseMarketSale.SaleItemCollection{FindLeaseMarketSale.SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic}>(leasePublicPath) 
		if !leaseSaleItemCap.check() {
			//The link here has to be a capability not a tenant, because it can change.
			account.save<@FindLeaseMarketSale.SaleItemCollection>(<- FindLeaseMarketSale.createEmptySaleItemCollection(leaseTenantCapability), to: leaseStoragePath)
			account.link<&FindLeaseMarketSale.SaleItemCollection{FindLeaseMarketSale.SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic}>(leasePublicPath, target: leaseStoragePath)
		}

		self.saleItems= account.borrow<&FindLeaseMarketSale.SaleItemCollection>(from: leaseStoragePath)!

		// Get supported NFT and FT Information from Registries from input alias
		let ft = FTRegistry.getFTInfo(ftAliasOrIdentifier) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(ftAliasOrIdentifier))
		self.vaultType= ft.type

		let lease=account.borrow<&FIND.LeaseCollection>(from: FIND.LeaseStoragePath)!


		self.pointer= FindLeaseMarket.AuthLeasePointer(ref:lease, name: leaseName)

	}

	pre{
		self.saleItems != nil : "Cannot borrow reference to saleItem"
	}

	execute{
		self.saleItems!.listForSale(pointer: self.pointer, vaultType: self.vaultType, directSellPrice: directSellPrice, validUntil: validUntil, extraField: {})
	}
}


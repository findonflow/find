import FindMarket from "../contracts/FindMarket.cdc"
import DapperUtilityCoin from "../contracts/standard/DapperUtilityCoin.cdc"
import FIND from "../contracts/FIND.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FindLeaseMarketSale from "../contracts/FindLeaseMarketSale.cdc"
import FindLeaseMarket from "../contracts/FindLeaseMarket.cdc"

transaction(dapperAddress: Address, leaseName: String, directSellPrice:UFix64, validUntil: UFix64?) {

	let saleItems : &FindLeaseMarketSale.SaleItemCollection?
	let pointer : FindLeaseMarket.AuthLeasePointer
	let vaultType : Type

	prepare(account: AuthAccount) {

		// Get the salesItemRef from tenant
		let leaseMarketplace = FindMarket.getTenantAddress("findLease")!
		let leaseTenantCapability= FindMarket.getTenantCapability(leaseMarketplace)!
		let leaseTenant = leaseTenantCapability.borrow()!
		self.saleItems= account.borrow<&FindLeaseMarketSale.SaleItemCollection>(from: leaseTenant.getStoragePath(Type<@FindLeaseMarketSale.SaleItemCollection>()))

		// Get supported NFT and FT Information from Registries from input alias
		let ft = FTRegistry.getFTInfo(Type<@DapperUtilityCoin.Vault>().identifier) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(Type<@DapperUtilityCoin.Vault>().identifier))
		self.vaultType= ft.type

		let ref=account.borrow<&FIND.LeaseCollection>(from: FIND.LeaseStoragePath)!

		self.pointer= FindLeaseMarket.AuthLeasePointer(ref: ref, name: leaseName)
	}

	pre{
		self.saleItems != nil : "Cannot borrow reference to saleItem"
	}

	execute{
		self.saleItems!.listForSale(pointer: self.pointer, vaultType: self.vaultType, directSellPrice: directSellPrice, validUntil: validUntil, extraField: {})

	}

}


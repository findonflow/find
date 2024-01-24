import FindMarket from "../contracts/FindMarket.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FIND from "../contracts/FIND.cdc"
import FindLeaseMarketAuctionSoft from "../contracts/FindLeaseMarketAuctionSoft.cdc"
import FindLeaseMarket from "../contracts/FindLeaseMarket.cdc"

transaction(leaseName: String, ftAliasOrIdentifier: String, price:UFix64, auctionReservePrice: UFix64, auctionDuration: UFix64, auctionExtensionOnLateBid: UFix64, minimumBidIncrement: UFix64, auctionValidUntil: UFix64?) {

	let saleItems : &FindLeaseMarketAuctionSoft.SaleItemCollection?
	let pointer : FindLeaseMarket.AuthLeasePointer
	let vaultType : Type

	prepare(account: auth(StorageCapabilities, SaveValue,PublishCapability, BorrowValue) &Account) {

		// Get supported NFT and FT Information from Registries from input alias
		let ft = FTRegistry.getFTInfo(ftAliasOrIdentifier) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(ftAliasOrIdentifier))

		let leaseMarketplace = FindMarket.getFindTenantAddress()
		let leaseTenantCapability= FindMarket.getTenantCapability(leaseMarketplace)!
		let leaseTenant = leaseTenantCapability.borrow()!

		let leaseASSaleItemType= Type<@FindLeaseMarketAuctionSoft.SaleItemCollection>()
		let leaseASPublicPath=leaseTenant.getPublicPath(leaseASSaleItemType)
		let leaseASStoragePath= leaseTenant.getStoragePath(leaseASSaleItemType)
		let leaseASSaleItemCap= account.capabilities.get<&FindLeaseMarketAuctionSoft.SaleItemCollection>(leaseASPublicPath)
		if leaseASSaleItemCap == nil {
			//The link here has to be a capability not a tenant, because it can change.
			account.storage.save<@FindLeaseMarketAuctionSoft.SaleItemCollection>(<- FindLeaseMarketAuctionSoft.createEmptySaleItemCollection(leaseTenantCapability), to: leaseASStoragePath)
			let saleColCap = account.capabilities.storage.issue<&FindLeaseMarketAuctionSoft.SaleItemCollection>(leaseASStoragePath)
			account.capabilities.publish(saleColCap, at: leaseASPublicPath)
		}

		self.saleItems= account.storage.borrow<&FindLeaseMarketAuctionSoft.SaleItemCollection>(from: leaseASStoragePath)
		let cap = account.capabilities.storage.issue<auth(FIND.Leasee) &FIND.LeaseCollection>(FIND.LeaseStoragePath)!
		self.pointer= FindLeaseMarket.AuthLeasePointer(cap: cap, name: leaseName)
		self.vaultType= ft.type
	}

	pre{
		// Ben : panic on some unreasonable inputs in trxn
		minimumBidIncrement > 0.0 :"Minimum bid increment should be larger than 0."
		(auctionReservePrice - auctionReservePrice) % minimumBidIncrement == 0.0 : "Acution ReservePrice should be in step of minimum bid increment."
		auctionDuration > 0.0 : "Auction Duration should be greater than 0."
		auctionExtensionOnLateBid > 0.0 : "Auction Duration should be greater than 0."
		self.saleItems != nil : "Cannot borrow reference to saleItem"
	}

	execute{
		self.saleItems!.listForAuction(pointer: self.pointer, vaultType: self.vaultType, auctionStartPrice: price, auctionReservePrice: auctionReservePrice, auctionDuration: auctionDuration, auctionExtensionOnLateBid: auctionExtensionOnLateBid, minimumBidIncrement: minimumBidIncrement, auctionValidUntil: auctionValidUntil, saleItemExtraField: {})

	}
}

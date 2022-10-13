import FindMarket from "../contracts/FindMarket.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FIND from "../contracts/FIND.cdc"
import FindLeaseMarketAuctionSoft from "../contracts/FindLeaseMarketAuctionSoft.cdc"
import FindLeaseMarket from "../contracts/FindLeaseMarket.cdc"

transaction(leaseName: String, ftAliasOrIdentifier:String, price:UFix64, auctionReservePrice: UFix64, auctionDuration: UFix64, auctionExtensionOnLateBid: UFix64, minimumBidIncrement: UFix64, auctionValidUntil: UFix64?) {
	
	let saleItems : &FindLeaseMarketAuctionSoft.SaleItemCollection?
	let pointer : FindLeaseMarket.AuthLeasePointer
	let vaultType : Type
	
	prepare(account: AuthAccount) {

		// Get supported NFT and FT Information from Registries from input alias
		let ft = FTRegistry.getFTInfo(ftAliasOrIdentifier) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(ftAliasOrIdentifier))
		
		let leaseMarketplace = FindMarket.getTenantAddress("findLease")!
		let leaseTenantCapability= FindMarket.getTenantCapability(leaseMarketplace)!
		let leaseTenant = leaseTenantCapability.borrow()!
		self.saleItems= account.borrow<&FindLeaseMarketAuctionSoft.SaleItemCollection>(from: leaseTenant.getStoragePath(Type<@FindLeaseMarketAuctionSoft.SaleItemCollection>()))
		let ref = account.borrow<&FIND.LeaseCollection>(from: FIND.LeaseStoragePath)!
		self.pointer= FindLeaseMarket.AuthLeasePointer(ref: ref, name: leaseName)
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

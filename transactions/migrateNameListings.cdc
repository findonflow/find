import FIND from "../contracts/FIND.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import FindLeaseMarket from "../contracts/FindLeaseMarket.cdc"
import FindLeaseMarketSale from "../contracts/FindLeaseMarketSale.cdc"
import FindLeaseMarketAuctionEscrow from "../contracts/FindLeaseMarketAuctionEscrow.cdc"
import FindLeaseMarketDirectOfferEscrow from "../contracts/FindLeaseMarketDirectOfferEscrow.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"

transaction() {

	let saleRef : &FindLeaseMarketSale.SaleItemCollection
	let auctionRef : &FindLeaseMarketAuctionEscrow.SaleItemCollection
	let find : &FIND.LeaseCollection

	prepare(account: AuthAccount) {

		let tenantCapability= FindMarket.getTenantCapability(FindMarket.getFindTenantAddress())!
		let tenant = tenantCapability.borrow()!

		let leaseSaleType= Type<@FindLeaseMarketSale.SaleItemCollection>()
		let leaseSalePublicPath=FindMarket.getPublicPath(leaseSaleType, name: tenant.name)
		let leaseSaleStoragePath= FindMarket.getStoragePath(leaseSaleType, name:tenant.name)
		let leaseSaleCap= account.getCapability<&FindLeaseMarketSale.SaleItemCollection{FindLeaseMarketSale.SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic}>(leaseSalePublicPath)
		if !leaseSaleCap.check() {
			account.save<@FindLeaseMarketSale.SaleItemCollection>(<- FindLeaseMarketSale.createEmptySaleItemCollection(tenantCapability), to: leaseSaleStoragePath)
			account.link<&FindLeaseMarketSale.SaleItemCollection{FindLeaseMarketSale.SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic}>(leaseSalePublicPath, target: leaseSaleStoragePath)
		}
		self.saleRef = account.borrow<&FindLeaseMarketSale.SaleItemCollection>(from: leaseSaleStoragePath)!

		let leaseaeType= Type<@FindLeaseMarketAuctionEscrow.SaleItemCollection>()
		let leaseaeSalePublicPath=FindMarket.getPublicPath(leaseaeType, name: tenant.name)
		let leaseaeSaleStoragePath= FindMarket.getStoragePath(leaseaeType, name:tenant.name)
		let leaseaeSaleCap= account.getCapability<&FindLeaseMarketAuctionEscrow.SaleItemCollection{FindLeaseMarketAuctionEscrow.SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic}>(leaseaeSalePublicPath)
		if !leaseaeSaleCap.check() {
			account.save<@FindLeaseMarketAuctionEscrow.SaleItemCollection>(<- FindLeaseMarketAuctionEscrow.createEmptySaleItemCollection(tenantCapability), to: leaseaeSaleStoragePath)
			account.link<&FindLeaseMarketAuctionEscrow.SaleItemCollection{FindLeaseMarketAuctionEscrow.SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic}>(leaseaeSalePublicPath, target: leaseaeSaleStoragePath)
		}
		self.auctionRef = account.borrow<&FindLeaseMarketAuctionEscrow.SaleItemCollection>(from: leaseaeSaleStoragePath)!

		let leasedoeSaleType= Type<@FindLeaseMarketDirectOfferEscrow.SaleItemCollection>()
		let leasedoeSalePublicPath=FindMarket.getPublicPath(leasedoeSaleType, name: tenant.name)
		let leasedoeSaleStoragePath= FindMarket.getStoragePath(leasedoeSaleType, name:tenant.name)
		let leasedoeSaleCap= account.getCapability<&FindLeaseMarketDirectOfferEscrow.SaleItemCollection{FindLeaseMarketDirectOfferEscrow.SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic}>(leasedoeSalePublicPath)
		if !leasedoeSaleCap.check() {
			account.save<@FindLeaseMarketDirectOfferEscrow.SaleItemCollection>(<- FindLeaseMarketDirectOfferEscrow.createEmptySaleItemCollection(tenantCapability), to: leasedoeSaleStoragePath)
			account.link<&FindLeaseMarketDirectOfferEscrow.SaleItemCollection{FindLeaseMarketDirectOfferEscrow.SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic}>(leasedoeSalePublicPath, target: leasedoeSaleStoragePath)
		}

		self.find = account.borrow<&FIND.LeaseCollection>(from: FIND.LeaseStoragePath) ?? panic("Cannot borrow FIND Lease Collection")

		for l in self.find.getLeaseInformation() {
			// This should be a sale
			if l.salePrice != nil {
				let pointer = FindLeaseMarket.AuthLeasePointer(ref:self.find, name: l.name)
				self.saleRef.listForSale(pointer: pointer, vaultType: Type<@FUSD.Vault>(), directSellPrice: l.salePrice!, validUntil: nil, extraField: {})
			}

			if l.auctionStartPrice != nil {
				let pointer = FindLeaseMarket.AuthLeasePointer(ref:self.find, name: l.name)
				self.auctionRef.listForAuction(pointer: pointer, vaultType: Type<@FUSD.Vault>(), auctionStartPrice: l.auctionStartPrice!, auctionReservePrice: l.auctionReservePrice ?? l.auctionStartPrice!, auctionDuration: 86400.0 , auctionExtensionOnLateBid: l.extensionOnLateBid ?? 300.0, minimumBidIncrement: 1.0, auctionStartTime: nil, auctionValidUntil: nil, saleItemExtraField: {})
			}
		}

	}

}

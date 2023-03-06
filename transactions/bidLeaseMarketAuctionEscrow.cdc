import Profile from "../contracts/Profile.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import FIND from "../contracts/FIND.cdc"
import FindLeaseMarketAuctionEscrow from "../contracts/FindLeaseMarketAuctionEscrow.cdc"
import FindLeaseMarket from "../contracts/FindLeaseMarket.cdc"

transaction(leaseName: String, amount: UFix64) {

	let saleItemsCap: Capability<&FindLeaseMarketAuctionEscrow.SaleItemCollection{FindLeaseMarketAuctionEscrow.SaleItemCollectionPublic}>
	let bidsReference: &FindLeaseMarketAuctionEscrow.MarketBidCollection?
	let ftVault: @FungibleToken.Vault

	prepare(account: AuthAccount) {

		let resolveAddress = FIND.resolve(leaseName)
		if resolveAddress == nil {panic("The address input is not a valid name nor address. Input : ".concat(leaseName))}
		let address = resolveAddress!

		let leaseMarketplace = FindMarket.getFindTenantAddress()
		let leaseTenantCapability= FindMarket.getTenantCapability(leaseMarketplace)!
		let leaseTenant = leaseTenantCapability.borrow()!

		let receiverCap=account.getCapability<&{FungibleToken.Receiver}>(Profile.publicReceiverPath)
		let leaseASBidType= Type<@FindLeaseMarketAuctionEscrow.MarketBidCollection>()
		let leaseASBidPublicPath=leaseTenant.getPublicPath(leaseASBidType)
		let leaseASBidStoragePath= leaseTenant.getStoragePath(leaseASBidType)
		let leaseASBidCap= account.getCapability<&FindLeaseMarketAuctionEscrow.MarketBidCollection{FindLeaseMarketAuctionEscrow.MarketBidCollectionPublic, FindLeaseMarket.MarketBidCollectionPublic}>(leaseASBidPublicPath)
		if !leaseASBidCap.check() {
			account.save<@FindLeaseMarketAuctionEscrow.MarketBidCollection>(<- FindLeaseMarketAuctionEscrow.createEmptyMarketBidCollection(receiver:receiverCap, tenantCapability:leaseTenantCapability), to: leaseASBidStoragePath)
			account.link<&FindLeaseMarketAuctionEscrow.MarketBidCollection{FindLeaseMarketAuctionEscrow.MarketBidCollectionPublic, FindLeaseMarket.MarketBidCollectionPublic}>(leaseASBidPublicPath, target: leaseASBidStoragePath)
		}

		self.saleItemsCap= FindLeaseMarketAuctionEscrow.getSaleItemCapability(marketplace:leaseMarketplace, user:address) ?? panic("cannot find sale item cap")
		let marketOption = FindMarket.getMarketOptionFromType(Type<@FindLeaseMarketAuctionEscrow.SaleItemCollection>())

		let item = FindLeaseMarket.assertOperationValid(tenant: leaseMarketplace, name: leaseName, marketOption: marketOption)

		let ft = FTRegistry.getFTInfoByTypeIdentifier(item.getFtType().identifier) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(item.getFtType().identifier))

		self.ftVault <- account.borrow<&FungibleToken.Vault>(from: ft.vaultPath)?.withdraw(amount: amount) ?? panic("Cannot borrow vault from sender")

		let bidStoragePath=leaseTenant.getStoragePath(Type<@FindLeaseMarketAuctionEscrow.MarketBidCollection>())

		self.bidsReference= account.borrow<&FindLeaseMarketAuctionEscrow.MarketBidCollection>(from: bidStoragePath)
	}

	pre {
		self.bidsReference != nil : "This account does not have a bid collection"
	}

	execute {
		self.bidsReference!.bid(name:leaseName, vault: <- self.ftVault, bidExtraField: {})
	}
}

import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import Profile from "../contracts/Profile.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import FIND from "../contracts/FIND.cdc"
import FindLeaseMarket from "../contracts/FindLeaseMarket.cdc"
import FindLeaseMarketAuctionSoft from "../contracts/FindLeaseMarketAuctionSoft.cdc"

transaction(leaseName: String, amount: UFix64) {

	let saleItemsCap: Capability<&FindLeaseMarketAuctionSoft.SaleItemCollection{FindLeaseMarketAuctionSoft.SaleItemCollectionPublic}>
	let walletReference : &FungibleToken.Vault
	let bidsReference: &FindLeaseMarketAuctionSoft.MarketBidCollection?
	let balanceBeforeBid: UFix64
	let ftVaultType: Type

	prepare(account: AuthAccount) {

		let resolveAddress = FIND.resolve(leaseName)
		if resolveAddress == nil {panic("The address input is not a valid name nor address. Input : ".concat(leaseName))}
		let address = resolveAddress!

		let leaseMarketplace = FindMarket.getFindTenantAddress()
		let leaseTenantCapability= FindMarket.getTenantCapability(leaseMarketplace)!
		let leaseTenant = leaseTenantCapability.borrow()!

		let receiverCap=account.getCapability<&{FungibleToken.Receiver}>(Profile.publicReceiverPath)
		let leaseASBidType= Type<@FindLeaseMarketAuctionSoft.MarketBidCollection>()
		let leaseASBidPublicPath=leaseTenant.getPublicPath(leaseASBidType)
		let leaseASBidStoragePath= leaseTenant.getStoragePath(leaseASBidType)
		let leaseASBidCap= account.getCapability<&FindLeaseMarketAuctionSoft.MarketBidCollection{FindLeaseMarketAuctionSoft.MarketBidCollectionPublic, FindLeaseMarket.MarketBidCollectionPublic}>(leaseASBidPublicPath)
		if !leaseASBidCap.check() {
			account.save<@FindLeaseMarketAuctionSoft.MarketBidCollection>(<- FindLeaseMarketAuctionSoft.createEmptyMarketBidCollection(receiver:receiverCap, tenantCapability:leaseTenantCapability), to: leaseASBidStoragePath)
			account.link<&FindLeaseMarketAuctionSoft.MarketBidCollection{FindLeaseMarketAuctionSoft.MarketBidCollectionPublic, FindLeaseMarket.MarketBidCollectionPublic}>(leaseASBidPublicPath, target: leaseASBidStoragePath)
		}

		self.saleItemsCap= FindLeaseMarketAuctionSoft.getSaleItemCapability(marketplace:leaseMarketplace, user:address) ?? panic("cannot find sale item cap")
		let marketOption = FindMarket.getMarketOptionFromType(Type<@FindLeaseMarketAuctionSoft.SaleItemCollection>())

		let item = FindLeaseMarket.assertOperationValid(tenant: leaseMarketplace, name: leaseName, marketOption: marketOption)

		let ft = FTRegistry.getFTInfoByTypeIdentifier(item.getFtType().identifier) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(item.getFtType().identifier))

		self.walletReference = account.borrow<&FungibleToken.Vault>(from: ft.vaultPath) ?? panic("No suitable wallet linked for this account. Account address : ".concat(account.address.toString()))
		self.ftVaultType = ft.type

		let bidStoragePath=leaseTenant.getStoragePath(Type<@FindLeaseMarketAuctionSoft.MarketBidCollection>())

		self.bidsReference= account.borrow<&FindLeaseMarketAuctionSoft.MarketBidCollection>(from: bidStoragePath)
		self.balanceBeforeBid=self.walletReference.balance
	}

	pre {
		self.bidsReference != nil : "This account does not have a bid collection"
		self.walletReference.balance > amount : "Your wallet does not have enough funds to pay for this item"
	}

	execute {
		self.bidsReference!.bid(name:leaseName, amount: amount, vaultType: self.ftVaultType, bidExtraField: {})
	}
}

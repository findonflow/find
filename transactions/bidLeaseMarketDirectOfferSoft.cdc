import FindMarket from "../contracts/FindMarket.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FIND from "../contracts/FIND.cdc"
import FindLeaseMarketDirectOfferSoft from "../contracts/FindLeaseMarketDirectOfferSoft.cdc"

transaction(leaseName: String, ftAliasOrIdentifier:String, amount: UFix64, validUntil: UFix64?) {

	let bidsReference: &FindLeaseMarketDirectOfferSoft.MarketBidCollection?
	let ftVaultType: Type

	prepare(account: AuthAccount) {


		let resolveAddress = FIND.resolve(leaseName)
		if resolveAddress == nil {panic("The address input is not a valid name nor address. Input : ".concat(leaseName))}
		let address = resolveAddress!

		let ft = FTRegistry.getFTInfo(ftAliasOrIdentifier) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(ftAliasOrIdentifier))

		self.ftVaultType = ft.type

		let walletReference = account.borrow<&FungibleToken.Vault>(from: ft.vaultPath) ?? panic("No suitable wallet linked for this account")
		assert(walletReference.balance > amount , message: "Bidder has to have enough balance in wallet")

		let leaseMarketplace = FindMarket.getTenantAddress("findLease")!
		let leaseTenantCapability= FindMarket.getTenantCapability(leaseMarketplace)!
		let leaseTenant = leaseTenantCapability.borrow()!
		let bidStoragePath=leaseTenant.getStoragePath(Type<@FindLeaseMarketDirectOfferSoft.MarketBidCollection>())
		self.bidsReference= account.borrow<&FindLeaseMarketDirectOfferSoft.MarketBidCollection>(from: bidStoragePath)

	}

	pre {
		self.bidsReference != nil : "This account does not have a bid collection"
	}

	execute {
		self.bidsReference!.bid(name:leaseName, amount: amount, vaultType: self.ftVaultType, validUntil: validUntil, saleItemExtraField: {}, bidExtraField: {})
	}
}

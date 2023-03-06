import FindLeaseMarketDirectOfferEscrow from "../contracts/FindLeaseMarketDirectOfferEscrow.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import FindLeaseMarket from "../contracts/FindLeaseMarket.cdc"

transaction(leaseName: String, amount: UFix64) {

	let bidsReference: &FindLeaseMarketDirectOfferEscrow.MarketBidCollection
	let ftVault: @FungibleToken.Vault

	prepare(account: AuthAccount) {
		let marketplace = FindMarket.getFindTenantAddress()
		let tenant=FindMarket.getTenant(marketplace)
		let storagePath=tenant.getStoragePath(Type<@FindLeaseMarketDirectOfferEscrow.MarketBidCollection>())
		self.bidsReference= account.borrow<&FindLeaseMarketDirectOfferEscrow.MarketBidCollection>(from: storagePath) ?? panic("Bid resource does not exist")
		// get Bidding Fungible Token Vault
  		let marketOption = FindMarket.getMarketOptionFromType(Type<@FindLeaseMarketDirectOfferEscrow.MarketBidCollection>())
		let item = FindLeaseMarket.assertBidOperationValid(tenant: marketplace, address: account.address, marketOption: marketOption, name: leaseName)

		let ft = item.getFtType()
		let ftInfo = FTRegistry.getFTInfo(ft.identifier) ?? panic("This FT is not supported in FT Registry")
		self.ftVault <- account.borrow<&FungibleToken.Vault>(from: ftInfo.vaultPath)?.withdraw(amount: amount) ?? panic("cannot borrow vault from buyer")
	}

	execute {
		self.bidsReference.increaseBid(name: leaseName, vault: <- self.ftVault)
	}
}


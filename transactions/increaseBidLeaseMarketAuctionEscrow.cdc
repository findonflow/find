import FindLeaseMarketAuctionEscrow from "../contracts/FindLeaseMarketAuctionEscrow.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import FindLeaseMarket from "../contracts/FindLeaseMarket.cdc"

transaction(leaseName: String, amount: UFix64) {

	let bidsReference: &FindLeaseMarketAuctionEscrow.MarketBidCollection
	let vault: @FungibleToken.Vault

	prepare(account: AuthAccount) {
		let marketplace = FindMarket.getFindTenantAddress()
		let tenant=FindMarket.getTenant(marketplace)
		let storagePath=tenant.getStoragePath(Type<@FindLeaseMarketAuctionEscrow.MarketBidCollection>())
		self.bidsReference= account.borrow<&FindLeaseMarketAuctionEscrow.MarketBidCollection>(from: storagePath) ?? panic("Bid resource does not exist")
		// get Bidding Fungible Token Vault
	  	let marketOption = FindMarket.getMarketOptionFromType(Type<@FindLeaseMarketAuctionEscrow.MarketBidCollection>())
		let item = FindLeaseMarket.assertBidOperationValid(tenant: marketplace, address: account.address, marketOption: marketOption, name: leaseName)

		let ft = FTRegistry.getFTInfoByTypeIdentifier(item.getFtType().identifier) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(item.getFtType().identifier))
		self.vault <- account.borrow<&FungibleToken.Vault>(from: ft.vaultPath)?.withdraw(amount: amount) ?? panic("Cannot borrow vault from bidder")
	}

	execute {
		self.bidsReference.increaseBid(name: leaseName, vault: <- self.vault)
	}

}


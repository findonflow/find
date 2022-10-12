import FindLeaseMarketAuctionSoft from "../contracts/FindLeaseMarketAuctionSoft.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import FindLeaseMarket from "../contracts/FindLeaseMarket.cdc"

transaction(leaseName: String, amount: UFix64) {

	let bidsReference: &FindLeaseMarketAuctionSoft.MarketBidCollection

	prepare(dapper: AuthAccount, account: AuthAccount) {
		let marketplace = FindMarket.getTenantAddress("findLease")!
		let tenant=FindMarket.getTenant(marketplace)
		let storagePath=tenant.getStoragePath(Type<@FindLeaseMarketAuctionSoft.MarketBidCollection>())
		self.bidsReference= account.borrow<&FindLeaseMarketAuctionSoft.MarketBidCollection>(from: storagePath) ?? panic("Bid resource does not exist")
		// get Bidding Fungible Token Vault
	  	let marketOption = FindMarket.getMarketOptionFromType(Type<@FindLeaseMarketAuctionSoft.MarketBidCollection>())
		let item = FindLeaseMarket.assertBidOperationValid(tenant: marketplace, address: account.address, marketOption: marketOption, name: leaseName)

		let ft = FTRegistry.getFTInfoByTypeIdentifier(item.getFtType().identifier) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(item.getFtType().identifier))

		let walletReference = dapper.borrow<&FungibleToken.Vault>(from: ft.vaultPath) 
		if ft.alias != "DUC" && walletReference == nil {
			panic("No suitable wallet linked for this account")
		}
	}

	execute {
		self.bidsReference.increaseBid(name: leaseName, increaseBy: amount)
	}

}


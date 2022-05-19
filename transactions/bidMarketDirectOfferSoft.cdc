import FindMarketTenant from "../contracts/FindMarketTenant.cdc"
import FindMarketDirectOfferSoft from "../contracts/FindMarketDirectOfferSoft.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FindViews from "../contracts/FindViews.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import NFTRegistry from "../contracts/NFTRegistry.cdc"
import FIND from "../contracts/FIND.cdc"

transaction(user: String, nftAlias: String, id: UInt64, ftAlias:String, amount: UFix64) {

	let targetCapability : Capability<&{NonFungibleToken.Receiver}>
	let walletReference : &FungibleToken.Vault
	let bidsReference: &FindMarketDirectOfferSoft.MarketBidCollection?
	let balanceBeforeBid: UFix64
	let pointer: FindViews.ViewReadPointer
	let ftVaultType: Type

	prepare(account: AuthAccount) {
		
		let resolveAddress = FIND.resolve(user)
		if resolveAddress == nil {panic("The address input is not a valid name nor address. Input : ".concat(user))}
		let address = resolveAddress!

		let nft = NFTRegistry.getNFTInfoByAlias(nftAlias) ?? panic("This NFT is not supported by the Find Market yet")
		let ft = FTRegistry.getFTInfoByAlias(ftAlias) ?? panic("This FT is not supported by the Find Market yet")

		self.ftVaultType = ft.type

		self.targetCapability= account.getCapability<&{NonFungibleToken.Receiver}>(nft.publicPath)
		self.walletReference = account.borrow<&FungibleToken.Vault>(from: ft.vaultPath) ?? panic("No suitable wallet linked for this account")

		let tenant=FindMarketTenant.getFindTenantCapability().borrow() ?? panic("Cannot borrow reference to tenant")
		let storagePath=tenant.getStoragePath(Type<@FindMarketDirectOfferSoft.MarketBidCollection>())!
		self.bidsReference= account.borrow<&FindMarketDirectOfferSoft.MarketBidCollection>(from: storagePath)
		self.balanceBeforeBid=self.walletReference.balance
		self.pointer= FindViews.createViewReadPointer(address: address, path:nft.publicPath, id: id)
	}

	pre {
		self.bidsReference != nil : "This account does not have a bid collection"
		self.walletReference.balance > amount : "Your wallet does not have enough funds to pay for this item"
		self.targetCapability.check() : "The target collection for the item your are bidding on does not exist"
	}

	execute {
		self.bidsReference!.bid(item:self.pointer, amount: amount, vaultType: self.ftVaultType, nftCap: self.targetCapability)
	}
}

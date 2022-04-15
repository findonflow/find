import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketDirectOfferEscrow from "../contracts/FindMarketDirectOfferEscrow.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FindViews from "../contracts/FindViews.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import NFTRegistry from "../contracts/NFTRegistry.cdc"

transaction(address: Address, nftAlias: String, id: UInt64, ftAlias:String, amount: UFix64) {

	let targetCapability : Capability<&{NonFungibleToken.Receiver}>
	let walletReference : &FungibleToken.Vault
	let bidsReference: &FindMarketDirectOfferEscrow.MarketBidCollection?
	let balanceBeforeBid: UFix64
	let pointer: FindViews.ViewReadPointer

	prepare(account: AuthAccount) {

		let nft = NFTRegistry.getNFTInfoByAlias(nftAlias) ?? panic("This NFT is not supported by the Find Market yet")
		let ft = FTRegistry.getFTInfoByAlias(ftAlias) ?? panic("This FT is not supported by the Find Market yet")
		
		self.targetCapability= account.getCapability<&{NonFungibleToken.Receiver}>(nft.publicPath)
		self.walletReference = account.borrow<&FungibleToken.Vault>(from: ft.vaultPath) ?? panic("No suitable wallet linked for this account")

		let tenant=FindMarket.getFindTenant()
		let storagePath=tenant.getStoragePath(Type<@FindMarketDirectOfferEscrow.MarketBidCollection>())!

		self.bidsReference= account.borrow<&FindMarketDirectOfferEscrow.MarketBidCollection>(from: storagePath)
		self.balanceBeforeBid=self.walletReference.balance
		self.pointer= FindViews.createViewReadPointer(address: address, path:nft.publicPath, id: id)
	}

	pre {
		self.bidsReference != nil : "This account does not have a bid collection"
		self.walletReference.balance > amount : "Your wallet does not have enough funds to pay for this item"
		self.targetCapability.check() : "The target collection for the item your are bidding on does not exist"
	}

	execute {
		let vault <- self.walletReference.withdraw(amount: amount) 
		self.bidsReference!.bid(item:self.pointer, vault: <- vault, nftCap: self.targetCapability)
	}

	post {
		self.walletReference.balance == self.balanceBeforeBid - amount
	}
}

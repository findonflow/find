import FindMarketAuctionEscrow from "../contracts/FindMarketAuctionEscrow.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FindViews from "../contracts/FindViews.cdc"
import NFTRegistry from "../contracts/NFTRegistry.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import FIND from "../contracts/FIND.cdc"

transaction(marketplace:Address, user: String, id: UInt64, amount: UFix64) {

	let saleItemsCap: Capability<&FindMarketAuctionEscrow.SaleItemCollection{FindMarketAuctionEscrow.SaleItemCollectionPublic}> 
	let targetCapability : Capability<&{NonFungibleToken.Receiver}>
	let walletReference : &FungibleToken.Vault
	let bidsReference: &FindMarketAuctionEscrow.MarketBidCollection?
	let balanceBeforeBid: UFix64
	let pointer: FindViews.ViewReadPointer

	prepare(account: AuthAccount) {

		let resolveAddress = FIND.resolve(user)
		if resolveAddress == nil {panic("The address input is not a valid name nor address. Input : ".concat(user))}
		let address = resolveAddress!

		self.saleItemsCap= FindMarketAuctionEscrow.getSaleItemCapability(marketplace:marketplace, user:address) ?? panic("cannot find sale item cap")

		let marketOption = FindMarket.getMarketOptionFromType(Type<@FindMarketAuctionEscrow.SaleItemCollection>())
		let item = FindMarket.assertOperationValid(tenant: marketplace, address: address, marketOption: marketOption, id: id)

		let nft = NFTRegistry.getNFTInfoByTypeIdentifier(item.getItemType().identifier) ?? panic("This NFT is not supported by the Find Market yet ")
		let ft = FTRegistry.getFTInfoByTypeIdentifier(item.getFtType().identifier) ?? panic("This FT is not supported by the Find Market yet")
	
		self.targetCapability= account.getCapability<&{NonFungibleToken.Receiver}>(nft.publicPath)
		self.walletReference = account.borrow<&FungibleToken.Vault>(from: ft.vaultPath) ?? panic("No suitable wallet linked for this account")

		let tenant=FindMarket.getTenant(marketplace)
		let storagePath=tenant.getStoragePath(Type<@FindMarketAuctionEscrow.MarketBidCollection>())!

		self.bidsReference= account.borrow<&FindMarketAuctionEscrow.MarketBidCollection>(from: storagePath)
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
		self.bidsReference!.bid(item:self.pointer, vault: <- vault, nftCap: self.targetCapability, bidExtraField: {})
	}

}

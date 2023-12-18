import FindMarketAuctionEscrow from "../contracts/FindMarketAuctionEscrow.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindViews from "../contracts/FindViews.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import FIND from "../contracts/FIND.cdc"
import Profile from "../contracts/Profile.cdc"

transaction(user: String, id: UInt64, amount: UFix64) {

	let saleItemsCap: Capability<&FindMarketAuctionEscrow.SaleItemCollection{FindMarketAuctionEscrow.SaleItemCollectionPublic}>
	var targetCapability : Capability<&{NonFungibleToken.Receiver}>
	let walletReference : &FungibleToken.Vault
	let bidsReference: &FindMarketAuctionEscrow.MarketBidCollection?
	let balanceBeforeBid: UFix64
	let pointer: FindViews.ViewReadPointer

	prepare(account: AuthAccount) {
		let marketplace = FindMarket.getFindTenantAddress()
		let resolveAddress = FIND.resolve(user)
		if resolveAddress == nil {panic("The address input is not a valid name nor address. Input : ".concat(user))}
		let address = resolveAddress!

		let tenantCapability= FindMarket.getTenantCapability(marketplace)!
		let tenant = tenantCapability.borrow()!
		let receiverCap=account.getCapability<&{FungibleToken.Receiver}>(Profile.publicReceiverPath)
		/// auctions that escrow ft
		let aeBidType= Type<@FindMarketAuctionEscrow.MarketBidCollection>()

		let aeBidPublicPath=FindMarket.getPublicPath(aeBidType, name: tenant.name)
		let aeBidStoragePath= FindMarket.getStoragePath(aeBidType, name:tenant.name)
		let aeBidCap= account.getCapability<&FindMarketAuctionEscrow.MarketBidCollection{FindMarketAuctionEscrow.MarketBidCollectionPublic, FindMarket.MarketBidCollectionPublic}>(aeBidPublicPath)
		if !aeBidCap.check() {
			account.save<@FindMarketAuctionEscrow.MarketBidCollection>(<- FindMarketAuctionEscrow.createEmptyMarketBidCollection(receiver:receiverCap, tenantCapability:tenantCapability), to: aeBidStoragePath)
			account.link<&FindMarketAuctionEscrow.MarketBidCollection{FindMarketAuctionEscrow.MarketBidCollectionPublic, FindMarket.MarketBidCollectionPublic}>(aeBidPublicPath, target: aeBidStoragePath)
		}

		self.saleItemsCap= FindMarketAuctionEscrow.getSaleItemCapability(marketplace:marketplace, user:address) ?? panic("cannot find sale item cap. User address : ".concat(address.toString()))

		let marketOption = FindMarket.getMarketOptionFromType(Type<@FindMarketAuctionEscrow.SaleItemCollection>())
		let item = FindMarket.assertOperationValid(tenant: marketplace, address: address, marketOption: marketOption, id: id)

		let nftIdentifier = item.getItemType().identifier
		let collectionIdentifier = FINDNFTCatalog.getCollectionsForType(nftTypeIdentifier: nftIdentifier)?.keys ?? panic("This NFT is not supported by the NFT Catalog yet. Type : ".concat(nftIdentifier))
		let collection = FINDNFTCatalog.getCatalogEntry(collectionIdentifier : collectionIdentifier[0])!
		let nft = collection.collectionData

		let ft = FTRegistry.getFTInfoByTypeIdentifier(item.getFtType().identifier) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(item.getFtType().identifier))

		self.targetCapability= account.getCapability<&{NonFungibleToken.Receiver}>(nft.publicPath)
		/* Check for nftCapability */
		if !self.targetCapability.check() {
			let cd = item.getNFTCollectionData()
			// should use account.type here instead
			if account.type(at: cd.storagePath) != nil {
				let pathIdentifier = nft.publicPath.toString()
				let findPath = PublicPath(identifier: pathIdentifier.slice(from: "/public/".length , upTo: pathIdentifier.length).concat("_FIND"))!
				account.link<&{NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(
					findPath,
					target: nft.storagePath
				)
				self.targetCapability = account.getCapability<&{NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(findPath)
			} else {
				account.save(<- cd.createEmptyCollection(), to: cd.storagePath)
				account.link<&{NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(cd.publicPath, target: cd.storagePath)
				account.link<&{NonFungibleToken.Provider, NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(cd.providerPath, target: cd.storagePath)
			}

		}

		self.walletReference = account.borrow<&FungibleToken.Vault>(from: ft.vaultPath) ?? panic("No suitable wallet linked for this account")

		let bidSstoragePath=tenant.getStoragePath(Type<@FindMarketAuctionEscrow.MarketBidCollection>())

		self.bidsReference= account.borrow<&FindMarketAuctionEscrow.MarketBidCollection>(from: bidSstoragePath)
		self.balanceBeforeBid=self.walletReference.balance
		self.pointer= FindViews.createViewReadPointer(address: address, path:nft.publicPath, id: item.getItemID())
	}

	pre {
		self.bidsReference != nil : "This account does not have a bid collection"
		self.walletReference.balance > amount : "Your wallet does not have enough funds to pay for this item"
	}

	execute {
		let vault <- self.walletReference.withdraw(amount: amount)
		self.bidsReference!.bid(item:self.pointer, vault: <- vault, nftCap: self.targetCapability, bidExtraField: {})
	}

}

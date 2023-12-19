import Profile from "../contracts/Profile.cdc"
import FindMarketDirectOfferSoft from "../contracts/FindMarketDirectOfferSoft.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindViews from "../contracts/FindViews.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FIND from "../contracts/FIND.cdc"

transaction(user: String, nftAliasOrIdentifier: String, id: UInt64, ftAliasOrIdentifier: String, amount: UFix64, validUntil: UFix64?) {

	var targetCapability : Capability<&{NonFungibleToken.Receiver}>
	let bidsReference: &FindMarketDirectOfferSoft.MarketBidCollection?
	let pointer: FindViews.ViewReadPointer
	let ftVaultType: Type

	prepare(account: auth(BorrowValue) &Account) {

		let marketplace = FindMarket.getFindTenantAddress()
		let resolveAddress = FIND.resolve(user)
		if resolveAddress == nil {panic("The address input is not a valid name nor address. Input : ".concat(user))}
		let address = resolveAddress!

		let collectionIdentifier = FINDNFTCatalog.getCollectionsForType(nftTypeIdentifier: nftAliasOrIdentifier)?.keys ?? panic("This NFT is not supported by the NFT Catalog yet. Type : ".concat(nftAliasOrIdentifier))
		let collection = FINDNFTCatalog.getCatalogEntry(collectionIdentifier : collectionIdentifier[0])!
		let nft = collection.collectionData

		let ft = FTRegistry.getFTInfo(ftAliasOrIdentifier) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(ftAliasOrIdentifier))

		self.ftVaultType = ft.type

		self.targetCapability= account.getCapability<&{NonFungibleToken.Receiver}>(nft.publicPath)

		let tenantCapability= FindMarket.getTenantCapability(marketplace)!
		let tenant = tenantCapability.borrow()!

		let receiverCap=account.getCapability<&{FungibleToken.Receiver}>(Profile.publicReceiverPath)
		let dosBidType= Type<@FindMarketDirectOfferSoft.MarketBidCollection>()
		let dosBidPublicPath=FindMarket.getPublicPath(dosBidType, name: tenant.name)
		let dosBidStoragePath= FindMarket.getStoragePath(dosBidType, name:tenant.name)
		let dosBidCap= account.getCapability<&FindMarketDirectOfferSoft.MarketBidCollection{FindMarketDirectOfferSoft.MarketBidCollectionPublic, FindMarket.MarketBidCollectionPublic}>(dosBidPublicPath)
		if !dosBidCap.check() {
			account.storage.save<@FindMarketDirectOfferSoft.MarketBidCollection>(<- FindMarketDirectOfferSoft.createEmptyMarketBidCollection(receiver:receiverCap, tenantCapability:tenantCapability), to: dosBidStoragePath)
			account.link<&FindMarketDirectOfferSoft.MarketBidCollection{FindMarketDirectOfferSoft.MarketBidCollectionPublic, FindMarket.MarketBidCollectionPublic}>(dosBidPublicPath, target: dosBidStoragePath)
		}

		self.bidsReference= account.storage.borrow<&FindMarketDirectOfferSoft.MarketBidCollection>(from: dosBidStoragePath)
		self.pointer= FindViews.createViewReadPointer(address: address, path:nft.publicPath, id: id)

		/* Check for nftCapability */
		if !self.targetCapability.check() {
			let cd = self.pointer.getNFTCollectionData()
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
				account.storage.save(<- cd.createEmptyCollection(), to: cd.storagePath)
				account.link<&{NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(cd.publicPath, target: cd.storagePath)
				account.link<&{NonFungibleToken.Provider, NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(cd.providerPath, target: cd.storagePath)
			}

		}
	}

	pre {
		self.bidsReference != nil : "This account does not have a bid collection"
	}

	execute {
		self.bidsReference!.bid(item:self.pointer, amount: amount, vaultType: self.ftVaultType, nftCap: self.targetCapability, validUntil: validUntil, saleItemExtraField: {}, bidExtraField: {})
	}
}

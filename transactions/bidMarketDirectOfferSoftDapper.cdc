import "Profile"
import "FindMarketDirectOfferSoft"
import "FindMarket"
import "FungibleToken"
import "NonFungibleToken"
import "MetadataViews"
import "FindViews"
import "FINDNFTCatalog"
import "FTRegistry"
import "FIND"

transaction(user: String, nftAliasOrIdentifier: String, id: UInt64, ftAliasOrIdentifier: String, amount: UFix64, validUntil: UFix64?) {

	var targetCapability : Capability<&{NonFungibleToken.Receiver}>
	let bidsReference: &FindMarketDirectOfferSoft.MarketBidCollection?
	let pointer: FindViews.ViewReadPointer
	let ftVaultType: Type

	prepare(account: auth(StorageCapabilities, SaveValue,PublishCapability, BorrowValue, UnpublishCapability) &Account) {

		let marketplace = FindMarket.getFindTenantAddress()
		let resolveAddress = FIND.resolve(user)
		if resolveAddress == nil {panic("The address input is not a valid name nor address. Input : ".concat(user))}
		let address = resolveAddress!

		let collectionIdentifier = FINDNFTCatalog.getCollectionsForType(nftTypeIdentifier: nftAliasOrIdentifier)?.keys ?? panic("This NFT is not supported by the NFT Catalog yet. Type : ".concat(nftAliasOrIdentifier))
		let collection = FINDNFTCatalog.getCatalogEntry(collectionIdentifier : collectionIdentifier[0])!
		let nft = collection.collectionData

		let ft = FTRegistry.getFTInfo(ftAliasOrIdentifier) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(ftAliasOrIdentifier))

		self.ftVaultType = ft.type

		let tenantCapability= FindMarket.getTenantCapability(marketplace)!
		let tenant = tenantCapability.borrow()!

		let receiverCap=account.capabilities.get<&{FungibleToken.Receiver}>(Profile.publicReceiverPath)!
		let dosBidType= Type<@FindMarketDirectOfferSoft.MarketBidCollection>()
		let dosBidPublicPath=FindMarket.getPublicPath(dosBidType, name: tenant.name)
		let dosBidStoragePath= FindMarket.getStoragePath(dosBidType, name:tenant.name)
		let dosBidCap= account.capabilities.get<&FindMarketDirectOfferSoft.MarketBidCollection>(dosBidPublicPath)
		if dosBidCap == nil {
			account.storage.save<@FindMarketDirectOfferSoft.MarketBidCollection>(<- FindMarketDirectOfferSoft.createEmptyMarketBidCollection(receiver:receiverCap, tenantCapability:tenantCapability), to: dosBidStoragePath)
			let cap = account.capabilities.storage.issue<&FindMarketDirectOfferSoft.MarketBidCollection>(dosBidStoragePath)
			account.capabilities.publish(cap, at: dosBidPublicPath)
		}

		self.bidsReference= account.storage.borrow<&FindMarketDirectOfferSoft.MarketBidCollection>(from: dosBidStoragePath)
		self.pointer= FindViews.createViewReadPointer(address: address, path:nft.publicPath, id: id)

		let col= account.storage.borrow<&AnyResource>(from: nft.storagePath) as? &{NonFungibleToken.Collection}?
		if col == nil {
			let cd = self.pointer.getNFTCollectionData()
			account.storage.save(<- cd.createEmptyCollection(), to: cd.storagePath)
			account.capabilities.unpublish(cd.publicPath)
			let cap = account.capabilities.storage.issue<&{NonFungibleToken.Collection}>(cd.storagePath)
			account.capabilities.publish(cap, at: cd.publicPath)
			self.targetCapability=cap
		} else {
			//TODO: I do not think this works as intended
			var targetCapability= account.capabilities.get<&AnyResource>(nft.publicPath) as? Capability<&{NonFungibleToken.Collection}>
			if targetCapability == nil || !targetCapability!.check() {
				let cd = self.pointer.getNFTCollectionData()
				let cap = account.capabilities.storage.issue<&{NonFungibleToken.Collection}>(cd.storagePath)
				account.capabilities.unpublish(cd.publicPath)
				account.capabilities.publish(cap, at: cd.publicPath)
				targetCapability= account.capabilities.get<&{NonFungibleToken.Collection}>(nft.publicPath)
		}
			self.targetCapability=targetCapability!
		}
	}

	pre {
		self.bidsReference != nil : "This account does not have a bid collection"
	}

	execute {
		self.bidsReference!.bid(item:self.pointer, amount: amount, vaultType: self.ftVaultType, nftCap: self.targetCapability, validUntil: validUntil, saleItemExtraField: {}, bidExtraField: {})
	}
}

import "FindMarketDirectOfferEscrow"
import "NonFungibleToken"
import "MetadataViews"
import "FindViews"
import "NFTCatalog"
import "FINDNFTCatalog"
import "FindMarket"
import "ViewResolver"

transaction(id: UInt64) {

	let market : auth(FindMarketDirectOfferEscrow.Seller) &FindMarketDirectOfferEscrow.SaleItemCollection?
	let pointer : FindViews.AuthNFTPointer

	prepare(account: auth(BorrowValue, IssueStorageCapabilityController, PublishCapability, SaveValue) &Account) {

		let marketplace = FindMarket.getFindTenantAddress()
		let tenant=FindMarket.getTenant(marketplace)
		let storagePath=tenant.getStoragePath(Type<@FindMarketDirectOfferEscrow.SaleItemCollection>())
		let marketOption = FindMarket.getMarketOptionFromType(Type<@FindMarketDirectOfferEscrow.SaleItemCollection>())

		let item = FindMarket.assertOperationValid(tenant: marketplace, address: account.address, marketOption: marketOption, id: id)

		let nftIdentifier = item.getItemType().identifier
		let collectionIdentifier = FINDNFTCatalog.getCollectionsForType(nftTypeIdentifier: nftIdentifier)?.keys ?? panic("This NFT is not supported by the NFT Catalog yet. Type : ".concat(nftIdentifier))
		let collection = FINDNFTCatalog.getCatalogEntry(collectionIdentifier : collectionIdentifier[0])!
		let nft = collection.collectionData


		var providerCap=account.capabilities.storage.issue<auth(NonFungibleToken.Withdraw) &{NonFungibleToken.Provider, ViewResolver.ResolverCollection, NonFungibleToken.Collection}>(nft.storagePath)

		/* Ben : Question -> Either client will have to provide the path here or agree that we set it up for the user */
		if providerCap == nil  {
				// If linking is not successful, we link it using finds custom link
				let pathIdentifier = nft.storagePath.toString()
				let findPath: StoragePath = StoragePath(identifier: pathIdentifier.slice(from: "/storage/".length , upTo: pathIdentifier.length).concat("_FIND"))!
				providerCap = account.capabilities.storage.issue<auth(NonFungibleToken.Withdraw) &{NonFungibleToken.Provider, ViewResolver.ResolverCollection, NonFungibleToken.Collection}>(findPath)
		}

		self.pointer= FindViews.AuthNFTPointer(cap: providerCap, id: item.getItemID())
		self.market = account.storage.borrow<auth(FindMarketDirectOfferEscrow.Seller) &FindMarketDirectOfferEscrow.SaleItemCollection>(from: storagePath)

	}

	pre{
		self.market != nil : "Cannot borrow reference to saleItem"
	}

	execute{
		self.market!.acceptDirectOffer(self.pointer)
	}
}

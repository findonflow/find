import "FindMarketDirectOfferEscrow"
import "NonFungibleToken"
import "MetadataViews"
import "FindViews"
import "NFTCatalog"
import "FINDNFTCatalog"
import "FindMarket"

transaction(ids: [UInt64]) {

	let market : &FindMarketDirectOfferEscrow.SaleItemCollection?
	let pointer : [FindViews.AuthNFTPointer]

	prepare(account: auth(BorrowValue, IssueStorageCapabilityController, PublishCapability, SaveValue) &Account) {

		let marketplace = FindMarket.getFindTenantAddress()
		let tenant=FindMarket.getTenant(marketplace)
		let storagePath=tenant.getStoragePath(Type<@FindMarketDirectOfferEscrow.SaleItemCollection>())
		let marketOption = FindMarket.getMarketOptionFromType(Type<@FindMarketDirectOfferEscrow.SaleItemCollection>())
		self.market = account.storage.borrow<&FindMarketDirectOfferEscrow.SaleItemCollection>(from: storagePath)
		self.pointer = []

		let nfts : {String : NFTCatalog.NFTCollectionData} = {}
		var counter = 0
		while counter < ids.length {
			let item = FindMarket.assertOperationValid(tenant: marketplace, address: account.address, marketOption: marketOption, id: ids[counter])

			var nft : NFTCatalog.NFTCollectionData? = nil
			let nftIdentifier = item.getItemType().identifier

			if nfts[nftIdentifier] != nil {
				nft = nfts[nftIdentifier]
			} else {
				let collectionIdentifier = FINDNFTCatalog.getCollectionsForType(nftTypeIdentifier: nftIdentifier)?.keys ?? panic("This NFT is not supported by the NFT Catalog yet. Type : ".concat(nftIdentifier))
				let collection = FINDNFTCatalog.getCatalogEntry(collectionIdentifier : collectionIdentifier[0])!
				nft = collection.collectionData
				nfts[nftIdentifier] = nft
			}


			var providerCap=account.capabilities.storage.issue<auth(NonFungibleToken.Withdraw) &{NonFungibleToken.Provider, ViewResolver.ResolverCollection, NonFungibleToken.Collection}>(nft.storagePath)

			/* Ben : Question -> Either client will have to provide the path here or agree that we set it up for the user */
			if providerCap == nil  {
					// If linking is not successful, we link it using finds custom link
					let pathIdentifier = nft!.storagePath.toString()
					let findPath: StoragePath = StoragePath(identifier: pathIdentifier.slice(from: "/storage/".length , upTo: pathIdentifier.length).concat("_FIND"))!
					providerCap = account.capabilities.storage.issue<auth(NonFungibleToken.Withdraw) &{NonFungibleToken.Provider, ViewResolver.ResolverCollection, NonFungibleToken.Collection}>(findPath)
			}

			let pointer= FindViews.AuthNFTPointer(cap: providerCap, id: item.getItemID())
			self.pointer.append(pointer)
			counter = counter + 1
		}

	}

	pre{
		self.market != nil : "Cannot borrow reference to saleItem"
	}

	execute{
		var counter = 0
		while counter < ids.length {
			self.market!.acceptDirectOffer(self.pointer[counter])
			counter = counter + 1
		}
	}
}

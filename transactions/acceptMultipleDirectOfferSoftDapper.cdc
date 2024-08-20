import "FindMarketDirectOfferSoft"
import "NonFungibleToken"
import "MetadataViews"
import "FindViews"
import "NFTCatalog"
import "FINDNFTCatalog"
import "FindMarket"
import "FungibleToken"

transaction(ids: [UInt64]) {

	let market : &FindMarketDirectOfferSoft.SaleItemCollection
	let pointer : [FindViews.AuthNFTPointer]

	prepare(account: auth(BorrowValue) &Account) {

		let marketplace = FindMarket.getFindTenantAddress()
		let tenant=FindMarket.getTenant(marketplace)
		let storagePath=tenant.getStoragePath(Type<@FindMarketDirectOfferSoft.SaleItemCollection>())
		self.market = account.storage.borrow<&FindMarketDirectOfferSoft.SaleItemCollection>(from: storagePath)!
		let marketOption = FindMarket.getMarketOptionFromType(Type<@FindMarketDirectOfferSoft.SaleItemCollection>())

		var counter = 0
		self.pointer = []
		let nfts : {String : NFTCatalog.NFTCollectionData} = {}

		while counter < ids.length {
			let item = FindMarket.assertOperationValid(tenant: marketplace, address: account.address, marketOption: marketOption, id: ids[counter])
			var nft : NFTCatalog.NFTCollectionData? = nil
			let nftIdentifier = item.getItemType().identifier
			let ftType = item.getFtType()

			if nfts[nftIdentifier] != nil {
				nft = nfts[nftIdentifier]
			} else {
				// nft = getCollectionData(nftIdentifier)
				let collectionIdentifier = FINDNFTCatalog.getCollectionsForType(nftTypeIdentifier: nftIdentifier)?.keys ?? panic("This NFT is not supported by the NFT Catalog yet. Type : ".concat(nftIdentifier))
				let collection = FINDNFTCatalog.getCatalogEntry(collectionIdentifier : collectionIdentifier[0])!
				nft = collection.collectionData
				nfts[nftIdentifier] = nft
			}

			let providerCap=account.getCapability<&{NonFungibleToken.Provider, ViewResolver.ResolverCollection, NonFungibleToken.Collection}>(nft!.privatePath)
			let pointer= FindViews.AuthNFTPointer(cap: providerCap, id: item.getItemID())
			self.pointer.append(pointer)
			counter = counter + 1
		}

	}

	execute {
		var counter = 0
		while counter < ids.length {
			self.market.acceptOffer(self.pointer[counter])
			counter = counter + 1
		}
	}

}

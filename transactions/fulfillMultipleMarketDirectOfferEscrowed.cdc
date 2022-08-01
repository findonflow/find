import FindMarketDirectOfferEscrow from "../contracts/FindMarketDirectOfferEscrow.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindViews from "../contracts/FindViews.cdc"
import NFTCatalog from "../contracts/standard/NFTCatalog.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
import FindMarket from "../contracts/FindMarket.cdc"

transaction(marketplace:Address, ids: [UInt64]) {

	let market : &FindMarketDirectOfferEscrow.SaleItemCollection?
	let pointer : [FindViews.AuthNFTPointer]

	prepare(account: AuthAccount) {

		let tenant=FindMarket.getTenant(marketplace)
		let storagePath=tenant.getStoragePath(Type<@FindMarketDirectOfferEscrow.SaleItemCollection>())
		let marketOption = FindMarket.getMarketOptionFromType(Type<@FindMarketDirectOfferEscrow.SaleItemCollection>())
		self.market = account.borrow<&FindMarketDirectOfferEscrow.SaleItemCollection>(from: storagePath)
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
				nft = getCollectionData(nftIdentifier) 
				nfts[nftIdentifier] = nft
			}
		
			let providerCap=account.getCapability<&{NonFungibleToken.Provider, MetadataViews.ResolverCollection, NonFungibleToken.CollectionPublic}>(nft!.privatePath)

			/* Ben : Question -> Either client will have to provide the path here or agree that we set it up for the user */
			if !providerCap.check() {
					account.link<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
						nft!.privatePath,
						target: nft!.storagePath
				)
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

pub fun getCollectionData(_ nftIdentifier: String) : NFTCatalog.NFTCollectionData {
	let collectionIdentifier = FINDNFTCatalog.getCollectionsForType(nftTypeIdentifier: nftIdentifier)?.keys ?? panic("This NFT is not supported by the NFT Catalog yet. Type : ".concat(nftIdentifier)) 
	let collection = FINDNFTCatalog.getCatalogEntry(collectionIdentifier : collectionIdentifier[0])! 
	return collection.collectionData
}
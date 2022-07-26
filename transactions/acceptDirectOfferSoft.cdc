import FindMarketDirectOfferSoft from "../contracts/FindMarketDirectOfferSoft.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindViews from "../contracts/FindViews.cdc"
import NFTCatalog from "../contracts/NFTCatalog.cdc"
import FindMarket from "../contracts/FindMarket.cdc"

transaction(marketplace:Address, id: UInt64) {

	let market : &FindMarketDirectOfferSoft.SaleItemCollection
	let pointer : FindViews.AuthNFTPointer

	prepare(account: AuthAccount) {
		let tenant=FindMarket.getTenant(marketplace)
		let storagePath=tenant.getStoragePath(Type<@FindMarketDirectOfferSoft.SaleItemCollection>())
		self.market = account.borrow<&FindMarketDirectOfferSoft.SaleItemCollection>(from: storagePath)!
		let marketOption = FindMarket.getMarketOptionFromType(Type<@FindMarketDirectOfferSoft.SaleItemCollection>())
		let item = FindMarket.assertOperationValid(tenant: marketplace, address: account.address, marketOption: marketOption, id: id)
		let nftIdentifier = item.getItemType().identifier

		//If this is nil, there must be something wrong with FIND setup
		let privatePath = getPrivatePath(nftIdentifier)

		let providerCap=account.getCapability<&{NonFungibleToken.Provider, MetadataViews.ResolverCollection, NonFungibleToken.CollectionPublic}>(privatePath)
		self.pointer= FindViews.AuthNFTPointer(cap: providerCap, id: item.getItemID())
	}

	execute {
		self.market.acceptOffer(self.pointer)
	}
}

pub fun getPrivatePath(_ nftIdentifier: String) : PrivatePath {
	let collectionIdentifier = NFTCatalog.getCollectionsForType(nftTypeIdentifier: nftIdentifier)?.keys ?? panic("This NFT is not supported by the NFT Catalog yet. Type : ".concat(nftIdentifier)) 
	let collection = NFTCatalog.getCatalogEntry(collectionIdentifier : collectionIdentifier[0])! 
	return collection.collectionData.privatePath
}
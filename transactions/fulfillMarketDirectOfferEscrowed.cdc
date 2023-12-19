import FindMarketDirectOfferEscrow from "../contracts/FindMarketDirectOfferEscrow.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindViews from "../contracts/FindViews.cdc"
import NFTCatalog from "../contracts/standard/NFTCatalog.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
import FindMarket from "../contracts/FindMarket.cdc"

transaction(id: UInt64) {

	let market : &FindMarketDirectOfferEscrow.SaleItemCollection?
	let pointer : FindViews.AuthNFTPointer

	prepare(account: auth(BorrowValue) &Account) {

		let marketplace = FindMarket.getFindTenantAddress()
		let tenant=FindMarket.getTenant(marketplace)
		let storagePath=tenant.getStoragePath(Type<@FindMarketDirectOfferEscrow.SaleItemCollection>())
		let marketOption = FindMarket.getMarketOptionFromType(Type<@FindMarketDirectOfferEscrow.SaleItemCollection>())

		let item = FindMarket.assertOperationValid(tenant: marketplace, address: account.address, marketOption: marketOption, id: id)

		let nftIdentifier = item.getItemType().identifier
		let collectionIdentifier = FINDNFTCatalog.getCollectionsForType(nftTypeIdentifier: nftIdentifier)?.keys ?? panic("This NFT is not supported by the NFT Catalog yet. Type : ".concat(nftIdentifier))
		let collection = FINDNFTCatalog.getCatalogEntry(collectionIdentifier : collectionIdentifier[0])!
		let nft = collection.collectionData


		var providerCap=account.getCapability<&{NonFungibleToken.Provider, ViewResolver.ResolverCollection, NonFungibleToken.Collection}>(nft.privatePath)

		/* Ben : Question -> Either client will have to provide the path here or agree that we set it up for the user */
		if !providerCap.check() {
			let newCap = account.link<&{NonFungibleToken.Provider, NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(
					nft.privatePath,
					target: nft.storagePath
			)
			if newCap == nil {
				// If linking is not successful, we link it using finds custom link
				let pathIdentifier = nft.privatePath.toString()
				let findPath = PrivatePath(identifier: pathIdentifier.slice(from: "/private/".length , upTo: pathIdentifier.length).concat("_FIND"))!
				account.link<&{NonFungibleToken.Provider, NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(
					findPath,
					target: nft.storagePath
				)
				providerCap = account.getCapability<&{NonFungibleToken.Provider, NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(findPath)
			}
		}

		self.pointer= FindViews.AuthNFTPointer(cap: providerCap, id: item.getItemID())
		self.market = account.storage.borrow<&FindMarketDirectOfferEscrow.SaleItemCollection>(from: storagePath)

	}

	pre{
		self.market != nil : "Cannot borrow reference to saleItem"
	}

	execute{
		self.market!.acceptDirectOffer(self.pointer)
	}
}

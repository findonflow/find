import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketSale from "../contracts/FindMarketSale.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindViews from "../contracts/FindViews.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"

transaction(nftAliasOrIdentifier: String, id: UInt64, ftAliasOrIdentifier: String, directSellPrice:UFix64, validUntil: UFix64?) {

	let saleItems : &FindMarketSale.SaleItemCollection?
	let pointer : FindViews.AuthNFTPointer
	let vaultType : Type

	prepare(account: auth(BorrowValue) &Account) {

		let marketplace = FindMarket.getFindTenantAddress()
		let tenantCapability= FindMarket.getTenantCapability(marketplace)!
		let saleItemType= Type<@FindMarketSale.SaleItemCollection>()

		let tenant = tenantCapability.borrow()!
		let publicPath=FindMarket.getPublicPath(saleItemType, name: tenant.name)
		let storagePath= FindMarket.getStoragePath(saleItemType, name:tenant.name)

		let saleItemCap= account.getCapability<&FindMarketSale.SaleItemCollection{FindMarketSale.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(publicPath)
		if !saleItemCap.check() {
			//The link here has to be a capability not a tenant, because it can change.
			account.storage.save<@FindMarketSale.SaleItemCollection>(<- FindMarketSale.createEmptySaleItemCollection(tenantCapability), to: storagePath)
			account.link<&FindMarketSale.SaleItemCollection{FindMarketSale.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(publicPath, target: storagePath)
		}
		// Get supported NFT and FT Information from Registries from input alias
		let collectionIdentifier = FINDNFTCatalog.getCollectionsForType(nftTypeIdentifier:nftAliasOrIdentifier)?.keys ?? panic("This NFT is not supported by the NFT Catalog yet. Type : ".concat(nftAliasOrIdentifier))
		let collection = FINDNFTCatalog.getCatalogEntry(collectionIdentifier : collectionIdentifier[0])!
		let nft = collection.collectionData

		let ft = FTRegistry.getFTInfo(ftAliasOrIdentifier) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(ftAliasOrIdentifier))

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
		// Get the salesItemRef from tenant
		self.saleItems= account.storage.borrow<&FindMarketSale.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketSale.SaleItemCollection>()))
		self.pointer= FindViews.AuthNFTPointer(cap: providerCap, id: id)
		self.vaultType= ft.type
	}

	pre{
		self.saleItems != nil : "Cannot borrow reference to saleItem"
	}

	execute{
		self.saleItems!.listForSale(pointer: self.pointer, vaultType: self.vaultType, directSellPrice: directSellPrice, validUntil: validUntil, extraField: {})
	}
}

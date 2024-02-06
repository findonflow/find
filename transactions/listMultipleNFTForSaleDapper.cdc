import "FindMarket"
import "FindMarketSale"
import "NonFungibleToken"
import "MetadataViews"
import "FindViews"
import "NFTCatalog"
import "FINDNFTCatalog"
import "FTRegistry"

transaction(nftAliasOrIdentifiers: [String], ids: [UInt64], ftAliasOrIdentifiers: [String], directSellPrices:[UFix64], validUntil: UFix64?) {

	let saleItems : &FindMarketSale.SaleItemCollection?
	let pointers : [FindViews.AuthNFTPointer]
	let vaultTypes : [Type]

	prepare(account: auth(BorrowValue) &Account) {

		if nftAliasOrIdentifiers.length != ids.length {
			panic("The length of arrays passed in has to be the same")
		} else if nftAliasOrIdentifiers.length != directSellPrices.length {
			panic("The length of arrays passed in has to be the same")
		}

		let marketplace = FindMarket.getFindTenantAddress()
		let tenantCapability= FindMarket.getTenantCapability(marketplace)!
		let tenant = tenantCapability.borrow()!
		self.saleItems= account.storage.borrow<&FindMarketSale.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketSale.SaleItemCollection>()))
		self.pointers= []
		self.vaultTypes= []

		let saleItemType= Type<@FindMarketSale.SaleItemCollection>()
		let publicPath=FindMarket.getPublicPath(saleItemType, name: tenant.name)
		let storagePath= FindMarket.getStoragePath(saleItemType, name:tenant.name)

		let saleItemCap= account.getCapability<&FindMarketSale.SaleItemCollection{FindMarketSale.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(publicPath)
		if !saleItemCap.check() {
			//The link here has to be a capability not a tenant, because it can change.
			account.storage.save<@FindMarketSale.SaleItemCollection>(<- FindMarketSale.createEmptySaleItemCollection(tenantCapability), to: storagePath)
			account.link<&FindMarketSale.SaleItemCollection{FindMarketSale.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(publicPath, target: storagePath)
		}

		let nfts : {String : NFTCatalog.NFTCollectionData} = {}
		let fts : {String : FTRegistry.FTInfo} = {}

		var counter = 0
		while counter < ids.length {
			// Get supported NFT and FT Information from Registries from input alias
			var nft : NFTCatalog.NFTCollectionData? = nil

			if nfts[nftAliasOrIdentifiers[counter]] != nil {
				nft = nfts[nftAliasOrIdentifiers[counter]]
			} else {
				let collectionIdentifier = FINDNFTCatalog.getCollectionsForType(nftTypeIdentifier: nftAliasOrIdentifiers[counter])?.keys ?? panic("This NFT is not supported by the NFT Catalog yet. Type : ".concat(nftAliasOrIdentifiers[counter]))
				let collection = FINDNFTCatalog.getCatalogEntry(collectionIdentifier : collectionIdentifier[0])!
				nft = collection.collectionData
				nfts[nftAliasOrIdentifiers[counter]] = nft
			}

			if fts[ftAliasOrIdentifiers[counter]] != nil {
				let ft = fts[ftAliasOrIdentifiers[counter]]!
				self.vaultTypes.append(ft.type)
			} else {
				let ft = FTRegistry.getFTInfo(ftAliasOrIdentifiers[counter]) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(ftAliasOrIdentifiers[counter]))
				fts[ftAliasOrIdentifiers[counter]] = ft
				self.vaultTypes.append(ft.type)
			}



			var providerCap=account.getCapability<&{NonFungibleToken.Provider, ViewResolver.ResolverCollection, NonFungibleToken.Collection}>(nft!.privatePath)

			/* Ben : Question -> Either client will have to provide the path here or agree that we set it up for the user */
			if !providerCap.check() {
				let newCap = account.link<&{NonFungibleToken.Provider, NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(
						nft!.privatePath,
						target: nft!.storagePath
				)
				if newCap == nil {
					// If linking is not successful, we link it using finds custom link
					let pathIdentifier = nft!.privatePath.toString()
					let findPath = PrivatePath(identifier: pathIdentifier.slice(from: "/private/".length , upTo: pathIdentifier.length).concat("_FIND"))!
					account.link<&{NonFungibleToken.Provider, NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(
						findPath,
						target: nft!.storagePath
					)
					providerCap = account.getCapability<&{NonFungibleToken.Provider, NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(findPath)
				}
			}
			// Get the salesItemRef from tenant
			self.pointers.append(FindViews.AuthNFTPointer(cap: providerCap, id: ids[counter]))
			counter = counter + 1
		}

	}

	pre{
		self.saleItems != nil : "Cannot borrow reference to saleItem"
	}

	execute{
		var counter = 0
		while counter < ids.length {
			self.saleItems!.listForSale(pointer: self.pointers[counter], vaultType: self.vaultTypes[counter], directSellPrice: directSellPrices[counter], validUntil: validUntil, extraField: {})
			counter = counter + 1
		}
	}
}

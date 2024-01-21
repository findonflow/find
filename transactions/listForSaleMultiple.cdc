import FIND from "../contracts/FIND.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketSale from "../contracts/FindMarketSale.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindViews from "../contracts/FindViews.cdc"
import NFTCatalog from "../contracts/standard/NFTCatalog.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"

transaction(nftAliasOrIdentifiers: [String], ids: [AnyStruct], ftAliasOrIdentifiers: [String], directSellPrices:[UFix64], validUntil: UFix64?) {

	let saleItems : &FindMarketSale.SaleItemCollection?
	let pointers : [FindViews.AuthNFTPointer]
	let leaseNames : [String]
	let vaultTypes : [Type]
	let finLeases : auth(FIND.LeaseOwner) &FIND.LeaseCollection

	prepare(account: auth(BorrowValue) &Account) {

		let marketplace = FindMarket.getFindTenantAddress()
		let tenantCapability= FindMarket.getTenantCapability(marketplace)!
		let tenant = tenantCapability.borrow()!
		self.vaultTypes= []
		self.pointers= []
		self.leaseNames= []
		self.finLeases= account.storage.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath) ?? panic("Cannot borrow reference to find lease collection")

		let saleItemType= Type<@FindMarketSale.SaleItemCollection>()
		let publicPath=FindMarket.getPublicPath(saleItemType, name: tenant.name)
		let storagePath= FindMarket.getStoragePath(saleItemType, name:tenant.name)

		let saleItemCap= account.getCapability<&FindMarketSale.SaleItemCollection{FindMarketSale.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(publicPath)
		if !saleItemCap.check() {
			//The link here has to be a capability not a tenant, because it can change.
			account.storage.save<@FindMarketSale.SaleItemCollection>(<- FindMarketSale.createEmptySaleItemCollection(tenantCapability), to: storagePath)
			account.link<&FindMarketSale.SaleItemCollection{FindMarketSale.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(publicPath, target: storagePath)
		}
		self.saleItems= account.storage.borrow<&FindMarketSale.SaleItemCollection>(from: storagePath)!

		var counter = 0

		let nfts : {String : NFTCatalog.NFTCollectionData} = {}
		let fts : {String : FTRegistry.FTInfo} = {}

		while counter < ids.length {
			var ft : FTRegistry.FTInfo? = nil

			if fts[ftAliasOrIdentifiers[counter]] != nil {
				ft = fts[ftAliasOrIdentifiers[counter]]
			} else {
				ft = FTRegistry.getFTInfo(ftAliasOrIdentifiers[counter]) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(ftAliasOrIdentifiers[counter]))
				fts[ftAliasOrIdentifiers[counter]] = ft
			}

			if let name = ids[counter] as? String {
				if nftAliasOrIdentifiers[counter] != Type<@FIND.Lease>().identifier {
					panic("Lease does not match with identifiers")
				}
				if ftAliasOrIdentifiers[counter] != Type<@FUSD.Vault>().identifier {
					panic("Listing of leases only supports FUSD at the moment")
				}
				self.leaseNames.append(name)
			}

			if let id = ids[counter] as? UInt64 {
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
				self.pointers.append(FindViews.AuthNFTPointer(cap: providerCap, id: id))
			}

			self.vaultTypes.append(ft!.type)
			counter = counter + 1
		}
	}

	execute{
		var counter = 0
		var nameCounter = 0
		for identifier in nftAliasOrIdentifiers {
			let vc = counter + nameCounter
			if identifier == Type<@FIND.Lease>().identifier {
				self.finLeases.listForSale(name: self.leaseNames[nameCounter],  directSellPrice:directSellPrices[vc])
				nameCounter = nameCounter + 1
				continue
			}

			self.saleItems!.listForSale(pointer: self.pointers[counter], vaultType: self.vaultTypes[vc], directSellPrice: directSellPrices[vc], validUntil: validUntil, extraField: {})
			counter = counter + 1
		}
	}
}

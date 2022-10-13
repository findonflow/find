import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketSale from "../contracts/FindMarketSale.cdc"
import DapperUtilityCoin from "../contracts/standard/DapperUtilityCoin.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindViews from "../contracts/FindViews.cdc"
import NFTCatalog from "../contracts/standard/NFTCatalog.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"

transaction(dapperAddress: Address, marketplace:Address, nftAliasOrIdentifiers: [String], ids: [UInt64], directSellPrices:[UFix64], validUntil: UFix64?) {
	
	let saleItems : &FindMarketSale.SaleItemCollection?
	let pointers : [FindViews.AuthNFTPointer]
	
	prepare(account: AuthAccount) {

		if nftAliasOrIdentifiers.length != ids.length {
			panic("The length of arrays passed in has to be the same")
		} else if nftAliasOrIdentifiers.length != directSellPrices.length {
			panic("The length of arrays passed in has to be the same")
		}


		let tenantCapability= FindMarket.getTenantCapability(marketplace)!
		let tenant = tenantCapability.borrow()!
		self.saleItems= account.borrow<&FindMarketSale.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketSale.SaleItemCollection>()))
		self.pointers= []

		let nfts : {String : NFTCatalog.NFTCollectionData} = {}

		var counter = 0
		while counter < ids.length {
			// Get supported NFT and FT Information from Registries from input alias
			var nft : NFTCatalog.NFTCollectionData? = nil
			var ft : FTRegistry.FTInfo? = nil

			if nfts[nftAliasOrIdentifiers[counter]] != nil {
				nft = nfts[nftAliasOrIdentifiers[counter]]
			} else {
				let collectionIdentifier = FINDNFTCatalog.getCollectionsForType(nftTypeIdentifier: nftAliasOrIdentifiers[counter])?.keys ?? panic("This NFT is not supported by the NFT Catalog yet. Type : ".concat(nftAliasOrIdentifiers[counter])) 
				let collection = FINDNFTCatalog.getCatalogEntry(collectionIdentifier : collectionIdentifier[0])! 
				nft = collection.collectionData
				nfts[nftAliasOrIdentifiers[counter]] = nft
			}

			var providerCap=account.getCapability<&{NonFungibleToken.Provider, MetadataViews.ResolverCollection, NonFungibleToken.CollectionPublic}>(nft!.privatePath)

			/* Ben : Question -> Either client will have to provide the path here or agree that we set it up for the user */
			if !providerCap.check() {
				let newCap = account.link<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
						nft!.privatePath,
						target: nft!.storagePath
				)
				if newCap == nil {
					// If linking is not successful, we link it using finds custom link 
					let pathIdentifier = nft!.privatePath.toString()
					let findPath = PrivatePath(identifier: pathIdentifier.slice(from: "/private/".length , upTo: pathIdentifier.length).concat("_FIND"))!
					account.link<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
						findPath,
						target: nft!.storagePath
					)
					providerCap = account.getCapability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(findPath)
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
			self.saleItems!.listForSale(pointer: self.pointers[counter], vaultType: Type<@DapperUtilityCoin.Vault>(), directSellPrice: directSellPrices[counter], validUntil: validUntil, extraField: {})
			counter = counter + 1
		}
	}
}

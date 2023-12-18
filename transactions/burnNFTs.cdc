import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import NFTCatalog from "../contracts/standard/NFTCatalog.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
import FindViews from "../contracts/FindViews.cdc"
import FIND from "../contracts/FIND.cdc"
import FindFurnace from "../contracts/FindFurnace.cdc"

transaction(types: [String] , ids: [UInt64], messages: [String]) {

	let authPointers : [FindViews.AuthNFTPointer]

	prepare(account : auth(BorrowValue) &Account) {

		self.authPointers = []

		let contractData : {Type : NFTCatalog.NFTCatalogMetadata} = {}


		for i , typeIdentifier in types {
			let type = CompositeType(typeIdentifier) ?? panic("Cannot refer to type with identifier : ".concat(typeIdentifier))

			var data : NFTCatalog.NFTCatalogMetadata? = contractData[type]
			if data == nil {
				data = FINDNFTCatalog.getMetadataFromType(type) ?? panic("NFT Type is not supported by NFT Catalog. Type : ".concat(type.identifier))
				contractData[type] = data
			}

			let path = data!.collectionData

			var providerCap=account.getCapability<&{NonFungibleToken.Provider, ViewResolver.ResolverCollection, NonFungibleToken.Collection}>(path.privatePath)
			if !providerCap.check() {
				let newCap = account.link<&{NonFungibleToken.Provider, NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(
					path.privatePath,
					target: path.storagePath
				)
				if newCap == nil {
					// If linking is not successful, we link it using finds custom link 
					let pathIdentifier = path.privatePath.toString()
					let findPath = PrivatePath(identifier: pathIdentifier.slice(from: "/private/".length , upTo: pathIdentifier.length).concat("_FIND"))!
					account.link<&{NonFungibleToken.Provider, NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(
						findPath,
						target: path.storagePath
					)
					providerCap = account.getCapability<&{NonFungibleToken.Provider, NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(findPath)
				}
			}
			let pointer = FindViews.AuthNFTPointer(cap: providerCap, id: ids[i])
			self.authPointers.append(pointer)
		}
	}

	execute {
		let ctx : {String : String} = {
			"tenant" : "find"
		}
		for i,  pointer in self.authPointers {
			let id = ids[i] 
			ctx["message"] = messages[i]

			// burn thru furnace
			FindFurnace.burn(pointer: pointer, context: ctx)
		}
	}
}

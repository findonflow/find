import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import NFTCatalog from "../contracts/standard/NFTCatalog.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
import FindViews from "../contracts/FindViews.cdc"
import FIND from "../contracts/FIND.cdc"
import FindAirdropper from "../contracts/FindAirdropper.cdc"

transaction(nftIdentifiers: [String], allReceivers: [String] , ids:[UInt64], memos: [String]) {

	let authPointers : [FindViews.AuthNFTPointer]
	let paths : [PublicPath]

	prepare(account : AuthAccount) {

		self.authPointers = []
		self.paths = []

		let contractData : {Type : NFTCatalog.NFTCatalogMetadata} = {}


		for i , typeIdentifier in nftIdentifiers {
			let type = CompositeType(typeIdentifier) ?? panic("Cannot refer to type with identifier : ".concat(typeIdentifier))

			var data : NFTCatalog.NFTCatalogMetadata? = contractData[type]
			if data == nil {
				data = FINDNFTCatalog.getMetadataFromType(type) ?? panic("NFT Type is not supported by NFT Catalog. Type : ".concat(type.identifier))
				contractData[type] = data
			}

			let path = data!.collectionData

			var providerCap=account.getCapability<&{NonFungibleToken.Provider, MetadataViews.ResolverCollection, NonFungibleToken.CollectionPublic}>(path.privatePath)
			if !providerCap.check() {
				let newCap = account.link<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
					path.privatePath,
					target: path.storagePath
				)
				if newCap == nil {
					// If linking is not successful, we link it using finds custom link 
					let pathIdentifier = path.privatePath.toString()
					let findPath = PrivatePath(identifier: pathIdentifier.slice(from: "/private/".length , upTo: pathIdentifier.length).concat("_FIND"))!
					account.link<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
						findPath,
						target: path.storagePath
					)
					providerCap = account.getCapability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(findPath)
				}
			}
			let pointer = FindViews.AuthNFTPointer(cap: providerCap, id: ids[i])
			self.authPointers.append(pointer)
			self.paths.append(path.publicPath)
		}
	}

	execute {
		let addresses : {String : Address} = {} 
		for i,  pointer in self.authPointers {
			let receiver = allReceivers[i]
			let id = ids[i] 
			let message = memos[i]
			let path = self.paths[i]

			var user = addresses[receiver]
			if user == nil {
				user = FIND.resolve(receiver) ?? panic("Cannot resolve user with name / address : ".concat(receiver))
				addresses[receiver] = user
			}

			// airdrop thru airdropper
			FindAirdropper.airdrop(pointer: pointer, receiver: user!, path: path, context: {"message" : message})
		}
	}
}

import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindViews from "../contracts/FindViews.cdc"
import FIND from "../contracts/FIND.cdc"
import FindAirdropper from "../contracts/FindAirdropper.cdc"
import Wearables from "../contracts/community/Wearables.cdc"

transaction(allReceivers: [String] , ids:[UInt64], memos: [String]) {

	let authPointers : [FindViews.AuthNFTPointer]

	prepare(account : AuthAccount) {

		self.authPointers = []
		let privatePath = Wearables.CollectionPrivatePath
		let storagePath = Wearables.CollectionStoragePath

		for id in ids {

			var providerCap=account.getCapability<&{NonFungibleToken.Provider, MetadataViews.ResolverCollection, NonFungibleToken.CollectionPublic}>(privatePath)
			if !providerCap.check() {
				let newCap = account.link<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
					privatePath,
					target: storagePath
				)
				if newCap == nil {
					// If linking is not successful, we link it using finds custom link
					let pathIdentifier = privatePath.toString()
					let findPath = PrivatePath(identifier: pathIdentifier.slice(from: "/private/".length , upTo: pathIdentifier.length).concat("_FIND"))!
					account.link<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
						findPath,
						target: storagePath
					)
					providerCap = account.getCapability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(findPath)
				}
			}
			let pointer = FindViews.AuthNFTPointer(cap: providerCap, id: id)

			self.authPointers.append(pointer)
		}

	}

	execute {
		let addresses : {String : Address} = {}
		let publicPath = Wearables.CollectionPublicPath

		let ctx : {String : String} = {
			"tenant" : "find"
		}

		for i,  pointer in self.authPointers {
			let receiver = allReceivers[i]
			let id = ids[i]
			ctx["message"] = memos[i]

			var user = addresses[receiver]
			if user == nil {
				user = FIND.resolve(receiver) ?? panic("Cannot resolve user with name / address : ".concat(receiver))
				addresses[receiver] = user
			}

			// airdrop thru airdropper
			FindAirdropper.safeAirdrop(pointer: pointer, receiver: user!, path: publicPath, context: ctx, deepValidation: true)
		}

	}
}

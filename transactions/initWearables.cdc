import Wearables from "../contracts/community/Wearables.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"

transaction() {
	prepare(account: AuthAccount) {

		let wearablesRef= account.borrow<&Wearables.Collection>(from: Wearables.CollectionStoragePath)
		if wearablesRef == nil {
			account.save<@NonFungibleToken.Collection>(<- Wearables.createEmptyCollection(), to: Wearables.CollectionStoragePath)
			account.unlink(Wearables.CollectionPublicPath)
			account.link<&Wearables.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
				Wearables.CollectionPublicPath,
				target: Wearables.CollectionStoragePath
			)
			account.unlink(Wearables.CollectionPrivatePath)
			account.link<&Wearables.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
				Wearables.CollectionPrivatePath,
				target: Wearables.CollectionStoragePath
			)
			return
		}

		let wearablesCap= account.getCapability<&Wearables.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(Wearables.CollectionPublicPath)
		if !wearablesCap.check() {
			account.unlink(Wearables.CollectionPublicPath)
			account.link<&Wearables.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
				Wearables.CollectionPublicPath,
				target: Wearables.CollectionStoragePath
			)
		}

		let wearablesProviderCap= account.getCapability<&Wearables.Collection{NonFungibleToken.Provider,NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(Wearables.CollectionPrivatePath)
		if !wearablesProviderCap.check() {
			account.unlink(Wearables.CollectionPrivatePath)
			account.link<&Wearables.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
				Wearables.CollectionPrivatePath,
				target: Wearables.CollectionStoragePath
			)
		}

	}
}

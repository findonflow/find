import Market from "../contracts/Market.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"
import Dandy from "../contracts/Dandy.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import TypedMetadata from "../contracts/TypedMetadata.cdc"

//TODO: use execute and post
transaction(id: UInt64) {
	prepare(account: AuthAccount) {

		let dandyPrivateCap=	account.getCapability<&Dandy.Collection{NonFungibleToken.Provider, MetadataViews.ResolverCollection, NonFungibleToken.Receiver}>(Dandy.CollectionPrivatePath)
		let pointer= TypedMetadata.AuthNFTPointer(cap: dandyPrivateCap, id: id)

		let market = account.borrow<&Market.SaleItemCollection>(from: Market.SaleItemCollectionStoragePath)!
		market.fulfillDirectOffer(pointer)

	}
}

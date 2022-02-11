import FindMarket from "../contracts/FindMarket.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"
import Dandy from "../contracts/Dandy.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindViews from "../contracts/FindViews.cdc"

//TODO: use execute and post
transaction(id: UInt64) {
	prepare(account: AuthAccount) {

		let dandyPrivateCap=	account.getCapability<&Dandy.Collection{NonFungibleToken.Provider, MetadataViews.ResolverCollection, NonFungibleToken.Receiver}>(Dandy.CollectionPrivatePath)
		let pointer= FindViews.AuthNFTPointer(cap: dandyPrivateCap, id: id)

		let market = account.borrow<&FindMarket.SaleItemCollection>(from: FindMarket.SaleItemCollectionStoragePath)!
		market.fulfillDirectOffer(pointer)

	}
}

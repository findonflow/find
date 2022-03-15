import FindMarket from "../contracts/FindMarket.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import Dandy from "../contracts/Dandy.cdc"
import FindViews from "../contracts/FindViews.cdc"

transaction(id: UInt64, directSellPrice:UFix64, marketplace:Address) {
	prepare(account: AuthAccount) {

		let saleItems= FindMarket.getSaleItemCapability(marketplace) ?? panic("Could not find sale item capability for this tenant")
		let dandyPrivateCap=	account.getCapability<&Dandy.Collection{NonFungibleToken.Provider, MetadataViews.ResolverCollection, NonFungibleToken.Receiver}>(Dandy.CollectionPrivatePath)

		let pointer= FindViews.AuthNFTPointer(cap: dandyPrivateCap, id: id)
		saleItems.borrow()!.listForSale(pointer: pointer, vaultType: Type<@FUSD.Vault>(), directSellPrice: directSellPrice)
	}
}

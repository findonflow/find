import Market from "../contracts/Market.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import Dandy from "../contracts/Dandy.cdc"
import TypedMetadata from "../contracts/TypedMetadata.cdc"

transaction(id: UInt64, user: Address, offerPrice:UFix64) {
	prepare(account: AuthAccount) {

		let buyerDandyCap= account.getCapability<&{NonFungibleToken.Receiver}>(Dandy.CollectionPublicPath)
		let pointer= TypedMetadata.createViewReadPointer(address: user, path:Dandy.CollectionPublicPath, id: id)
		let bids = account.borrow<&Market.MarketBidCollection>(from: Market.MarketBidCollectionStoragePath)!
		let vaultRef = account.borrow<&FUSD.Vault>(from: /storage/fusdVault) ?? panic("Could not borrow reference to the flowTokenVault!")
		let vault <- vaultRef.withdraw(amount: offerPrice) 
		bids.directOffer(item: pointer, vault: <- vault, nftCap: buyerDandyCap)
	}
}

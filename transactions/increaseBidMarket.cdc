import FindMarket from "../contracts/FindMarket.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"
import Dandy from "../contracts/Dandy.cdc"
import FindViews from "../contracts/FindViews.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"

transaction(id: UInt64, amount: UFix64) {
	prepare(account: AuthAccount) {

		let vaultRef = account.borrow<&FUSD.Vault>(from: /storage/fusdVault) ?? panic("Could not borrow reference to the flowTokenVault!")
		let vault <- vaultRef.withdraw(amount: amount) 
		let bids = account.borrow<&FindMarket.MarketBidCollection>(from: FindMarket.MarketBidCollectionStoragePath)!

		bids.increaseBid(id: id, vault: <- vault)
	}
}

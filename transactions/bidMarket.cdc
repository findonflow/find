import Market from "../contracts/Market.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"
import Dandy from "../contracts/Dandy.cdc"

transaction(address: Address, id: UInt64, amount: UFix64) {
	prepare(account: AuthAccount) {

		//TODO: This path should be sent in
		let dandyCap= account.getCapability<&{NonFungibleToken.Receiver}>(Dandy.CollectionPublicPath)
//		let vaultRef = account.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault) ?? panic("Could not borrow reference to the flowTokenVault!")

//		/storage/fusdVault
		let vaultRef = account.borrow<&FUSD.Vault>(from: /storage/fusdVault) ?? panic("Could not borrow reference to the flowTokenVault!")
		let vault <- vaultRef.withdraw(amount: amount) 
		let bids = account.borrow<&Market.MarketBidCollection>(from: Market.MarketBidCollectionStoragePath)!
		bids.bid(address: address, id: id, vault: <- vault, nftCap: dandyCap)
	}
}

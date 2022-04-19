import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketSale from "../contracts/FindMarketSale.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import Dandy from "../contracts/Dandy.cdc"
import FindViews from "../contracts/FindViews.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"

//BAM: remove
transaction(address: Address, id: UInt64, amount: UFix64) {

	let targetCapability : Capability<&{NonFungibleToken.Receiver}>
	let walletReference : &FlowToken.Vault

	let saleItemsCap: Capability<&FindMarketSale.SaleItemCollection{FindMarketSale.SaleItemCollectionPublic}> 
	let balanceBeforeBid: UFix64

	prepare(account: AuthAccount) {
		self.targetCapability= account.getCapability<&{NonFungibleToken.Receiver}>(Dandy.CollectionPublicPath)
		self.walletReference = account.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault) ?? panic("No Flow wallet linked for this account")
		self.balanceBeforeBid=self.walletReference.balance
		self.saleItemsCap= FindMarketSale.getFindSaleItemCapability(address) ?? panic("cannot find sale item cap")
	}

	pre {
		self.saleItemsCap.check() : "The sale item cap is not linked"
		self.walletReference.balance > amount : "Your wallet does not have enough funds to pay for this item"
		self.targetCapability.check() : "The target collection for the item your are bidding on does not exist"
	}

	execute {
		let vault <- self.walletReference.withdraw(amount: amount) 
		self.saleItemsCap.borrow()!.buy(id:id, vault: <- vault, nftCap: self.targetCapability)
	}

	post {
		self.walletReference.balance == self.balanceBeforeBid - amount
	}
}

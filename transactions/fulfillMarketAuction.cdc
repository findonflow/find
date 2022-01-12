import Market from "../contracts/Market.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"
import Dandy from "../contracts/Dandy.cdc"


transaction(owner: Address, id: UInt64) {
	prepare(account: AuthAccount) {

		let marketCap = getAccount(owner).getCapability<&Market.SaleItemCollection{Market.SaleItemCollectionPublic}>(Market.SaleItemCollectionPublicPath)
		marketCap.borrow()!.fulfillAuction(id)

	}
}

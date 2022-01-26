import Market from "../contracts/Market.cdc"

transaction(owner: Address, id: UInt64) {
	prepare(account: AuthAccount) {

		let marketCap = getAccount(owner).getCapability<&Market.SaleItemCollection{Market.SaleItemCollectionPublic}>(Market.SaleItemCollectionPublicPath)
		marketCap.borrow()!.fulfillAuction(id)

	}
}

import FindMarket from "../contracts/FindMarket.cdc"

transaction(owner: Address, id: UInt64) {
	prepare(account: AuthAccount) {

		let marketCap = getAccount(owner).getCapability<&FindMarket.SaleItemCollection{FindMarket.SaleItemCollectionPublic}>(FindMarket.SaleItemCollectionPublicPath)
		marketCap.borrow()!.fulfillAuction(id)

	}
}

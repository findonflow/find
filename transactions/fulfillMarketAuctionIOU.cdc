import FindMarketAuctionIOUEscrowed from "../contracts/FindMarketAuctionIOUEscrowed.cdc"
import FIND from "../contracts/FIND.cdc"

transaction(marketplace:Address, owner: String, id: UInt64) {

	let saleItem : Capability<&FindMarketAuctionIOUEscrowed.SaleItemCollection{FindMarketAuctionIOUEscrowed.SaleItemCollectionPublic}>?

	prepare(account: AuthAccount) {
		let resolveAddress = FIND.resolve(owner)
		if resolveAddress == nil { 
			panic("The address input is not a valid name nor address. Input : ".concat(owner))
		}
		let address = resolveAddress!
		self.saleItem = FindMarketAuctionIOUEscrowed.getSaleItemCapability(marketplace:marketplace, user:address)

	}

	pre{
		self.saleItem != nil : "This saleItem capability does not exist. Sale item ID: ".concat(id.toString())
		self.saleItem!.check() : "Cannot borrow reference to saleItem. Sale item ID: ".concat(id.toString())
	}

	execute {
		self.saleItem!.borrow()!.fulfillAuction(id:id, vault: nil)
	}
}

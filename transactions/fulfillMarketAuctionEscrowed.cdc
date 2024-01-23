import FindMarketAuctionEscrow from "../contracts/FindMarketAuctionEscrow.cdc"
import FIND from "../contracts/FIND.cdc"
import FindMarket from "../contracts/FindMarket.cdc"

transaction(owner: String, id: UInt64) {

    let saleItem : Capability<&{FindMarketAuctionEscrow.SaleItemCollectionPublic}>?

    prepare(account: auth(BorrowValue) &Account) {
        let marketplace = FindMarket.getFindTenantAddress()
        let resolveAddress = FIND.resolve(owner)
        if resolveAddress == nil {
            panic("The address input is not a valid name nor address. Input : ".concat(owner))
        }
        let address = resolveAddress!
        self.saleItem = FindMarketAuctionEscrow.getSaleItemCapability(marketplace:marketplace, user:address)

    }

    pre{
        self.saleItem != nil : "This saleItem capability does not exist. Sale item ID: ".concat(id.toString())
        self.saleItem!.check() : "Cannot borrow reference to saleItem. Sale item ID: ".concat(id.toString())
    }

    execute {
        self.saleItem!.borrow()!.fulfillAuction(id)
    }
}

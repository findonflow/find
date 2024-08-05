import "FIND"
import "FUSD"
import "FindMarket"
import "Clock"

access(all) struct FINDReport{

    access(all) let leases: [FIND.LeaseInformation]
    access(all) let leasesBids: [FIND.BidInfo]
    access(all) let itemsForSale: {String : FindMarket.SaleItemCollectionReport}
    access(all) let marketBids: {String : FindMarket.BidItemCollectionReport}

    init(
        bids: [FIND.BidInfo],
        leases : [FIND.LeaseInformation],
        leasesBids: [FIND.BidInfo],
        itemsForSale: {String : FindMarket.SaleItemCollectionReport},
        marketBids: {String : FindMarket.BidItemCollectionReport},
    ) {

        self.leases=leases
        self.leasesBids=leasesBids
        self.itemsForSale=itemsForSale
        self.marketBids=marketBids
    }
}


access(all) fun main(user: String) : FINDReport? {

    let maybeAddress=FIND.resolve(user)
    if maybeAddress == nil{
        return nil
    }

    let address=maybeAddress!

    let account=getAccount(address)
    if account.balance == 0.0 {
        return nil
    }


    let leaseCap = account.capabilities.borrow<&FIND.LeaseCollection>(FIND.LeasePublicPath)
    let leases = leaseCap?.getLeaseInformation() ?? []
    let find= FindMarket.getFindTenantAddress()
    var items : {String : FindMarket.SaleItemCollectionReport} = FindMarket.getSaleItemReport(tenant:find, address: address, getNFTInfo:true)
    var marketBids : {String : FindMarket.BidItemCollectionReport} = FindMarket.getBidsReport(tenant:find, address: address, getNFTInfo:true)

    return FINDReport(
        bids: [],
        leases: leases,
        leasesBids: [],
        itemsForSale: items,
        marketBids: marketBids,
    )
}




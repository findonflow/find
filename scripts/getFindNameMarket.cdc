import "FIND"

access(all) struct FINDReport{

    access(all) let leases: [FIND.LeaseInformation]
    access(all) let leasesBids: [FIND.BidInfo]

    init(
        bids: [FIND.BidInfo],
        leases : [FIND.LeaseInformation],
        leasesBids: [FIND.BidInfo],
    ) {

        self.leases=leases
        self.leasesBids=leasesBids
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


    let bidCap=account.capabilities.borrow<&FIND.BidCollection>(FIND.BidPublicPath)!
    let leaseCap = account.capabilities.borrow<&FIND.LeaseCollection>(FIND.LeasePublicPath)!

    let leases = leaseCap.getLeaseInformation() 
    let oldLeaseBid = bidCap.getBids() 

    return FINDReport(
        bids: oldLeaseBid,
        leases: leases,
        leasesBids: oldLeaseBid,
    )
}




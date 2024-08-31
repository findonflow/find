import "FIND"
import "FlowToken"
import "FindLeaseMarket"
import "FindMarket"
import "Clock"

access(all) struct FINDReport{

    access(all) let leasesForSale: {String : SaleItemCollectionReport}
    access(all) let leasesBids: {String : BidItemCollectionReport}

    init(
        leasesForSale: {String : SaleItemCollectionReport},
        leasesBids: {String : BidItemCollectionReport},
    ) {
        self.leasesForSale=leasesForSale
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

    let find= FindMarket.getFindTenantAddress()
    let leasesSale : {String : FindLeaseMarket.SaleItemCollectionReport} = FindLeaseMarket.getSaleItemReport(tenant:find, address: address, getLeaseInfo:true)
    let consolidatedLeasesSale = addLeasesSale(leasesSale)
    let leasesBids : {String : FindLeaseMarket.BidItemCollectionReport} = FindLeaseMarket.getBidsReport(tenant:find, address: address, getLeaseInfo:true)
    let consolidatedLeaseBid = addLeasesBid(leasesBids)

    return FINDReport(
        leasesForSale: consolidatedLeasesSale,
        leasesBids: consolidatedLeaseBid,
    )
}

// These are for consolidating FIND Lease Sales
access(all) struct SaleItemCollectionReport {
    access(all) let items : [SaleItemInformation]
    access(all) let ghosts: [FindLeaseMarket.GhostListing]

    init(items: [SaleItemInformation], ghosts: [FindLeaseMarket.GhostListing]) {
        self.items=items
        self.ghosts=ghosts
    }

    access(all) fun combine(_ s: SaleItemCollectionReport?) {
        if s == nil {
            return
        }
        self.items.appendAll(s!.items)
        self.ghosts.appendAll(s!.ghosts)
    }
}

access(all) struct SaleItemInformation {
    access(all) var leaseIdentifier: String
    access(all) var leaseName: String
    access(all) var seller: Address?
    access(all) var sellerName: String?
    access(all) var amount: UFix64?
    access(all) var bidder: Address?
    access(all) var bidderName: String?
    access(all) var listingId: UInt64?

    access(all) var saleType: String
    access(all) var listingTypeIdentifier: String
    access(all) var ftAlias: String
    access(all) var ftTypeIdentifier: String
    access(all) var listingValidUntil: UFix64?

    access(all) var lease: LeaseInfo?
    access(all) var auction: FindLeaseMarket.AuctionItem?
    access(all) var listingStatus:String
    access(all) var saleItemExtraField: {String : AnyStruct}
    access(all) var market: String

    init(
        leaseIdentifier: String,
        leaseName: String,
        seller: Address?,
        sellerName: String?,
        amount: UFix64?,
        bidder: Address?,
        bidderName: String?,
        listingId: UInt64?,
        saleType: String,
        listingTypeIdentifier: String,
        ftAlias: String,
        ftTypeIdentifier: String,
        listingValidUntil: UFix64?,
        lease: LeaseInfo?,
        auction: FindLeaseMarket.AuctionItem?,
        listingStatus:String,
        saleItemExtraField: {String : AnyStruct},
        market: String
    ) {
        self.leaseIdentifier=leaseIdentifier
        self.leaseName=leaseName
        self.seller=seller
        self.sellerName=sellerName
        self.amount=amount
        self.bidder=bidder
        self.bidderName=bidderName
        self.listingId=listingId
        self.saleType=saleType
        self.listingTypeIdentifier=listingTypeIdentifier
        self.ftAlias=ftAlias
        self.ftTypeIdentifier=ftTypeIdentifier
        self.listingValidUntil=listingValidUntil
        self.lease=lease
        self.auction=auction
        self.listingStatus=listingStatus
        self.saleItemExtraField=saleItemExtraField
        self.market=market
    }
}

access(all) struct LeaseInfo {
    access(all) let name: String
    access(all) let address: Address
    access(all) let cost: UFix64
    access(all) let status: String
    access(all) let validUntil: UFix64
    access(all) let lockedUntil: UFix64
    access(all) let addons: [String]

    init(
        name: String,
        address: Address,
        cost: UFix64,
        status: String,
        validUntil: UFix64,
        lockedUntil: UFix64,
        addons: [String]
    ){
        self.name=name
        self.address=address
        self.cost=cost
        self.status=status
        self.validUntil=validUntil
        self.lockedUntil=lockedUntil
        self.addons=addons
    }

}

access(all) fun LeaseInfoFromFindLeaseMarket(_ l: FindLeaseMarket.LeaseInfo?) : LeaseInfo? {
    if l == nil {
        return nil
    }
    return LeaseInfo(
        name: l!.name,
        address: l!.address,
        cost: l!.cost,
        status: l!.status,
        validUntil: l!.validUntil,
        lockedUntil: l!.lockedUntil,
        addons: l!.addons
    )
}

access(all) fun LeaseInfoFromFIND(_ l: FIND.LeaseInformation?) : LeaseInfo? {
    if l == nil {
        return nil
    }
    return LeaseInfo(
        name: l!.name,
        address: l!.address,
        cost: l!.cost,
        status: l!.status,
        validUntil: l!.validUntil,
        lockedUntil: l!.lockedUntil,
        addons: l!.getAddons()
    )
}

access(all) fun SaleItemInformationFromFindLeaseMarket(_ s: FindLeaseMarket.SaleItemInformation) : SaleItemInformation {
    return SaleItemInformation(
        leaseIdentifier: s.leaseIdentifier,
        leaseName: s.leaseName,
        seller: s.seller,
        sellerName: s.sellerName,
        amount: s.amount,
        bidder: s.bidder,
        bidderName: s.bidderName,
        listingId: s.listingId,
        saleType: s.saleType,
        listingTypeIdentifier: s.listingTypeIdentifier,
        ftAlias: s.ftAlias,
        ftTypeIdentifier: s.ftTypeIdentifier,
        listingValidUntil: s.listingValidUntil,
        lease: LeaseInfoFromFindLeaseMarket(s.lease),
        auction: s.auction,
        listingStatus:s.listingStatus,
        saleItemExtraField: s.saleItemExtraField,
        market: "FindLeaseMarket"
    )
}

access(all) fun SaleItemInformationReportFromFindLeaseMarket(_ s: FindLeaseMarket.SaleItemCollectionReport) : SaleItemCollectionReport {

    var listing: [SaleItemInformation] = []
    for i in s.items {
        listing.append(SaleItemInformationFromFindLeaseMarket(i))
    }
    return SaleItemCollectionReport(items: listing, ghosts: s.ghosts)

}

access(all) fun addLeasesSale(_ sales : {String : FindLeaseMarket.SaleItemCollectionReport}) : {String : SaleItemCollectionReport} {


    let FINDLeasesSale :{String : SaleItemCollectionReport}  = {}
    let s : {String : SaleItemCollectionReport} = {}
    for key in sales.keys {
        let val = sales[key]!
        s[key] = SaleItemInformationReportFromFindLeaseMarket(val)
    }

    let findLeaseMarketSale = s["FindLeaseMarketSale"] ?? SaleItemCollectionReport(items: [], ghosts: [])
    findLeaseMarketSale.combine(FINDLeasesSale["FindLeaseMarketSale"])
    s["FindLeaseMarketSale"] = findLeaseMarketSale

    let FindLeaseMarketAuctionEscrow = s["FindLeaseMarketAuctionEscrow"] ?? SaleItemCollectionReport(items: [], ghosts: [])
    FindLeaseMarketAuctionEscrow.combine(FINDLeasesSale["FindLeaseMarketAuctionEscrow"])
    s["FindLeaseMarketAuctionEscrow"] = FindLeaseMarketAuctionEscrow

    let FindLeaseMarketDirectOfferEscrow = s["FindLeaseMarketDirectOfferEscrow"] ?? SaleItemCollectionReport(items: [], ghosts: [])
    FindLeaseMarketDirectOfferEscrow.combine(FINDLeasesSale["FindLeaseMarketDirectOfferEscrow"])
    s["FindLeaseMarketDirectOfferEscrow"] = FindLeaseMarketDirectOfferEscrow
    return s
}

access(all) struct BidInfo{
    access(all) let name: String
    access(all) let bidAmount: UFix64
    access(all) let bidTypeIdentifier: String
    access(all) let timestamp: UFix64
    access(all) let item: SaleItemInformation
    access(all) let market: String

    init(
        name: String,
        bidAmount: UFix64,
        bidTypeIdentifier: String,
        timestamp: UFix64,
        item: SaleItemInformation,
        market: String
    ) {
        self.name=name
        self.bidAmount=bidAmount
        self.bidTypeIdentifier=bidTypeIdentifier
        self.timestamp=timestamp
        self.item=item
        self.market=market
    }
}

access(all) fun BidInfoFromFindLeaseMarket(_ b: FindLeaseMarket.BidInfo) : BidInfo {
    let i = SaleItemInformationFromFindLeaseMarket(b.item)
    return BidInfo(
        name: b.name,
        bidAmount: b.bidAmount,
        bidTypeIdentifier: b.bidTypeIdentifier,
        timestamp: b.timestamp,
        item: i,
        market: "FindLeaseMarket"
    )
}

access(all) struct BidItemCollectionReport {
    access(all) let items : [BidInfo]
    access(all) let ghosts: [FindLeaseMarket.GhostListing]

    init(items: [BidInfo], ghosts: [FindLeaseMarket.GhostListing]) {
        self.items=items
        self.ghosts=ghosts
    }

    access(all) fun combine(_ s: BidItemCollectionReport?) {
        if s == nil {
            return
        }
        self.items.appendAll(s!.items)
        self.ghosts.appendAll(s!.ghosts)
    }
}

access(all) fun BidReportFromFindLeaseMarket(_ s: FindLeaseMarket.BidItemCollectionReport) : BidItemCollectionReport {

    var listing: [BidInfo] = []
    for i in s.items {
        listing.append(BidInfoFromFindLeaseMarket(i))
    }
    return BidItemCollectionReport(items: listing, ghosts: s.ghosts)

}

access(all) fun addLeasesBid(_ sales : {String : FindLeaseMarket.BidItemCollectionReport}) : {String : BidItemCollectionReport} {

    let FINDLeasesSale : {String : BidItemCollectionReport} = {}
    let s : {String : BidItemCollectionReport} = {}
    for key in sales.keys {
        let val = sales[key]!
        s[key] = BidReportFromFindLeaseMarket(val)
    }

    let findLeaseMarketSale = s["FindLeaseMarketSale"] ?? BidItemCollectionReport(items: [], ghosts: [])
    findLeaseMarketSale.combine(FINDLeasesSale["FindLeaseMarketSale"])
    s["FindLeaseMarketSale"] = findLeaseMarketSale

    let FindLeaseMarketAuctionEscrow = s["FindLeaseMarketAuctionEscrow"] ?? BidItemCollectionReport(items: [], ghosts: [])
    FindLeaseMarketAuctionEscrow.combine(FINDLeasesSale["FindLeaseMarketAuctionEscrow"])
    s["FindLeaseMarketAuctionEscrow"] = FindLeaseMarketAuctionEscrow

    let FindLeaseMarketDirectOfferEscrow = s["FindLeaseMarketDirectOfferEscrow"] ?? BidItemCollectionReport(items: [], ghosts: [])
    FindLeaseMarketDirectOfferEscrow.combine(FINDLeasesSale["FindLeaseMarketDirectOfferEscrow"])
    s["FindLeaseMarketDirectOfferEscrow"] = FindLeaseMarketDirectOfferEscrow
    return s
}

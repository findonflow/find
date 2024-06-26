import FIND from "../contracts/FIND.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"
import FindLeaseMarket from "../contracts/FindLeaseMarket.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import Clock from "../contracts/Clock.cdc"

pub struct FINDReport{

	pub let leasesForSale: {String : SaleItemCollectionReport}
	pub let leasesBids: {String : BidItemCollectionReport}

	init(
		 leasesForSale: {String : SaleItemCollectionReport},
		 leasesBids: {String : BidItemCollectionReport},
		 ) {
		self.leasesForSale=leasesForSale
		self.leasesBids=leasesBids
	}
}


pub fun main(user: String) : FINDReport? {

	let maybeAddress=FIND.resolve(user)
	if maybeAddress == nil{
		return nil
	}

	let address=maybeAddress!

	let account=getAuthAccount(address)
	if account.balance == 0.0 {
		return nil
	}

		let find= FindMarket.getFindTenantAddress()
		let leasesSale : {String : FindLeaseMarket.SaleItemCollectionReport} = FindLeaseMarket.getSaleItemReport(tenant:find, address: address, getLeaseInfo:true)
		let consolidatedLeasesSale = addLeasesSale([], leasesSale)
		let leasesBids : {String : FindLeaseMarket.BidItemCollectionReport} = FindLeaseMarket.getBidsReport(tenant:find, address: address, getLeaseInfo:true)
		let consolidatedLeaseBid = addLeasesBid([], leasesBids)
		
		return FINDReport(
			leasesForSale: consolidatedLeasesSale,
			leasesBids: consolidatedLeaseBid,
		)
}

// These are for consolidating FIND Lease Sales
pub struct SaleItemCollectionReport {
	pub let items : [SaleItemInformation]
	pub let ghosts: [FindLeaseMarket.GhostListing]

	init(items: [SaleItemInformation], ghosts: [FindLeaseMarket.GhostListing]) {
		self.items=items
		self.ghosts=ghosts
	}

	pub fun combine(_ s: SaleItemCollectionReport?) {
		if s == nil {
			return
		}
		self.items.appendAll(s!.items)
		self.ghosts.appendAll(s!.ghosts)
	}
}

pub struct SaleItemInformation {
	pub var leaseIdentifier: String
	pub var leaseName: String
	pub var seller: Address?
	pub var sellerName: String?
	pub var amount: UFix64?
	pub var bidder: Address?
	pub var bidderName: String?
	pub var listingId: UInt64?

	pub var saleType: String
	pub var listingTypeIdentifier: String
	pub var ftAlias: String
	pub var ftTypeIdentifier: String
	pub var listingValidUntil: UFix64?

	pub var lease: LeaseInfo?
	pub var auction: FindLeaseMarket.AuctionItem?
	pub var listingStatus:String
	pub var saleItemExtraField: {String : AnyStruct}
	pub var market: String

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

pub struct LeaseInfo {
	pub let name: String
	pub let address: Address
	pub let cost: UFix64
	pub let status: String
	pub let validUntil: UFix64
	pub let lockedUntil: UFix64
	pub let addons: [String]

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

pub fun LeaseInfoFromFindLeaseMarket(_ l: FindLeaseMarket.LeaseInfo?) : LeaseInfo? {
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

pub fun LeaseInfoFromFIND(_ l: FIND.LeaseInformation?) : LeaseInfo? {
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

pub fun SaleItemInformationFromFindLeaseMarket(_ s: FindLeaseMarket.SaleItemInformation) : SaleItemInformation {
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

pub fun SaleReportFromFindLeaseMarket(_ s: FindLeaseMarket.SaleItemCollectionReport) : SaleItemCollectionReport {

	var listing: [SaleItemInformation] = []
	for i in s.items {
		listing.append(SaleItemInformationFromFindLeaseMarket(i))
	}
	return SaleItemCollectionReport(items: listing, ghosts: s.ghosts)

}

pub fun transformLeaseSale(_ leases: [FIND.LeaseInformation]) : {String : SaleItemCollectionReport} {
	let output : {String : SaleItemCollectionReport} = {}
	let saleCollection : [SaleItemInformation] = []
	let auctionCollection : [SaleItemInformation] = []
	let OfferCollection : [SaleItemInformation] = []
	for l in leases {
		if l.salePrice != nil {
			let sale = SaleItemInformation(
					leaseIdentifier: Type<@FIND.Lease>().identifier,
					leaseName: l.name,
					seller: l.address,
					sellerName: FIND.reverseLookup(l.address),
					amount: l.salePrice,
					bidder: nil,
					bidderName: nil,
					listingId: nil,
					saleType: Type<@FIND.Lease>().identifier,
					listingTypeIdentifier: Type<@FIND.Lease>().identifier,
					ftAlias: "FUSD",
					ftTypeIdentifier: Type<@FUSD.Vault>().identifier,
					listingValidUntil: nil,
					lease: LeaseInfoFromFIND(l),
					auction: nil,
					listingStatus:"active_listed",
					saleItemExtraField: {},
					market: "FIND"
				)
				saleCollection.append(sale)
		}

		if l.auctionStartPrice != nil {
			let a = FindLeaseMarket.AuctionItem(
				startPrice: l.auctionStartPrice!,
				currentPrice: l.latestBid ?? 0.0,
				minimumBidIncrement: 10.0,
				reservePrice: l.auctionReservePrice!,
				extentionOnLateBid: l.extensionOnLateBid!,
				auctionEndsAt: l.auctionEnds ,
				timestamp: Clock.time()
			)

			var bidderName : String? = nil
			if l.latestBidBy != nil {
				bidderName = FIND.reverseLookup(l.latestBidBy!)
			}

			let auction = SaleItemInformation(
				leaseIdentifier: Type<@FIND.Lease>().identifier,
				leaseName: l.name,
				seller: l.address,
				sellerName: FIND.reverseLookup(l.address),
				amount: l.salePrice,
				bidder: l.latestBidBy,
				bidderName: bidderName,
				listingId: nil,
				saleType: Type<@FIND.Lease>().identifier,
				listingTypeIdentifier: Type<@FIND.Lease>().identifier,
				ftAlias: "FUSD",
				ftTypeIdentifier: Type<@FUSD.Vault>().identifier,
				listingValidUntil: nil,
				lease: LeaseInfoFromFIND(l),
				auction: a,
				listingStatus:"active_listed",
				saleItemExtraField: {},
				market: "FIND"
			)
			auctionCollection.append(auction)
		} else if l.latestBid != nil {
			var bidderName : String? = nil
			if l.latestBidBy != nil {
				bidderName = FIND.reverseLookup(l.latestBidBy!)
			}

			let bid = SaleItemInformation(
				leaseIdentifier: Type<@FIND.Lease>().identifier,
				leaseName: l.name,
				seller: l.address,
				sellerName: FIND.reverseLookup(l.address),
				amount: l.salePrice,
				bidder: l.latestBidBy,
				bidderName: bidderName,
				listingId: nil,
				saleType: Type<@FIND.Lease>().identifier,
				listingTypeIdentifier: Type<@FIND.Lease>().identifier,
				ftAlias: "FUSD",
				ftTypeIdentifier: Type<@FUSD.Vault>().identifier,
				listingValidUntil: nil,
				lease: LeaseInfoFromFIND(l),
				auction: nil,
				listingStatus:"active_listed",
				saleItemExtraField: {},
				market: "FIND"
			)
			OfferCollection.append(bid)
		}

	}

	output["FindLeaseMarketSale"] = SaleItemCollectionReport(
		items: saleCollection,
		ghosts: []
	)

	output["FindLeaseMarketAuctionEscrow"] = SaleItemCollectionReport(
		items: auctionCollection,
		ghosts: []
	)

	output["FindLeaseMarketDirectOfferEscrow"] = SaleItemCollectionReport(
		items: OfferCollection,
		ghosts: []
	)

	return output
}

pub fun addLeasesSale(_ leases: [FIND.LeaseInformation], _ sales : {String : FindLeaseMarket.SaleItemCollectionReport}) : {String : SaleItemCollectionReport} {

	let FINDLeasesSale = transformLeaseSale(leases)
	let s : {String : SaleItemCollectionReport} = {}
	for key in sales.keys {
		let val = sales[key]!
		s[key] = SaleReportFromFindLeaseMarket(val)
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

pub struct BidInfo{
	pub let name: String
	pub let bidAmount: UFix64
	pub let bidTypeIdentifier: String
	pub let timestamp: UFix64
	pub let item: SaleItemInformation
	pub let market: String

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

pub fun BidInfoFromFindLeaseMarket(_ b: FindLeaseMarket.BidInfo) : BidInfo {
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

pub struct BidItemCollectionReport {
	pub let items : [BidInfo]
	pub let ghosts: [FindLeaseMarket.GhostListing]

	init(items: [BidInfo], ghosts: [FindLeaseMarket.GhostListing]) {
		self.items=items
		self.ghosts=ghosts
	}

	pub fun combine(_ s: BidItemCollectionReport?) {
		if s == nil {
			return
		}
		self.items.appendAll(s!.items)
		self.ghosts.appendAll(s!.ghosts)
	}
}

pub fun BidReportFromFindLeaseMarket(_ s: FindLeaseMarket.BidItemCollectionReport) : BidItemCollectionReport {

	var listing: [BidInfo] = []
	for i in s.items {
		listing.append(BidInfoFromFindLeaseMarket(i))
	}
	return BidItemCollectionReport(items: listing, ghosts: s.ghosts)

}

pub fun transformLeaseBid(_ leases: [FIND.BidInfo]) : {String : BidItemCollectionReport} {
	let output : {String : BidItemCollectionReport} = {}
	let auctionCollection : [BidInfo] = []
	let OfferCollection : [BidInfo] = []
	for l in leases {
		if l.type != "auction" {

			var sellerName : String? = nil
			if l.lease?.address != nil {
				sellerName = FIND.reverseLookup(l.lease!.address)
			}

			var bidderName : String? = nil
			if l.lease?.latestBidBy != nil {
				bidderName = FIND.reverseLookup(l.lease!.latestBidBy!)
			}

			let saleInfo = SaleItemInformation(
				leaseIdentifier: Type<@FIND.Lease>().identifier,
				leaseName: l.name,
				seller: l.lease?.address,
				sellerName: sellerName,
				amount: l.amount,
				bidder: l.lease?.latestBidBy,
				bidderName: bidderName,
				listingId: nil,
				saleType: Type<@FIND.Lease>().identifier,
				listingTypeIdentifier: Type<@FIND.Lease>().identifier,
				ftAlias: "FUSD",
				ftTypeIdentifier: Type<@FUSD.Vault>().identifier,
				listingValidUntil: nil,
				lease: LeaseInfoFromFIND(l.lease),
				auction: nil,
				listingStatus:"active_ongoing",
				saleItemExtraField: {},
				market: "FIND"
			)

			let a = BidInfo(
				name: l.name,
				bidAmount: l.amount,
				bidTypeIdentifier: Type<@FIND.Lease>().identifier,
				timestamp: Clock.time(),
				item: saleInfo,
				market: "FIND"
			)

			auctionCollection.append(a)
		} else if l.type != "blind" {

			var sellerName : String? = nil
			if l.lease?.address != nil {
				sellerName = FIND.reverseLookup(l.lease!.address)
			}

			var bidderName : String? = nil
			if l.lease?.latestBidBy != nil {
				bidderName = FIND.reverseLookup(l.lease!.latestBidBy!)
			}

			let saleInfo = SaleItemInformation(
				leaseIdentifier: Type<@FIND.Lease>().identifier,
				leaseName: l.name,
				seller: l.lease?.address,
				sellerName: sellerName,
				amount: l.amount,
				bidder: l.lease?.latestBidBy,
				bidderName: bidderName,
				listingId: nil,
				saleType: Type<@FIND.Lease>().identifier,
				listingTypeIdentifier: Type<@FIND.Lease>().identifier,
				ftAlias: "FUSD",
				ftTypeIdentifier: Type<@FUSD.Vault>().identifier,
				listingValidUntil: nil,
				lease: LeaseInfoFromFIND(l.lease),
				auction: nil,
				listingStatus:"active_offered",
				saleItemExtraField: {},
				market: "FIND"
			)

			let a = BidInfo(
				name: l.name,
				bidAmount: l.amount,
				bidTypeIdentifier: Type<@FIND.Lease>().identifier,
				timestamp: Clock.time(),
				item: saleInfo,
				market: "FIND"
			)

			OfferCollection.append(a)
		}

	}

	output["FindLeaseMarketAuctionEscrow"] = BidItemCollectionReport(
		items: auctionCollection,
		ghosts: []
	)

	output["FindLeaseMarketDirectOfferEscrow"] = BidItemCollectionReport(
		items: OfferCollection,
		ghosts: []
	)

	return output
}

pub fun addLeasesBid(_ leases: [FIND.BidInfo], _ sales : {String : FindLeaseMarket.BidItemCollectionReport}) : {String : BidItemCollectionReport} {

	let FINDLeasesSale = transformLeaseBid(leases)
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

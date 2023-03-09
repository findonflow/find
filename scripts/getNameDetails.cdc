import FIND from "../contracts/FIND.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import FindLeaseMarket from "../contracts/FindLeaseMarket.cdc"
import Profile from "../contracts/Profile.cdc"
import FindRelatedAccounts from "../contracts/FindRelatedAccounts.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"
import TokenForwarding from "../contracts/standard/TokenForwarding.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"

pub struct FINDReport {
	pub let profile:Profile.UserReport?
	pub let bids: [BidInfo]
	pub let relatedAccounts: { String: [Address]}
	pub let leases: [LeaseInformation]
	pub let privateMode: Bool
	pub let activatedAccount: Bool
	pub let isDapper: Bool?
	pub let address: Address?


	init(profile: Profile.UserReport?, relatedAccounts: { String: [Address]}, bids: [BidInfo], leases : [LeaseInformation], privateMode: Bool, activatedAccount: Bool , isDapper: Bool?, address: Address?) {
		self.profile=profile
		self.bids=bids
		self.leases=leases
		self.relatedAccounts=relatedAccounts
		self.privateMode=privateMode
		self.activatedAccount=activatedAccount
		self.isDapper=isDapper
		self.address=address
	}
}

pub struct NameReport {
	pub let status: String
	pub let cost: UFix64
	pub let leaseStatus: LeaseInformation?
	pub let userReport: FINDReport?

	init(status: String, cost: UFix64, leaseStatus: LeaseInformation?, userReport: FINDReport? ) {
		self.status=status
		self.cost=cost
		self.leaseStatus=leaseStatus
		self.userReport=userReport
	}
}

pub fun main(user: String) : NameReport? {

	var findReport: FINDReport? = nil
	var nameLease: LeaseInformation? = nil
	if let address=FIND.resolve(user) {
		let account=getAccount(address)
		if account.balance != 0.0 {
			let bidCap = account.getCapability<&FIND.BidCollection{FIND.BidCollectionPublic}>(FIND.BidPublicPath)
			let leaseCap = account.getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)
			let profile=account.getCapability<&{Profile.Public}>(Profile.publicPath).borrow()

			var profileReport = profile?.asReport()
			if profileReport != nil && profileReport!.findName != FIND.reverseLookup(address) {
				profileReport = Profile.UserReport(
					findName: "",
					address: profileReport!.address,
					name: profileReport!.name,
					gender: profileReport!.gender,
					description: profileReport!.description,
					tags: profileReport!.tags,
					avatar: profileReport!.avatar,
					links: profileReport!.links,
					wallets: profileReport!.wallets,
					following: profileReport!.following,
					followers: profileReport!.followers,
					allowStoringFollowers: profileReport!.allowStoringFollowers,
					createdAt: profileReport!.createdAt
				)
			}

			let find= FindMarket.getFindTenantAddress()
			let inputLeases = leaseCap.borrow()?.getLeaseInformation() ?? []
			let outputLeases : [LeaseInformation] = []
			for l in inputLeases {
				let leaseInfo = LeaseInformation(l)
				if let sale = FindLeaseMarket.getSaleInformation(tenant: find, name: l.name, marketOption: "FindLeaseMarketSale", getLeaseInfo: false) {
					leaseInfo.addSale(sale)
				}
				if let auctionS = FindLeaseMarket.getSaleInformation(tenant: find, name: l.name, marketOption: "FindLeaseMarketAuctionSoft", getLeaseInfo: false) {
					leaseInfo.addAuction(auctionS)
				}
				if let auctionE = FindLeaseMarket.getSaleInformation(tenant: find, name: l.name, marketOption: "FindLeaseMarketAuctionEscrow", getLeaseInfo: false) {
					leaseInfo.addAuction(auctionE)
				}
				if let offerS = FindLeaseMarket.getSaleInformation(tenant: find, name: l.name, marketOption: "FindLeaseMarketDirectOfferSoft", getLeaseInfo: false) {
					leaseInfo.addOffer(offerS)
				}
				if let offerE = FindLeaseMarket.getSaleInformation(tenant: find, name: l.name, marketOption: "FindLeaseMarketDirectOfferEscrow", getLeaseInfo: false) {
					leaseInfo.addOffer(offerE)
				}
				outputLeases.append(leaseInfo)
			}

			let inputBids = bidCap.borrow()?.getBids() ?? []
			let outputBids : [BidInfo] = []
			for b in inputBids {
				outputBids.append(AddBidInfo(b))
			}
			let leaseMarketBids = FindLeaseMarket.getBidsReport(tenant:find, address: address, getLeaseInfo: true)
			if let auctionS = leaseMarketBids["FindLeaseMarketAuctionSoft"] {
				for bid in auctionS.items {
					outputBids.append(AddAuctionBidLeaseMarket(bid))
				}
			}
			if let auctionE = leaseMarketBids["FindLeaseMarketAuctionEscrow"] {
				for bid in auctionE.items {
					outputBids.append(AddAuctionBidLeaseMarket(bid))
				}
			}
			if let offerS = leaseMarketBids["FindLeaseMarketDirectOfferSoft"] {
				for bid in offerS.items {
					outputBids.append(AddOfferBidLeaseMarket(bid))
				}
			}
			if let offerE = leaseMarketBids["FindLeaseMarketDirectOfferEscrow"] {
				for bid in offerE.items {
					outputBids.append(AddOfferBidLeaseMarket(bid))
				}
			}

			var isDapper=false
			if let receiver =account.getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver).borrow() {
			 	isDapper=receiver.isInstance(Type<@TokenForwarding.Forwarder>())
			} else {
				if let duc = account.getCapability<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver).borrow() {
					isDapper = duc.isInstance(Type<@TokenForwarding.Forwarder>())
				} else {
					isDapper = false
				}
			}

			findReport = FINDReport(
				profile: profileReport,
				relatedAccounts: FindRelatedAccounts.findRelatedFlowAccounts(address:address),
				bids: outputBids,
				leases: outputLeases,
				privateMode: profile?.isPrivateModeEnabled() ?? false,
				activatedAccount: true,
				isDapper:isDapper,
				address: address
			)
			if FIND.validateFindName(user) && findReport != nil {
				for lease in findReport!.leases {
					if lease.name == user {
						nameLease = lease
						break
					}
				}
			}
		} else {
			findReport = FINDReport(
				profile: nil,
				relatedAccounts: {},
				bids: [],
				leases: [],
				privateMode: false,
				activatedAccount: false,
				isDapper: nil,
				address: nil
			)
		}

	}

	var nameReport : NameReport? = nil
	if FIND.validateFindName(user) {
		let status = FIND.status(user)
		let cost=FIND.calculateCost(user)
		var s="TAKEN"
		if status.status == FIND.LeaseStatus.FREE {
			s="FREE"
		} else if status.status == FIND.LeaseStatus.LOCKED {
			s="LOCKED"
		}
		nameReport = NameReport(status: s, cost: cost, leaseStatus: nameLease, userReport: findReport)
	}


	return nameReport
}

pub struct Sale {
	pub var amount: UFix64?
	pub var ftAlias: String?
	pub var ftIdentifier: String
	pub var validUntil: UFix64?
	pub var market: String
	pub var saleStatus: String
	pub var saleTypeIdentifier: String

	init(
		amount: UFix64?,
		ftAlias: String?,
		ftIdentifier: String,
		validUntil: UFix64?,
		market: String,
		saleStatus: String,
		saleTypeIdentifier: String,
	) {
		self.amount=amount
		self.ftAlias=ftAlias
		self.ftIdentifier=ftIdentifier
		self.validUntil=validUntil
		self.market=market
		self.saleStatus=saleStatus
		self.saleTypeIdentifier=saleTypeIdentifier
	}
}

pub fun SaleFromFIND(_ l : FIND.LeaseInformation) : Sale? {
	if l.salePrice == nil {
		return nil
	}
	return Sale(
		amount: l.salePrice ,
		ftAlias: "FUSD",
		ftIdentifier: Type<@FUSD.Vault>().identifier,
		validUntil: nil,
		market: "FIND",
		saleStatus: "active_listed",
		saleTypeIdentifier: Type<@FIND.Lease>().identifier,
	)
}

pub fun SaleFromLeaseMarket(_ l: FindLeaseMarket.SaleItemInformation) : Sale {
	return Sale(
		amount: l.amount ,
		ftAlias: l.ftAlias,
		ftIdentifier: l.ftTypeIdentifier,
		validUntil: l.listingValidUntil,
		market: "FindleaseMarket",
		saleStatus: l.saleType,
		saleTypeIdentifier: l.listingTypeIdentifier,
	)
}

pub struct Auction {
	pub var amount: UFix64?
	pub var ftAlias: String?
	pub var ftIdentifier: String
	pub var validUntil: UFix64?
	pub var startPrice: UFix64?
	pub var reservePrice: UFix64?
	pub var extensionOnLateBid: UFix64?
	pub var bidder: Address?
	pub var bidderName: String?
	pub var endsAt: UFix64?
	pub var market: String
	pub var saleStatus: String
	pub var saleTypeIdentifier: String

	init(
		amount: UFix64?,
		ftAlias: String?,
		ftIdentifier: String,
		validUntil: UFix64?,
		startPrice: UFix64?,
		reservePrice: UFix64?,
		extensionOnLateBid: UFix64?,
		bidder: Address?,
		bidderName: String?,
		endsAt: UFix64?,
		market: String,
		saleStatus: String,
		saleTypeIdentifier: String,
	) {
		self.amount=amount
		self.ftAlias=ftAlias
		self.ftIdentifier=ftIdentifier
		self.validUntil=validUntil
		self.startPrice=startPrice
		self.reservePrice=reservePrice
		self.extensionOnLateBid=extensionOnLateBid
		self.bidder=bidder
		self.bidderName=bidderName
		self.endsAt=endsAt
		self.market=market
		self.saleStatus=saleStatus
		self.saleTypeIdentifier=saleTypeIdentifier
	}
}

pub fun AuctionFromFIND(_ l : FIND.LeaseInformation) : Auction? {
	if l.auctionStartPrice == nil {
		return nil
	}
	var bidderName : String? = nil
	if l.latestBidBy != nil {
		bidderName = FIND.reverseLookup(l.latestBidBy!)
	}
	return Auction(
		amount: l.latestBid,
		ftAlias: "FUSD",
		ftIdentifier: Type<@FUSD.Vault>().identifier,
		validUntil: nil,
		startPrice: l.auctionStartPrice,
		reservePrice: l.auctionReservePrice,
		extensionOnLateBid: l.extensionOnLateBid,
		bidder: l.latestBidBy,
		bidderName: bidderName,
		endsAt: l.auctionEnds,
		market: "FIND",
		saleStatus: "active_listed",
		saleTypeIdentifier: Type<@FIND.Lease>().identifier,
	)
}

pub fun AuctionFromLeaseMarket(_ l: FindLeaseMarket.SaleItemInformation) : Auction {
	return Auction(
		amount: l.auction?.currentPrice,
		ftAlias: l.ftAlias,
		ftIdentifier: l.ftTypeIdentifier,
		validUntil: l.listingValidUntil,
		startPrice: l.auction?.startPrice,
		reservePrice: l.auction?.reservePrice,
		extensionOnLateBid: l.auction?.extentionOnLateBid,
		bidder: l.bidder,
		bidderName: l.bidderName,
		endsAt: l.auction?.auctionEndsAt,
		market: "FindLeaseMarket",
		saleStatus: l.saleType,
		saleTypeIdentifier: l.listingTypeIdentifier,
	)
}

pub struct Offer {
	pub var amount: UFix64?
	pub var ftAlias: String?
	pub var ftIdentifier: String
	pub var validUntil: UFix64?
	pub var bidder: Address
	pub var bidderName: String?
	pub var market: String
	pub var saleStatus: String
	pub var saleTypeIdentifier: String

	init(
		amount: UFix64?,
		ftAlias: String?,
		ftIdentifier: String,
		validUntil: UFix64?,
		bidder: Address,
		bidderName: String?,
		market: String,
		saleStatus: String,
		saleTypeIdentifier: String,
	) {
		self.amount=amount
		self.ftAlias=ftAlias
		self.ftIdentifier=ftIdentifier
		self.validUntil=validUntil
		self.bidder=bidder
		self.bidderName=bidderName
		self.market=market
		self.saleStatus=saleStatus
		self.saleTypeIdentifier=saleTypeIdentifier
	}
}

pub fun OfferFromLeaseMarket(_ l: FindLeaseMarket.SaleItemInformation) : Offer {

	return Offer(
		amount: l.amount,
		ftAlias: l.ftAlias,
		ftIdentifier: l.ftTypeIdentifier,
		validUntil: l.listingValidUntil,
		bidder: l.bidder!,
		bidderName: l.bidderName,
		market: "FindLeaseMarket",
		saleStatus: l.saleType,
		saleTypeIdentifier: l.listingTypeIdentifier,
	)
}

pub struct LeaseInformation {
	pub var name: String
	pub var address: Address
	pub var cost: UFix64
	pub var status: String
	pub var validUntil: UFix64
	pub var lockedUntil: UFix64
	pub var currentTime: UFix64
	pub var addons: [String]
	pub var sales: [Sale]
	pub var auctions: [Auction]
	pub var offers: [Offer]

	init(_ l: FIND.LeaseInformation){

		self.name=l.name
		self.status=l.status
		self.validUntil=l.validUntil
		self.lockedUntil=l.lockedUntil
		self.currentTime=l.currentTime
		self.address=l.address
		self.cost=l.cost
		self.addons=l.addons
		let sale : [Sale] = []
		if let s = SaleFromFIND(l) {
			sale.append(s)
		}
		self.sales = sale

		let auction : [Auction] = []
		if let a = AuctionFromFIND(l) {
			auction.append(a)
		}
		self.auctions = auction

		self.offers = []

	}

	pub fun addSale(_ s: FindLeaseMarket.SaleItemInformation) {
		self.sales.append(SaleFromLeaseMarket(s))
	}

	pub fun addAuction(_ s: FindLeaseMarket.SaleItemInformation) {
		self.auctions.append(AuctionFromLeaseMarket(s))
	}

	pub fun addOffer(_ s: FindLeaseMarket.SaleItemInformation) {
		self.offers.append(OfferFromLeaseMarket(s))
	}

}

pub struct BidInfo {

	pub let name: String
	pub let amount: UFix64
	pub let bidStatus: String
	pub let bidTypeIdentifier: String
	pub let timestamp: UFix64
	pub let market: String
	pub let lease: LeaseInformation?

	init(
		name: String,
		amount: UFix64,
		bidStatus: String,
		bidTypeIdentifier: String,
		timestamp: UFix64,
		market: String,
		lease: LeaseInformation?
	) {
		self.name = name
		self.amount = amount
		self.timestamp = timestamp
		self.bidStatus = bidStatus
		self.bidTypeIdentifier = bidTypeIdentifier
		self.lease = lease
		self.market = market
	}

}

pub fun AddBidInfo(_ b: FIND.BidInfo) : BidInfo {
	var l : LeaseInformation? = nil
	if b.lease != nil {
		l = LeaseInformation(b.lease!)
	}
	return BidInfo(
		name: b.name,
		amount: b.amount,
		bidStatus: b.type,
		bidTypeIdentifier: Type<@FIND.Lease>().identifier,
		timestamp: b.timestamp,
		market: "FIND",
		lease:l
	)
}

pub fun AddAuctionBidLeaseMarket(_ b: FindLeaseMarket.BidInfo) : BidInfo {

	let leaseInfo = getAuthAccount(b.item.seller).borrow<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(from: FIND.LeaseStoragePath)!.getLease(b.name)
	var l : LeaseInformation? = nil
	if leaseInfo != nil {
		l = LeaseInformation(leaseInfo!)
	}
	return BidInfo(
		name: b.name,
		amount: b.bidAmount,
		bidStatus: "auction",
		bidTypeIdentifier: b.bidTypeIdentifier,
		timestamp: b.timestamp,
		market: "FindLeaseMarket",
		lease:l
	)
}

pub fun AddOfferBidLeaseMarket(_ b: FindLeaseMarket.BidInfo) : BidInfo {

	let leaseInfo = getAuthAccount(b.item.seller).borrow<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(from: FIND.LeaseStoragePath)!.getLease(b.name)
	var l : LeaseInformation? = nil
	if leaseInfo != nil {
		l = LeaseInformation(leaseInfo!)
	}
	return BidInfo(
		name: b.name,
		amount: b.bidAmount,
		bidStatus: "blind",
		bidTypeIdentifier: b.bidTypeIdentifier,
		timestamp: b.timestamp,
		market: "FindLeaseMarket",
		lease:l
	)
}

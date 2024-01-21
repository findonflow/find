import FIND from "../contracts/FIND.cdc"
import Profile from "../contracts/Profile.cdc"
import FindRelatedAccounts from "../contracts/FindRelatedAccounts.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import FindLeaseMarket from "../contracts/FindLeaseMarket.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import EmeraldIdentity from "../contracts/standard/EmeraldIdentity.cdc"
import EmeraldIdentityDapper from "../contracts/standard/EmeraldIdentityDapper.cdc"
import EmeraldIdentityLilico from "../contracts/standard/EmeraldIdentityLilico.cdc"
import TokenForwarding from "../contracts/standard/TokenForwarding.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import Wearables from "../contracts/community/Wearables.cdc"
import Clock from "../contracts/Clock.cdc"

access(all) struct FINDReport{
	access(all) let isDapper: Bool
	access(all) let profile:Profile.UserReport?
	access(all) let bids: [FIND.BidInfo]

	access(all) let leases: [FIND.LeaseInformation]
	access(all) let privateMode: Bool
	access(all) let leasesForSale: {String : SaleItemCollectionReport}
	access(all) let leasesBids: {String : BidItemCollectionReport}
	access(all) let itemsForSale: {String : FindMarket.SaleItemCollectionReport}
	access(all) let marketBids: {String : FindMarket.BidItemCollectionReport}
	access(all) let activatedAccount: Bool


	// This is deprecating, moving to accounts
	access(all) let relatedAccounts: { String: [Address]}

 	access(all) let lostAndFoundTypes: {String : String}
	// This is deprecating, moving to accounts
	// EmeraldID Account Linkage
	access(all) let emeraldIDAccounts : {String : Address}

	access(all) let accounts : [AccountInformation]?

	access(all) let readyForWearables : Bool?

	init(profile: Profile.UserReport?,
		 relatedAccounts: {String: [Address]},
		 bids: [FIND.BidInfo],
		 leases : [FIND.LeaseInformation],
		 privateMode: Bool,
		 leasesForSale: {String : SaleItemCollectionReport},
		 leasesBids: {String : BidItemCollectionReport},
		 itemsForSale: {String : FindMarket.SaleItemCollectionReport},
		 marketBids: {String : FindMarket.BidItemCollectionReport},
		 activatedAccount: Bool,
		 emeraldIDAccounts : {String : Address},
		 isDapper: Bool,
		 accounts: [AccountInformation]?,
		 readyForWearables: Bool?
		 ) {

	  self.lostAndFoundTypes={}
		self.profile=profile
		self.bids=bids
		self.leases=leases
		self.relatedAccounts=relatedAccounts
		self.privateMode=privateMode
		self.leasesForSale=leasesForSale
		self.leasesBids=leasesBids
		self.itemsForSale=itemsForSale
		self.marketBids=marketBids
		self.activatedAccount=activatedAccount
		self.emeraldIDAccounts=emeraldIDAccounts
		self.isDapper=isDapper
		self.accounts=accounts
		self.readyForWearables=readyForWearables
	}
}

access(all) struct AccountInformation {
	access(all) let name: String
	access(all) let address: String
	access(all) let network: String
	access(all) let trusted: Bool
	access(all) let node: String

	init(name: String, address: String, network: String, trusted: Bool, node: String) {
		self.name = name
		self.address = address
		self.network = network
		self.trusted = trusted
		self.node = node
	}
}

access(all) struct NameReport {
	access(all) let status: String
	access(all) let cost: UFix64
	access(all) let owner: Address?
	access(all) let validUntil: UFix64?
	access(all) let lockedUntil: UFix64?
	access(all) let registeredTime: UFix64?

	init(status: String, cost: UFix64, owner: Address?, validUntil: UFix64?, lockedUntil: UFix64?, registeredTime: UFix64? ) {
		self.status=status
		self.cost=cost
		self.owner=owner
		self.validUntil=validUntil
		self.lockedUntil=lockedUntil
		self.registeredTime=registeredTime
	}
}

access(all) struct Report {
	access(all) let FINDReport: FINDReport?
	access(all) let NameReport: NameReport?

	init(FINDReport: FINDReport?, NameReport: NameReport?) {
		self.FINDReport=FINDReport
		self.NameReport=NameReport
	}
}

access(all) fun main(user: String) : Report? {

	var findReport: FINDReport? = nil
	if let address=FIND.resolve(user) {
		let account=getAccount(address)
		if account.balance > 0.0 {

			var isDapper=false
			if let receiver =account.getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver).borrow() {
			 	isDapper=receiver.isInstance(Type<@TokenForwarding.Forwarder>())
			} else {
				if let duc = aaccount.capabilites.get<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)!.borrow() {
					isDapper = duc.isInstance(Type<@TokenForwarding.Forwarder>())
				} else {
					isDapper = false
				}
			}

			let bidCap = account.getCapability<&FIND.BidCollection{FIND.BidCollectionPublic}>(FIND.BidPublicPath)
			let leaseCap = account.getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)
			let profile=account.getCapability<&{Profile.Public}>(Profile.publicPath).borrow()

			let leases = leaseCap.borrow()?.getLeaseInformation() ?? []
			let oldLeaseBid = bidCap.borrow()?.getBids() ?? []

			let find= FindMarket.getFindTenantAddress()
			var items : {String : FindMarket.SaleItemCollectionReport} = FindMarket.getSaleItemReport(tenant:find, address: address, getNFTInfo:true)

			var marketBids : {String : FindMarket.BidItemCollectionReport} = FindMarket.getBidsReport(tenant:find, address: address, getNFTInfo:true)

			let leasesSale : {String : FindLeaseMarket.SaleItemCollectionReport} = FindLeaseMarket.getSaleItemReport(tenant:find, address: address, getLeaseInfo:true)

			let consolidatedLeasesSale = addLeasesSale(leases, leasesSale)

			let leasesBids : {String : FindLeaseMarket.BidItemCollectionReport} = FindLeaseMarket.getBidsReport(tenant:find, address: address, getLeaseInfo:true)

			let consolidatedLeaseBid = addLeasesBid(oldLeaseBid, leasesBids)

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

			/*
			// NFTCatalog Output
			let nftCatalogTypes = FINDNFTCatalog.getCatalogTypeData()
			let types : {String : NFTCatalog.NFTCollectionData} = {}
			for type in FindLostAndFoundWrapper.getSpecificRedeemableTypes(user: address, specificType: Type<@NonFungibleToken.NFT>()) {
				types[type.identifier] = FINDNFTCatalog.getCollectionDataForType(nftTypeIdentifier: type.identifier)
			}
			*/

			let discordID = EmeraldIdentity.getDiscordFromAccount(account: address)
									?? EmeraldIdentityDapper.getDiscordFromAccount(account: address)
									?? EmeraldIdentityLilico.getDiscordFromAccount(account: address)
									?? ""

			let emeraldIDAccounts : {String : Address} = {}
			emeraldIDAccounts["blocto"] = EmeraldIdentity.getAccountFromDiscord(discordID: discordID)
			emeraldIDAccounts["lilico"] = EmeraldIdentityLilico.getAccountFromDiscord(discordID: discordID)
			emeraldIDAccounts["dapper"] = EmeraldIdentityDapper.getAccountFromDiscord(discordID: discordID)

			let accounts : [AccountInformation] = []
			for wallet in ["blocto", "lilico", "dapper"] {
				if let w = emeraldIDAccounts[wallet] {
					accounts.append(
						AccountInformation(
							name: wallet,
							address: w.toString(),
							network: "Flow",
							trusted: true,
							node: "EmeraldID")
					)
				}
			}

			let allAcctsCap = FindRelatedAccounts.getCapability(address)
			if allAcctsCap.check() {
				let allAcctsRef = allAcctsCap.borrow()!
				let allAccts = allAcctsRef.getAllRelatedAccountInfo()
				for acct in allAccts.values {
					// We only verify flow accounts that are mutually linked
					var trusted = false
					if acct.address != nil {
						trusted = allAcctsRef.linked(name: acct.name, network: acct.network, address: acct.address!)
					}
					accounts.append(
						AccountInformation(
							name: acct.name,
							address: acct.stringAddress!,
							network: acct.network,
							trusted: trusted,
							node: "FindRelatedAccounts")
					)
				}
			}

			let wearableAccount = getAuthAccount(address)
			var readyForWearables = true
			let wearablesRef= wearableAccount.borrow<&Wearables.Collection>(from: Wearables.CollectionStoragePath)
			if wearablesRef == nil {
				readyForWearables = false
			}

			let wearablesCap= wearableAccount.getCapability<&Wearables.Collection{NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(Wearables.CollectionPublicPath)
			if !wearablesCap.check() {
				readyForWearables = false
			}

			let wearablesProviderCap= wearableAccount.getCapability<&Wearables.Collection{NonFungibleToken.Provider,NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(Wearables.CollectionPrivatePath)
			if !wearablesCap.check() {
				readyForWearables = false
			}

			findReport = FINDReport(
				profile: profileReport,
				relatedAccounts: FindRelatedAccounts.findRelatedFlowAccounts(address:address),
				bids: oldLeaseBid,
				leases: leases,
				privateMode: profile?.isPrivateModeEnabled() ?? false,
				leasesForSale: consolidatedLeasesSale,
				leasesBids: consolidatedLeaseBid,
				itemsForSale: items,
				marketBids: marketBids,
				activatedAccount: true,
				emeraldIDAccounts: emeraldIDAccounts,
				isDapper:isDapper,
				accounts: accounts,
				readyForWearables: readyForWearables
			)
		} else {
			findReport = FINDReport(
				profile: nil,
				relatedAccounts: {},
				bids: [],
				leases: [],
				privateMode: false,
				leasesForSale: {},
				leasesBids: {},
				itemsForSale: {},
				marketBids: {},
				activatedAccount: false,
				emeraldIDAccounts: {},
				isDapper: false,
				accounts: nil,
				readyForWearables: nil
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
		let findAddr = FIND.getFindNetworkAddress()
		let network = getAuthAccount(findAddr).borrow<&FIND.Network>(from: FIND.NetworkStoragePath)!
		let lease =  network.getLease(user)
		nameReport = NameReport(status: s, cost: cost, owner: lease?.profile?.address, validUntil: lease?.validUntil, lockedUntil: lease?.lockedUntil, registeredTime: lease?.registeredTime)
	}


	return Report(FINDReport: findReport, NameReport: nameReport)
}

// These are for consolidating FIND Lease Sales
access(all) struct SaleItemCollectionReport {
	access(all) let items : [SaleItemInformation]
	access(all) let ghosts: [FindLeaseMarket.GhostListing]

	init(items: [SaleItemInformation], ghosts: [FindLeaseMarket.GhostListing]) {
		self.items=items
		self.ghosts=ghosts
	}

	access(all) combine(_ s: SaleItemCollectionReport?) {
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
		addons: l!.addons
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

access(all) fun SaleItemInformationFromFindLeaseMarket(_ s: FindLeaseMarket.SaleItemCollectionReport) : SaleItemCollectionReport {

	var listing: [SaleItemInformation] = []
	for i in s.items {
		listing.append(SaleItemInformationFromFindLeaseMarket(i))
	}
	return SaleItemCollectionReport(items: listing, ghosts: s.ghosts)

}

access(all) transformLeaseSale(_ leases: [FIND.LeaseInformation]) : {String : SaleItemCollectionReport} {
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

access(all) addLeasesSale(_ leases: [FIND.LeaseInformation], _ sales : {String : FindLeaseMarket.SaleItemCollectionReport}) : {String : SaleItemCollectionReport} {

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

access(all) BidInfoFromFindLeaseMarket(_ b: FindLeaseMarket.BidInfo) : BidInfo {
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

	access(all) combine(_ s: BidItemCollectionReport?) {
		if s == nil {
			return
		}
		self.items.appendAll(s!.items)
		self.ghosts.appendAll(s!.ghosts)
	}
}

access(all) BidReportFromFindLeaseMarket(_ s: FindLeaseMarket.BidItemCollectionReport) : BidItemCollectionReport {

	var listing: [BidInfo] = []
	for i in s.items {
		listing.append(BidInfoFromFindLeaseMarket(i))
	}
	return BidItemCollectionReport(items: listing, ghosts: s.ghosts)

}

access(all) transformLeaseBid(_ leases: [FIND.BidInfo]) : {String : BidItemCollectionReport} {
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

access(all) addLeasesBid(_ leases: [FIND.BidInfo], _ sales : {String : FindLeaseMarket.BidItemCollectionReport}) : {String : BidItemCollectionReport} {

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

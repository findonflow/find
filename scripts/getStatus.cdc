import FIND from "../contracts/FIND.cdc"
import Profile from "../contracts/Profile.cdc"
import FindRelatedAccounts from "../contracts/FindRelatedAccounts.cdc"
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

pub struct FINDReport{
	pub let isDapper: Bool
	pub let profile:Profile.UserReport?
	pub let bids: [FIND.BidInfo]

	pub let leases: [FIND.LeaseInformation]
	pub let privateMode: Bool
	pub let leasesForSale: {String : FindLeaseMarket.SaleItemCollectionReport}
	pub let leasesBids: {String : FindLeaseMarket.BidItemCollectionReport}
	pub let itemsForSale: {String : FindMarket.SaleItemCollectionReport}
	pub let marketBids: {String : FindMarket.BidItemCollectionReport}
	pub let activatedAccount: Bool


	// This is deprecating, moving to accounts
	pub let relatedAccounts: { String: [Address]}

 pub let lostAndFoundTypes: {String : String}
	// This is deprecating, moving to accounts
	// EmeraldID Account Linkage
	pub let emeraldIDAccounts : {String : Address}

	pub let accounts : [AccountInformation]?

	pub let readyForWearables : Bool?

	init(profile: Profile.UserReport?,
		 relatedAccounts: {String: [Address]},
		 bids: [FIND.BidInfo],
		 leases : [FIND.LeaseInformation],
		 privateMode: Bool,
		 leasesForSale: {String : FindLeaseMarket.SaleItemCollectionReport},
		 leasesBids: {String : FindLeaseMarket.BidItemCollectionReport},
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

pub struct AccountInformation {
	pub let name: String
	pub let address: String
	pub let network: String
	pub let trusted: Bool
	pub let node: String

	init(name: String, address: String, network: String, trusted: Bool, node: String) {
		self.name = name
		self.address = address
		self.network = network
		self.trusted = trusted
		self.node = node
	}
}

pub struct NameReport {
	pub let status: String
	pub let cost: UFix64
	pub let owner: Address?
	pub let validUntil: UFix64?
	pub let lockedUntil: UFix64?
	pub let registeredTime: UFix64?

	init(status: String, cost: UFix64, owner: Address?, validUntil: UFix64?, lockedUntil: UFix64?, registeredTime: UFix64? ) {
		self.status=status
		self.cost=cost
		self.owner=owner
		self.validUntil=validUntil
		self.lockedUntil=lockedUntil
		self.registeredTime=registeredTime
	}
}

pub struct Report {
	pub let FINDReport: FINDReport?
	pub let NameReport: NameReport?

	init(FINDReport: FINDReport?, NameReport: NameReport?) {
		self.FINDReport=FINDReport
		self.NameReport=NameReport
	}
}

pub fun main(user: String) : Report? {

	var findReport: FINDReport? = nil
	if let address=FIND.resolve(user) {
		let account=getAccount(address)
		if account.balance > 0.0 {

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

			let bidCap = account.getCapability<&FIND.BidCollection{FIND.BidCollectionPublic}>(FIND.BidPublicPath)
			let leaseCap = account.getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)
			let profile=account.getCapability<&{Profile.Public}>(Profile.publicPath).borrow()

			let find= FindMarket.getFindTenantAddress()
			let findLease= FindMarket.getTenantAddress("findLease")!
			var items : {String : FindMarket.SaleItemCollectionReport} = FindMarket.getSaleItemReport(tenant:find, address: address, getNFTInfo:true)

			if items.length == 0 {
				if let findDapper= FindMarket.getTenantAddress("find_dapper") {
					items = FindMarket.getSaleItemReport(tenant:findDapper, address: address, getNFTInfo:true)
				}
			}

			var marketBids : {String : FindMarket.BidItemCollectionReport} = FindMarket.getBidsReport(tenant:find, address: address, getNFTInfo:true)

			if marketBids.length == 0 {
				if let findDapper = FindMarket.getTenantAddress("find_dapper") {
					marketBids = FindMarket.getBidsReport(tenant:findDapper, address: address, getNFTInfo:true)
				}
			}

			let leasesSale : {String : FindLeaseMarket.SaleItemCollectionReport} = FindLeaseMarket.getSaleItemReport(tenant:findLease, address: address, getLeaseInfo:true)

			let leasesBids : {String : FindLeaseMarket.BidItemCollectionReport} = FindLeaseMarket.getBidsReport(tenant:findLease, address: address, getLeaseInfo:true)

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

			let wearablesCap= wearableAccount.getCapability<&Wearables.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(Wearables.CollectionPublicPath)
			if !wearablesCap.check() {
				readyForWearables = false
			}

			let wearablesProviderCap= wearableAccount.getCapability<&Wearables.Collection{NonFungibleToken.Provider,NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(Wearables.CollectionPrivatePath)
			if !wearablesCap.check() {
				readyForWearables = false
			}

			findReport = FINDReport(
				profile: profileReport,
				relatedAccounts: FindRelatedAccounts.findRelatedFlowAccounts(address:address),
				bids: bidCap.borrow()?.getBids() ?? [],
				leases: leaseCap.borrow()?.getLeaseInformation() ?? [],
				privateMode: profile?.isPrivateModeEnabled() ?? false,
				leasesForSale: leasesSale,
				leasesBids: leasesBids,
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


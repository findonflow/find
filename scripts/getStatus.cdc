import FIND from "../contracts/FIND.cdc"
import Profile from "../contracts/Profile.cdc"
import RelatedAccounts from "../contracts/RelatedAccounts.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import FindLeaseMarket from "../contracts/FindLeaseMarket.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FindLostAndFoundWrapper from "../contracts/FindLostAndFoundWrapper.cdc"
import NFTCatalog from "../contracts/standard/NFTCatalog.cdc"
import EmeraldIdentity from "../contracts/standard/EmeraldIdentity.cdc"
import EmeraldIdentityDapper from "../contracts/standard/EmeraldIdentityDapper.cdc"
import EmeraldIdentityLilico from "../contracts/standard/EmeraldIdentityLilico.cdc"
import TokenForwarding from "../contracts/standard/TokenForwarding.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"

pub struct FINDReport{
	pub let isDapper: Bool
	pub let profile:Profile.UserReport?
	pub let bids: [FIND.BidInfo]
	pub let relatedAccounts: { String: Address}
	pub let leases: [FIND.LeaseInformation]
	pub let privateMode: Bool
	pub let leasesForSale: {String : FindLeaseMarket.SaleItemCollectionReport}
	pub let leasesBids: {String : FindLeaseMarket.BidItemCollectionReport}
	pub let itemsForSale: {String : FindMarket.SaleItemCollectionReport}
	pub let marketBids: {String : FindMarket.BidItemCollectionReport}
	pub let activatedAccount: Bool 

	// NFT Catalog outputs
	pub let lostAndFoundTypes: {String : NFTCatalog.NFTCollectionData}

	// EmeraldID Account Linkage 
	pub let emeraldIDAccounts : {String : Address}


	init(profile: Profile.UserReport?, 
		 relatedAccounts: {String: Address}, 
		 bids: [FIND.BidInfo], 
		 leases : [FIND.LeaseInformation], 
		 privateMode: Bool, 
		 leasesForSale: {String : FindLeaseMarket.SaleItemCollectionReport}, 
		 leasesBids: {String : FindLeaseMarket.BidItemCollectionReport}, 
		 itemsForSale: {String : FindMarket.SaleItemCollectionReport}, 
		 marketBids: {String : FindMarket.BidItemCollectionReport}, 
		 activatedAccount: Bool, 
		 lostAndFoundTypes: {String : NFTCatalog.NFTCollectionData}, 
		 emeraldIDAccounts : {String : Address},
		 isDapper: Bool
		 ) {

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
		self.lostAndFoundTypes=lostAndFoundTypes
		self.emeraldIDAccounts=emeraldIDAccounts
		self.isDapper=isDapper
	}
}

pub struct NameReport {
	pub let status: String 
	pub let cost: UFix64 

	init(status: String, cost: UFix64) {
		self.status=status 
		self.cost=cost
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

			let receiver =account.getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver).borrow()!
			let isDapper=receiver.isInstance(Type<@TokenForwarding.Forwarder>())

			let bidCap = account.getCapability<&FIND.BidCollection{FIND.BidCollectionPublic}>(FIND.BidPublicPath)
			let leaseCap = account.getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)
			let profile=account.getCapability<&{Profile.Public}>(Profile.publicPath).borrow()

			let find= FindMarket.getFindTenantAddress()
			let findLease= FindMarket.getTenantAddress("findLease")!
			let items : {String : FindMarket.SaleItemCollectionReport} = FindMarket.getSaleItemReport(tenant:find, address: address, getNFTInfo:true)

			let marketBids : {String : FindMarket.BidItemCollectionReport} = FindMarket.getBidsReport(tenant:find, address: address, getNFTInfo:true)

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

			// NFTCatalog Output 
			let nftCatalogTypes = FINDNFTCatalog.getCatalogTypeData()
			let types : {String : NFTCatalog.NFTCollectionData} = {}
			for type in FindLostAndFoundWrapper.getSpecificRedeemableTypes(user: address, specificType: Type<@NonFungibleToken.NFT>()) {
				types[type.identifier] = FINDNFTCatalog.getCollectionDataForType(nftTypeIdentifier: type.identifier)
			}

			let discordID = EmeraldIdentity.getDiscordFromAccount(account: address) 
									?? EmeraldIdentityDapper.getDiscordFromAccount(account: address) 
									?? EmeraldIdentityLilico.getDiscordFromAccount(account: address)
									?? ""

			let emeraldIDAccounts : {String : Address} = {}
			emeraldIDAccounts["blocto"] = EmeraldIdentity.getAccountFromDiscord(discordID: discordID)
			emeraldIDAccounts["lilico"] = EmeraldIdentityLilico.getAccountFromDiscord(discordID: discordID)
			emeraldIDAccounts["dapper"] = EmeraldIdentityDapper.getAccountFromDiscord(discordID: discordID)
			
			findReport = FINDReport(
				profile: profileReport,
				relatedAccounts: RelatedAccounts.findRelatedFlowAccounts(address:address),
				bids: bidCap.borrow()?.getBids() ?? [],
				leases: leaseCap.borrow()?.getLeaseInformation() ?? [],
				privateMode: profile?.isPrivateModeEnabled() ?? false,
				leasesForSale: leasesSale, 
				leasesBids: leasesBids,
				itemsForSale: items,
				marketBids: marketBids,
				activatedAccount: true, 
				lostAndFoundTypes: types, 
				emeraldIDAccounts: emeraldIDAccounts,
				isDapper:isDapper
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
				lostAndFoundTypes: {}, 
				emeraldIDAccounts: {},
				isDapper: false
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
		nameReport = NameReport(status: s, cost: cost)
	}
	

	return Report(FINDReport: findReport, NameReport: nameReport)
}



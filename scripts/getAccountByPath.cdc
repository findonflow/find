import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import Profile from "../contracts/Profile.cdc"
import FIND from "../contracts/FIND.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FindLeaseMarketSale from "../contracts/FindLeaseMarketSale.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
import FindUtils from "../contracts/FindUtils.cdc"
import FlovatarMarketplace from "../contracts/community/FlovatarMarketplace.cdc"
import NFTStorefront from "../contracts/standard/NFTStorefront.cdc"
import NFTStorefrontV2 from "../contracts/standard/NFTStorefrontV2.cdc"

pub let banned : {StoragePath : Bool} = {
    /storage/FantastecNFTCollection: true,
    /storage/FantastecNFTMinter: true,
    /storage/jambbLaunchCollectiblesCollection: true,
    /storage/jambbLaunchCollectiblesMinter: true,
    /storage/RacingTimeCollection: true,
    /storage/RacingTimeMinter: true,
    /storage/MusicBlockCollection: true,
    /storage/MusicBlockMinter: true,
    /storage/SupportUkraineCollectionV10: true,
    /storage/SupportUkraineMinterV10: true,
    /storage/DropzTokenCollection: true,
    /storage/DropzTokenAdmin: true,
    /storage/TokenLendingUserCertificate001: true,
    /storage/TokenLendingPlaceMinterProxy001: true,
    /storage/TokenLendingPlaceAdmin: true,
    /storage/TokenLendingPlace001: true,
    /storage/BnGNFTCollection: true,
    /storage/FuseCollectiveCollection: true,
    /storage/NFTLXKickCollection: true,
    /storage/NFTLXKickMinter: true,
    /storage/revvTeleportCustodyAdmin: true,
	/storage/ZayTraderCollection: true,
	/storage/RaribleNFTCollection: true,
	/storage/LibraryPassCollection: true
}
pub fun main(user: String, targetPaths: [String]): AnyStruct {
	let addr = FIND.resolve(user)
	// if address cannot be resolved, we return the name status only
	var nameStatus : NameReport? = nil
	if FIND.validateFindName(user) {
		nameStatus = getNameStatus(user)
	}

    let authAccount: AuthAccount = getAuthAccount(addr!)
	// if balance is 0.0, it is not a valid address. return not active
	if authAccount.balance == 0.0 {
		return Report(
			Account: authAccount,
			NFT: {},
			FT: {},
			Profile: nil,
			Leases: {},
			Resource: {},
			Listing: {},
			NameStatus: nameStatus,
			)
	}

    let nfts: {StoragePath: NFT} = {}
	let fts: {StoragePath: FT} = {}
	var userProfile: Profile.UserReport? = nil
	var leases: {String : LeaseInformation} = {}
	var leaseBids: {String : [NameBid]} = {}
	var resources: {StoragePath : Type} = {}

	var listings: {String : [UInt64]} = {}

    let iterateFunc: ((AuthAccount, StoragePath): Bool) = fun (acct: AuthAccount, path: StoragePath): Bool {
		if banned.containsKey(path) {
			return true
		}

		if !targetPaths.contains(path.toString()) {
			return true
		}

		var type = acct.type(at: path)!

		// NFT
        if type.isSubtype(of: Type<@NonFungibleToken.Collection>()) {
			let collection = authAccount.borrow<&NonFungibleToken.Collection>(from: path)!
			let number = collection.ownedNFTs.length
			nfts[path] = NFT(
				path: path,
				type: type,
				number: number,
				ids: collection.ownedNFTs.keys
				)
			return true
        }
		// FT
        if type.isSubtype(of: Type<@FungibleToken.Vault>()) {
			let vault = authAccount.borrow<&FungibleToken.Vault>(from: path)!
			fts[path] = FT(
				path: path,
				type: type,
				balance: vault.balance,
				)
			return true
        }
		// Find Profile
		// Each user should only have one profile set up
		// At the moment let's not consider the weird / edge cases
        if type.isSubtype(of: Type<@Profile.User>()) {
			if userProfile != nil {
				// return true means continue iteration here
				return true
			}
			let profile = authAccount.borrow<&Profile.User>(from: path)!
			var profileReport = profile.asReport()
			if profileReport != nil && profileReport.findName != FIND.reverseLookup(addr!) {
				profileReport = Profile.UserReport(
					findName: "",
					address: profileReport.address,
					name: profileReport.name,
					gender: profileReport.gender,
					description: profileReport.description,
					tags: profileReport.tags,
					avatar: profileReport.avatar,
					links: profileReport.links,
					wallets: profileReport.wallets,
					following: profileReport.following,
					followers: profileReport.followers,
					allowStoringFollowers: profileReport.allowStoringFollowers,
					createdAt: profileReport.createdAt
				)
			}
			userProfile = profileReport
			return true
        }

		// FIND Leases
        if type.isSubtype(of: Type<@FIND.LeaseCollection>()) {
			let leaseCol = authAccount.borrow<&FIND.LeaseCollection>(from: path)!
			let info = leaseCol.getLeaseInformation()
			for l in info {
				leases[l.name] = LeaseInformation(l)
			}
			return true
        }

		// FIND Leases Bid (FUSD / Non-Dapper)
		if type.isSubtype(of: Type<@FIND.BidCollection>()) {
			let bidCol = authAccount.borrow<&FIND.BidCollection>(from: path)!
			let bids = bidCol.getBids()
			for bid in bids {
				let lb = leaseBids[bid.name] ?? []
				lb.append(NameBid(
					name: bid.name,
					ft: FTInfo(FTRegistry.getFTInfo("FUSD")!),
					tenant: "find",
					tenantAddress: nil
					)
				)
			}
			return true
        }

		// FIND Leases Sale (Dapper)
		// need to expose getSaleItem and getBidItem to make this work
        // if type.isSubtype(of: Type<@{FindLeaseMarket.SaleItemCollectionPublic}>()) {
			// let saleCol = authAccount.borrow<&{FindLeaseMarket.SaleItemCollectionPublic}>(from: path)!
        if type.isSubtype(of: Type<@FindLeaseMarketSale.SaleItemCollection>()) {
			let saleCol = authAccount.borrow<&FindLeaseMarketSale.SaleItemCollection>(from: path)!
			let saleNames = saleCol.getNameSales()
			for name in saleNames {
				let saleItem = saleCol.borrow(name)
				leases[name]?.addSale(saleItem)
			}
			return true
        }

        if type.isSubtype(of: Type<@FlovatarMarketplace.SaleCollection>()) {
			let saleCol = authAccount.borrow<&FlovatarMarketplace.SaleCollection>(from: path)!
			listings["Flovatar"] = saleCol.getFlovatarIDs()
			listings["FlovatarComponent"] = saleCol.getFlovatarComponentIDs()
			return true
        }

        if type.isSubtype(of: Type<@NFTStorefront.Storefront>()) {
			let saleCol = authAccount.borrow<&NFTStorefront.Storefront>(from: path)!
			listings["StoreFront"] = saleCol.getListingIDs()
			return true
		}

        if type.isSubtype(of: Type<@NFTStorefrontV2.Storefront>()) {
			let saleCol = authAccount.borrow<&NFTStorefrontV2.Storefront>(from: path)!
			listings["StoreFrontV2"] = saleCol.getListingIDs()
			return true
		}

        if type.isSubtype(of: Type<@AnyResource>()) {
			resources[path] = authAccount.borrow<&AnyResource>(from: path)!.getType()
		}

        if type.isSubtype(of: Type<AnyStruct>()) {
			resources[path] = authAccount.borrow<&AnyStruct>(from: path)!.getType()
		}

        return true
    }

	let storagePaths : [StoragePath] = []
	for targetPath in targetPaths {
		storagePaths.append(StoragePath(identifier: targetPath.slice(from: "/storage/".length, upTo: targetPath.length))!)
	}

	var i = 0
    while i < targetPaths.length && iterateFunc(authAccount, storagePaths[i])  {
		i = i + 1
	}

    return Report(
		Account: authAccount,
		NFT: nfts,
		FT: fts,
		Profile: userProfile,
		Leases: leases,
		Resource: resources,
		Listing: listings,
		NameStatus: nameStatus
	)
}

pub fun getNameStatus(_ name: String) : NameReport? {
	if FIND.validateFindName(name) {
		let status = FIND.status(name)
		let cost=FIND.calculateCost(name)
		var s="TAKEN"
		if status.status == FIND.LeaseStatus.FREE {
			s="FREE"
		} else if status.status == FIND.LeaseStatus.LOCKED {
			s="LOCKED"
		}
		let findAddr = FIND.getFindNetworkAddress()
		let network = getAuthAccount(findAddr).borrow<&FIND.Network>(from: FIND.NetworkStoragePath)!
		let lease =  network.getLease(name)
		return NameReport(status: s, cost: cost, owner: lease?.profile?.address, validUntil: lease?.validUntil, lockedUntil: lease?.lockedUntil, registeredTime: lease?.registeredTime)
	}
	return nil
}


pub struct Report {
	pub var StorageUsed: UInt64
	pub var StorageCapacity: UInt64
	pub var StorageAvailable: UInt64
	pub var AccountBalance: UFix64
	pub let NFT : {StoragePath : NFT}
	pub let FT : {StoragePath : FT}
	pub let Profile: Profile.UserReport?
	pub let Leases: {String : LeaseInformation}
	pub let Resource: {StoragePath : AnyStruct}
	pub let Listing: {String : [UInt64]}
	pub let NameStatus: NameReport?

	pub let CurrentTime: UFix64

	init(
		Account: AuthAccount,
		NFT : {StoragePath : NFT},
		FT : {StoragePath : FT},
		Profile: Profile.UserReport?,
		Leases: {String : LeaseInformation},
		Resource: {StoragePath : AnyStruct},
		Listing: {String : [UInt64]},
		NameStatus: NameReport?
	) {

		self.AccountBalance = Account.balance
		self.StorageUsed = 0
		self.StorageCapacity = 0
		self.StorageAvailable = 0

		if self.AccountBalance != 0.0 {
			self.StorageUsed=Account.storageUsed
			self.StorageCapacity=Account.storageCapacity
			self.StorageAvailable=0
			if Account.storageCapacity > Account.storageUsed {
				self.StorageAvailable = Account.storageCapacity - Account.storageUsed
			}
		}

		self.NFT=NFT
		self.FT=FT
		self.Profile=Profile
		self.Leases=Leases
		self.Resource=Resource
		self.Listing=Listing
		self.NameStatus=NameStatus
		self.CurrentTime=getCurrentBlock().timestamp
	}
}

pub struct NameReport {
	pub let status: String
	pub let cost: UFix64
	pub let owner: Address?
	pub let validUntil: UFix64?
	pub let lockedUntil: UFix64?
	pub let registeredTime: UFix64?

	init(
		status: String,
		cost: UFix64,
		owner: Address?,
		validUntil: UFix64?,
		lockedUntil: UFix64?,
		registeredTime: UFix64?
	) {
		self.status=status
		self.cost=cost
		self.owner=owner
		self.validUntil=validUntil
		self.lockedUntil=lockedUntil
		self.registeredTime=registeredTime
	}
}

pub struct NFT {
	pub let path: StoragePath
	pub let type: String
	pub let number: Int
	pub let ids: [UInt64]
	pub var catalogData: CatalogData?

	init(
		path: StoragePath,
		type: Type,
		number: Int,
		ids: [UInt64]
	) {
		self.path=path
		self.type=type.identifier
		self.number=number
		self.ids=ids
		self.catalogData=nil
		let nftType = FindUtils.trimSuffix(type.identifier, suffix: "Collection")
		if let cd = FINDNFTCatalog.getMetadataFromType(CompositeType(nftType.concat("NFT"))!) {
			self.catalogData = CatalogData(
				contractName : cd.contractName,
				contractAddress : cd.contractAddress,
				collectionDisplay: cd.collectionDisplay,
			)
		}

	}
}

pub struct CatalogData {
	pub let contractName : String
	pub let contractAddress : Address
	pub let collectionDisplay: MetadataViews.NFTCollectionDisplay

	init(
		contractName : String,
		contractAddress : Address,
		collectionDisplay: MetadataViews.NFTCollectionDisplay,
	) {
		self.contractName=contractName
		self.contractAddress=contractAddress
		self.collectionDisplay=collectionDisplay
	}
}

pub struct FT {
	pub let path: StoragePath
	pub let type: String
	pub let balance: UFix64
	pub var detail: FTInfo?

	init(
		path: StoragePath,
		type: Type,
		balance: UFix64,
	) {
		self.path=path
		self.type=type.identifier
		self.balance=balance
		self.detail=nil
		if let i = FTRegistry.getFTInfo(type.identifier) {
			self.detail = FTInfo(i)
		}
	}
}

pub struct LeaseInformation {
	pub var name: String
	pub var address: Address
	pub var cost: UFix64
	pub var status: String
	pub var validUntil: UFix64
	pub var lockedUntil: UFix64
	pub var sales: [NameSale]
	pub var auctions: [NameAuction]
	pub var addons: [String]

	init(_ i: FIND.LeaseInformation) {
		self.name = i.name
		self.address = i.address
		self.cost = i.cost
		self.status = i.status
		self.validUntil = i.validUntil
		self.lockedUntil = i.lockedUntil
		self.sales = []
		if i.salePrice != nil {
			self.sales.append(
				NameSale(
					salePrice: i.salePrice!,
					ft: FTInfo(FTRegistry.getFTInfo("FUSD")!),
					tenant: "find",
					tenantAddress: nil
				)
			)
		}
		self.auctions = []
		if i.auctionStartPrice != nil {
			self.auctions.append(
				NameAuction(
					latestBid: i.latestBid,
					auctionStartPrice: i.auctionStartPrice,
					auctionEnds: i.auctionEnds,
					latestBidBy: i.latestBidBy,
					auctionReservePrice: i.auctionReservePrice,
					extensionOnLateBid: i.extensionOnLateBid,
					ft: FTInfo(FTRegistry.getFTInfo("FUSD")!),
					tenant: "find",
					tenantAddress: nil
				)
			)
		}
		self.addons = i.addons
	}

	pub fun addSale(_ s: &FindLeaseMarketSale.SaleItem) {
			self.sales.append(
				NameSale(
					salePrice: s.getBalance(),
					ft: FTInfo(FTRegistry.getFTInfo(s.getFtType().identifier)!),
					// hard code it as find for now
					tenant: "find",
					tenantAddress: nil
				)
			)
	}
}

pub struct NameSale {
	pub let salePrice: UFix64
	pub let tenant: String
	pub let tenantAddress: Address?
	pub let ft: FTInfo

	init(
		salePrice: UFix64,
		ft: FTInfo,
		tenant: String,
		tenantAddress: Address?
	) {
		self.salePrice=salePrice
		self.ft=ft
		self.tenant=tenant
		self.tenantAddress=tenantAddress
	}
}

pub struct NameAuction {
	pub let latestBid: UFix64?
	pub let auctionStartPrice: UFix64?
	pub let auctionEnds: UFix64?
	pub let latestBidBy: Address?
	pub var latestBidByName: String?
	pub let auctionReservePrice: UFix64?
	pub let extensionOnLateBid: UFix64?
	pub let ft: FTInfo
	pub let tenant: String
	pub let tenantAddress: Address?

	init(
		latestBid: UFix64?,
		auctionStartPrice: UFix64?,
		auctionEnds: UFix64?,
		latestBidBy: Address?,
		auctionReservePrice: UFix64?,
		extensionOnLateBid: UFix64?,
		ft: FTInfo,
		tenant: String,
		tenantAddress: Address?
	) {
		self.latestBid=latestBid
		self.auctionStartPrice=auctionStartPrice
		self.auctionEnds=auctionEnds
		self.latestBidBy=latestBidBy
		self.latestBidByName=nil
		if latestBidBy != nil {
			self.latestBidByName=FIND.reverseLookup(latestBidBy!)
		}
		self.auctionReservePrice=auctionReservePrice
		self.extensionOnLateBid=extensionOnLateBid
		self.ft=ft
		self.tenant=tenant
		self.tenantAddress=tenantAddress
	}
}

pub struct NameBid {
	pub let name: String
	pub let ft: FTInfo
	pub let tenant: String
	pub let tenantAddress: Address?

	init(
		name: String,
		ft: FTInfo,
		tenant: String,
		tenantAddress: Address?,
	) {
		self.name=name
		self.ft=ft
		self.tenant=tenant
		self.tenantAddress=tenantAddress
	}
}

pub struct FTInfo {
	pub let type: String
	pub let alias: String
	pub let icon: String?
	pub let tag: [String]

	init(
		_ i: FTRegistry.FTInfo
	) {
		self.type=i.type.identifier
		self.alias=i.alias
		self.icon=i.icon
		self.tag=i.tag
	}
}

pub struct NFTSale {

	pub let category : String
	pub let number : Int

	init(
		category: String,
		number: Int
	) {
		self.category = category
		self.number = number
	}

}

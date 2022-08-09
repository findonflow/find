import FungibleToken from "./standard/FungibleToken.cdc"
import FindViews from "../contracts/FindViews.cdc"
import FIND from "./FIND.cdc"
import Profile from "./Profile.cdc"
import Clock from "./Clock.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import FindRulesCache from "../contracts/FindRulesCache.cdc"

pub contract FindLeaseMarket {

	access(contract) let  saleItemTypes : [Type]
	access(contract) let  saleItemCollectionTypes : [Type]
	access(contract) let  marketBidTypes : [Type]
	access(contract) let  marketBidCollectionTypes : [Type]

	pub event RoyaltyPaid(tenant:String, leaseName: String, saleID: UInt64, address:Address, findName:String?, royaltyName:String, amount: UFix64, vaultType:String, leaseInfo:LeaseInfo)
	pub event RoyaltyCouldNotBePaid(tenant:String, leaseName: String, saleID: UInt64, address:Address, findName:String?, royaltyName:String, amount: UFix64, vaultType:String, leaseInfo:LeaseInfo, residualAddress: Address)
	pub event FindBlockRules(tenant: String, ruleName: String, ftTypes:[String], listingTypes:[String], status:String)
	pub event TenantAllowRules(tenant: String, ruleName: String, ftTypes:[String], listingTypes:[String], status:String)
	pub event FindCutRules(tenant: String, ruleName: String, cut:UFix64, ftTypes:[String], listingTypes:[String], status:String)

	// ========================================

	/* Get Tenant */
	pub fun getTenant(_ tenant: Address) : &FindMarket.Tenant{FindMarket.TenantPublic} {
		return FindMarket.getTenantCapability(tenant)!.borrow()!
	}

	pub fun getSaleItemTypes() : [Type] {
		return self.saleItemTypes
	}

	/* Get SaleItemCollections */
	pub fun getSaleItemCollectionTypes() : [Type] {
		return self.saleItemCollectionTypes
	}

	pub fun getSaleItemCollectionCapabilities(tenantRef: &FindMarket.Tenant{FindMarket.TenantPublic}, address: Address) : [Capability<&{FindLeaseMarket.SaleItemCollectionPublic}>] {
		var caps : [Capability<&{FindLeaseMarket.SaleItemCollectionPublic}>] = []
		for type in self.getSaleItemCollectionTypes() {
			if type != nil {
				let cap = getAccount(address).getCapability<&{FindLeaseMarket.SaleItemCollectionPublic}>(tenantRef.getPublicPath(type))
				if cap.check() {
					caps.append(cap)
				}
			}
		}
		return caps
	}

	pub fun getSaleItemCollectionCapability(tenantRef: &FindMarket.Tenant{FindMarket.TenantPublic}, marketOption: String, address: Address) : Capability<&{FindLeaseMarket.SaleItemCollectionPublic}> {
		for type in self.getSaleItemCollectionTypes() {
			if FindMarket.getMarketOptionFromType(type) == marketOption{
				let cap = getAccount(address).getCapability<&{FindLeaseMarket.SaleItemCollectionPublic}>(tenantRef.getPublicPath(type))
				return cap
			}
		}
		panic("Cannot find market option : ".concat(marketOption))
	}



	/* Get Sale Reports and Sale Item */
	pub fun assertOperationValid(tenant: Address, name: String, marketOption: String) : &{SaleItem} {

		let tenantRef=self.getTenant(tenant)
		let address=FIND.lookupAddress(name) ?? panic("Name is not owned by anyone. Name : ".concat(name))
		let collectionCap = self.getSaleItemCollectionCapability(tenantRef: tenantRef, marketOption: marketOption, address: address)
		let optRef = collectionCap.borrow() 
		if optRef == nil {
			panic("Account not properly set up, cannot borrow sale item collection")
		}
		let ref=optRef!
		let item=ref.borrowSaleItem(name)
		if !item.checkPointer() {
			panic("this is a ghost listing")
		} 

		return item
	}

	/* Get Sale Reports and Sale Item */
	pub fun getSaleInformation(tenant: Address, name: String, marketOption: String, getLeaseInfo: Bool) : FindLeaseMarket.SaleItemInformation? {
		let address = FIND.lookupAddress(name) ?? panic("Name is not owned by anyone. Name : ".concat(name))
		let tenantRef=self.getTenant(tenant)
		let info = self.checkSaleInformation(tenantRef: tenantRef, marketOption:marketOption, address: address, name: name, getGhost: false, getLeaseInfo: getLeaseInfo)
		if info.items.length > 0 {
			return info.items[0]
		}
		return nil
	}

	pub fun getSaleItemReport(tenant:Address, address: Address, getLeaseInfo: Bool) : {String : FindLeaseMarket.SaleItemCollectionReport} {
		let tenantRef = self.getTenant(tenant)
		var report : {String : FindLeaseMarket.SaleItemCollectionReport} = {}
		for type in self.getSaleItemCollectionTypes() {
			let marketOption = FindMarket.getMarketOptionFromType(type)
			let returnedReport = self.checkSaleInformation(tenantRef: tenantRef, marketOption:marketOption, address: address, name: nil, getGhost: true, getLeaseInfo: getLeaseInfo)
			if returnedReport.items.length > 0 || returnedReport.ghosts.length > 0 {
				report[marketOption] = returnedReport
			}
		}
		return report
	}

	pub fun getSaleItems(tenant:Address, name: String, getLeaseInfo: Bool) : {String : FindLeaseMarket.SaleItemCollectionReport} {
		let address = FIND.lookupAddress(name) ?? panic("Name is not owned by anyone. Name : ".concat(name))
		let tenantRef = self.getTenant(tenant)
		var report : {String : FindLeaseMarket.SaleItemCollectionReport} = {}
		for type in self.getSaleItemCollectionTypes() {
			let marketOption = FindMarket.getMarketOptionFromType(type)
			let returnedReport = self.checkSaleInformation(tenantRef: tenantRef, marketOption:marketOption, address: address, name: name, getGhost: true, getLeaseInfo: getLeaseInfo)
			if returnedReport.items.length > 0 || returnedReport.ghosts.length > 0 {
				report[marketOption] = returnedReport
			}
		}
		return report
	}

	pub fun getLeaseListing(tenant:Address, name: String, getLeaseInfo: Bool) : {String : FindLeaseMarket.SaleItemInformation} {
		let address = FIND.lookupAddress(name) ?? panic("Name is not owned by anyone. Name : ".concat(name))
		let tenantRef = self.getTenant(tenant)
		var report : {String : FindLeaseMarket.SaleItemInformation} = {}
		for type in self.getSaleItemCollectionTypes() {
			let marketOption = FindMarket.getMarketOptionFromType(type)
			let returnedReport = self.checkSaleInformation(tenantRef: tenantRef, marketOption:marketOption, address: address, name: name, getGhost: true, getLeaseInfo: getLeaseInfo)
			if returnedReport.items.length > 0 || returnedReport.ghosts.length > 0 {
				report[marketOption] = returnedReport.items[0]
			}
		}
		return report
	}

	access(contract) fun checkSaleInformation(tenantRef: &FindMarket.Tenant{FindMarket.TenantPublic}, marketOption: String, address: Address, name: String?, getGhost: Bool, getLeaseInfo: Bool) : FindLeaseMarket.SaleItemCollectionReport {
		let ghost: [FindLeaseMarket.GhostListing] =[]
		let info: [FindLeaseMarket.SaleItemInformation] =[]
		let collectionCap = self.getSaleItemCollectionCapability(tenantRef: tenantRef, marketOption: marketOption, address: address)
		let optRef = collectionCap.borrow() 
		if optRef == nil {
			return FindLeaseMarket.SaleItemCollectionReport(items: info, ghosts: ghost)
		}
		let ref=optRef!

		var listName : [String]= []
		if let leaseName = name{
			if !ref.containsNameSale(leaseName) {
				return FindLeaseMarket.SaleItemCollectionReport(items: info, ghosts: ghost)
			}
			listName=[leaseName]
		} else {
			listName = ref.getNameSales()
		}

		let listingType = ref.getListingType()

		for leaseName in listName {
			//if this id is not present in this Market option then we just skip it
			let item=ref.borrowSaleItem(leaseName)
			if !item.checkPointer() {
				if getGhost {
					ghost.append(FindLeaseMarket.GhostListing(listingType: listingType, name:leaseName))
				}
				continue
			} 
			let stopped=tenantRef.allowedAction(listingType: listingType, nftType: item.getItemType(), ftType: item.getFtType(), action: FindMarket.MarketAction(listing:false, name:"delist item for sale"), seller: address, buyer: nil)
			var status="active"

			if !stopped.allowed && stopped.message == "Seller banned by Tenant" {
				status="banned"
				info.append(FindLeaseMarket.SaleItemInformation(item: item, status: status, leaseInfo: false))
				continue
			}

			if !stopped.allowed {
				status="stopped"
				info.append(FindLeaseMarket.SaleItemInformation(item: item, status: status, leaseInfo: false))
				continue
			}

			let deprecated=tenantRef.allowedAction(listingType: listingType, nftType: item.getItemType(), ftType: item.getFtType(), action: FindMarket.MarketAction(listing:true, name:"delist item for sale"), seller: address, buyer: nil)

			if !deprecated.allowed {
				status="deprecated"
				info.append(FindLeaseMarket.SaleItemInformation(item: item, status: status, leaseInfo: getLeaseInfo))
				continue
			}

			if let validTime = item.getValidUntil() {
				if validTime <= Clock.time() {
					status="ended"
				}
			}
			info.append(FindLeaseMarket.SaleItemInformation(item: item, status: status, leaseInfo: getLeaseInfo))
		}

		return FindLeaseMarket.SaleItemCollectionReport(items: info, ghosts: ghost)
	}

	/* Get Bid Collections */
	pub fun getMarketBidTypes() : [Type] {
		return self.marketBidTypes
	}

	pub fun getMarketBidCollectionTypes() : [Type] {
		return self.marketBidCollectionTypes
	}

	pub fun getMarketBidCollectionCapabilities(tenantRef: &FindMarket.Tenant{FindMarket.TenantPublic}, address: Address) : [Capability<&{FindLeaseMarket.MarketBidCollectionPublic}>] {
		var caps : [Capability<&{FindLeaseMarket.MarketBidCollectionPublic}>] = []
		for type in self.getMarketBidCollectionTypes() {
			let cap = getAccount(address).getCapability<&{FindLeaseMarket.MarketBidCollectionPublic}>(tenantRef.getPublicPath(type))
			if cap.check() {
				caps.append(cap)
			}
		}
		return caps
	}

	pub fun getMarketBidCollectionCapability(tenantRef: &FindMarket.Tenant{FindMarket.TenantPublic}, marketOption: String, address: Address) : Capability<&{FindLeaseMarket.MarketBidCollectionPublic}> {
		for type in self.getMarketBidCollectionTypes() {
			if FindMarket.getMarketOptionFromType(type) == marketOption{
				let cap = getAccount(address).getCapability<&{FindLeaseMarket.MarketBidCollectionPublic}>(tenantRef.getPublicPath(type))
				return cap
			}
		}
		panic("Cannot find market option : ".concat(marketOption))
	}

	pub fun getBid(tenant: Address, address: Address, marketOption: String, name:String, getLeaseInfo: Bool) : FindLeaseMarket.BidInfo? {
		let tenantRef=self.getTenant(tenant)
		let bidInfo = self.checkBidInformation(tenantRef: tenantRef, marketOption: marketOption, address: address, name: name, getGhost: false, getLeaseInfo: getLeaseInfo)
		if bidInfo.items.length > 0 {
			return bidInfo.items[0]
		}
		return nil
	}

	pub fun getBidsReport(tenant:Address, address: Address, getLeaseInfo: Bool) : {String : FindLeaseMarket.BidItemCollectionReport} {
		let tenantRef = self.getTenant(tenant)
		var report : {String : FindLeaseMarket.BidItemCollectionReport} = {}
		for type in self.getMarketBidCollectionTypes() {
			let marketOption = FindMarket.getMarketOptionFromType(type)
			let returnedReport = self.checkBidInformation(tenantRef: tenantRef, marketOption: marketOption, address: address, name: nil, getGhost: true, getLeaseInfo: getLeaseInfo)
			if returnedReport.items.length > 0 || returnedReport.ghosts.length > 0 {
				report[marketOption] = returnedReport
			}
		}
		return report
	}

	access(contract) fun checkBidInformation(tenantRef: &FindMarket.Tenant{FindMarket.TenantPublic}, marketOption: String, address: Address, name: String?, getGhost:Bool, getLeaseInfo: Bool) : FindLeaseMarket.BidItemCollectionReport {
		let ghost: [FindLeaseMarket.GhostListing] =[]
		let info: [FindLeaseMarket.BidInfo] =[]
		let collectionCap = self.getMarketBidCollectionCapability(tenantRef: tenantRef, marketOption: marketOption, address: address)

		let optRef = collectionCap.borrow()
		if optRef==nil {
			return FindLeaseMarket.BidItemCollectionReport(items: info, ghosts: ghost)
		}

		let ref=optRef!

		let listingType = ref.getBidType()
		var listName : [String]= []
		if let leaseName = name{
			if !ref.containsNameBid(leaseName) {
				return FindLeaseMarket.BidItemCollectionReport(items: info, ghosts: ghost)
			}
			listName=[leaseName]
		} else {
			listName = ref.getNameBids()
		}

		for leaseName in listName {

			let bid=ref.borrowBidItem(leaseName)
			let item=self.getSaleInformation(tenant: tenantRef.owner!.address, name: leaseName, marketOption: marketOption, getLeaseInfo: getLeaseInfo)
			if item == nil {
				if getGhost {
					ghost.append(FindLeaseMarket.GhostListing(listingType: listingType, name:leaseName))
				}
				continue
			} 
			let bidInfo = FindLeaseMarket.BidInfo(name: leaseName, bidTypeIdentifier: listingType.identifier,  bidAmount: bid.getBalance(), timestamp: Clock.time(), item:item!)
			info.append(bidInfo)

		}
		return FindLeaseMarket.BidItemCollectionReport(items: info, ghosts: ghost)
	}

	pub fun assertBidOperationValid(tenant: Address, address: Address, marketOption: String, name:String) : &{SaleItem} {

		let tenantRef=self.getTenant(tenant)
		let collectionCap = self.getMarketBidCollectionCapability(tenantRef: tenantRef, marketOption: marketOption, address: address)
		let optRef = collectionCap.borrow() 
		if optRef == nil {
			panic("Account not properly set up, cannot borrow bid item collection. Account address : ".concat(collectionCap.address.toString()))
		}
		let ref=optRef!
		let bidItem=ref.borrowBidItem(name)

		let saleItemCollectionCap = self.getSaleItemCollectionCapability(tenantRef: tenantRef, marketOption: marketOption, address: bidItem.getSellerAddress())
		let saleRef = saleItemCollectionCap.borrow() 
		if saleRef == nil {
			panic("Seller account is not properly set up, cannot borrow sale item collection. Seller address : ".concat(saleItemCollectionCap.address.toString()))
		}
		let sale=saleRef!
		let item=sale.borrowSaleItem(name)
		if !item.checkPointer() {
			panic("this is a ghost listing")
		} 

		return item
	}

	/////// Pointer Section

	pub struct interface LeasePointer {
		pub let name: String
		pub let uuid: UInt64

		pub fun valid() : Bool
		pub fun getUUID() :UInt64
		pub fun getLease() : FIND.LeaseInformation 
		pub fun owner() : Address
		access(contract) fun borrow() : &FIND.LeaseCollection{FIND.LeaseCollectionPublic} 
	}

	pub struct ReadLeasePointer : LeasePointer {
		access(self) let cap: Capability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>
		pub let name: String
		pub let uuid: UInt64

		// Passing in the reference here to ensure that is the owner
		init(name: String) {

			let address = FIND.lookupAddress(name) ?? panic("This lease name is not owned")

			self.cap=getAccount(address).getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)
			self.name=name

			if !self.cap.check() {
				panic("The capability is not valid.")
			}

			self.uuid = self.cap.borrow()!.getLeaseUUID(name)

		}

		access(contract) fun borrow() : &FIND.LeaseCollection{FIND.LeaseCollectionPublic} {
			return self.cap.borrow() ?? panic("The capability of pointer is not linked.")
		}

		pub fun getLease() : FIND.LeaseInformation {
			return self.borrow().getLease(self.name) ?? panic("The owner doesn't hold the lease anymore".concat(self.name))
		}

		pub fun getUUID() :UInt64{
			return self.uuid
		}

		pub fun owner() : Address {
			return self.cap.address
		}

		pub fun valid() : Bool {
			if !self.cap.check() || !self.cap.borrow()!.getNames().contains(self.name) {
				return false
			}

			if Clock.time() > FindLeaseMarket.getNetwork().getLeaseExpireTime(self.name) {
				return false
			}
			return true
		}
	}

	pub struct AuthLeasePointer : LeasePointer {
		access(self) let cap: Capability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>
		pub let name: String
		pub let uuid: UInt64

		// Passing in the reference here to ensure that is the owner
		init(ref:&FIND.LeaseCollection, name: String) {
			self.cap=getAccount(ref.owner!.address).getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)
			self.name=name

			if !ref.getNames().contains(name) {
				panic("Please pass in the corresponding lease collection reference.")
			}

			if !self.cap.check() {
				panic("The capability is not valid.")
			}

			self.uuid = self.cap.borrow()!.getLeaseUUID(name)
		}

		access(contract) fun borrow() : &FIND.LeaseCollection{FIND.LeaseCollectionPublic} {
			return self.cap.borrow() ?? panic("The capability of pointer is not linked.")
		}

		pub fun getLease() : FIND.LeaseInformation {
			return self.borrow().getLease(self.name) ?? panic("The owner doesn't hold the lease anymore".concat(self.name))
		}

		pub fun getUUID() :UInt64{
			return self.uuid
		}

		pub fun valid() : Bool {
			if !self.cap.check() || !self.cap.borrow()!.getNames().contains(self.name) {
				return false
			}

			if Clock.time() > FindLeaseMarket.getNetwork().getLeaseExpireTime(self.name) {
				return false
			}
			return true
		}

		access(account) fun move(to: Address) {
			pre{
				self.valid() : "The lease capability is not valid"
			}
			let receiver = getAccount(to)
			let profile = receiver.getCapability<&{Profile.Public}>(Profile.publicPath)
			let leases = receiver.getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)
			self.borrow().move(name: self.name, profile: profile, to: leases)
		}

		pub fun owner() : Address {
			return self.cap.address
		}

	}

	access(account) fun pay(tenant: String, leaseName: String, saleItem: &{SaleItem}, vault: @FungibleToken.Vault, leaseInfo: LeaseInfo, cuts:FindRulesCache.TenantCuts) {
		let buyer=saleItem.getBuyer()
		let seller=saleItem.getSeller()
		let oldProfile= getAccount(seller).getCapability<&{Profile.Public}>(Profile.publicPath).borrow()!
		let soldFor=vault.balance
		let ftType=vault.getType()

		let ftInfo = FTRegistry.getFTInfoByTypeIdentifier(ftType.identifier)! // If this panic, there is sth wrong in FT set up
		let residualVault = getAccount(FindMarket.residualAddress).getCapability<&{FungibleToken.Receiver}>(ftInfo.receiverPath)

		// Paying to Network
		let network = FindLeaseMarket.getNetwork()
		let networkCutAmount= soldFor * network.getSecondaryCut() 
		let receiver = network.getWallet().address
		let name = FIND.reverseLookup(receiver)

		var walletCheck = true 
		if !network.getWallet().check() { 
			// if the capability is not valid, royalty cannot be paid
			walletCheck = false 
		} else if network.getWallet().borrow()!.isInstance(Type<@Profile.User>()){ 
			// if the capability is valid -> it is a User resource -> check if the wallet is set up.
			let ref = getAccount(receiver).getCapability<&{Profile.Public}>(Profile.publicPath).borrow()! // If this is nil, there shouldn't be a wallet receiver
			walletCheck = ref.hasWallet(ftType.identifier)
		} else if !network.getWallet().borrow()!.isInstance(ftType){ 
			// if the capability is valid -> it is a FT Vault, check if it matches the paying vault type.
			walletCheck = false 
		}

		/* If the royalty receiver check failed */
		if !walletCheck {

			if let receivingVault = getAccount(receiver).getCapability<&{FungibleToken.Receiver}>(ftInfo.receiverPath).borrow() {
				receivingVault.deposit(from: <- vault.withdraw(amount: networkCutAmount))
				emit RoyaltyPaid(tenant:tenant, leaseName: leaseName, saleID: saleItem.uuid, address:receiver, findName: name, royaltyName: "network", amount: networkCutAmount,  vaultType: ftType.identifier, leaseInfo:leaseInfo)
			} else {
				emit RoyaltyCouldNotBePaid(tenant:tenant, leaseName: leaseName, saleID: saleItem.uuid, address:receiver, findName: name, royaltyName: "network", amount: networkCutAmount,  vaultType: ftType.identifier, leaseInfo:leaseInfo, residualAddress: FindMarket.residualAddress)
				residualVault.borrow()!.deposit(from: <- vault.withdraw(amount: networkCutAmount))
			}

		} else {
			/* If the royalty receiver check succeed */
			emit RoyaltyPaid(tenant:tenant, leaseName: leaseName, saleID: saleItem.uuid, address:receiver, findName: name, royaltyName: "network", amount: networkCutAmount,  vaultType: ftType.identifier, leaseInfo:leaseInfo)
			network.getWallet().borrow()!.deposit(from: <- vault.withdraw(amount: networkCutAmount))
		}


		if let findCut =cuts.findCut {
			let cutAmount= soldFor * findCut.cut
			let name = FIND.reverseLookup(findCut.receiver.address)
			emit RoyaltyPaid(tenant: tenant, leaseName: leaseName, saleID: saleItem.uuid, address:findCut.receiver.address, findName: name , royaltyName: "find", amount: cutAmount,  vaultType: ftType.identifier, leaseInfo:leaseInfo)
			let vaultRef = findCut.receiver.borrow() ?? panic("Find Royalty receiving account is not set up properly. Find Royalty account address : ".concat(findCut.receiver.address.toString()))
			vaultRef.deposit(from: <- vault.withdraw(amount: cutAmount))
		}

		if let tenantCut =cuts.tenantCut {
			let cutAmount= soldFor * tenantCut.cut
			let name = FIND.reverseLookup(tenantCut.receiver.address)
			emit RoyaltyPaid(tenant: tenant, leaseName: leaseName, saleID: saleItem.uuid, address:tenantCut.receiver.address, findName: name, royaltyName: "marketplace", amount: cutAmount,  vaultType: ftType.identifier, leaseInfo:leaseInfo)
			let vaultRef = tenantCut.receiver.borrow() ?? panic("Tenant Royalty receiving account is not set up properly. Tenant Royalty account address : ".concat(tenantCut.receiver.address.toString()))
			vaultRef.deposit(from: <- vault.withdraw(amount: cutAmount))
		}

		oldProfile.deposit(from: <- vault)
	}

	//struct to expose information about leases
	pub struct LeaseInfo {
		pub let name: String
		pub let address: Address
		pub let cost: UFix64
		pub let status: String
		pub let validUntil: UFix64
		pub let lockedUntil: UFix64
		pub let addons: [String]

		init(_ pointer: AnyStruct{FindLeaseMarket.LeasePointer}){
			let network = FindLeaseMarket.getNetwork()
			let name = pointer.name
			let status= network.readStatus(name)
			self.name=name
			var s="TAKEN"	
			if status.status == FIND.LeaseStatus.FREE {
				s="FREE"
			} else if status.status == FIND.LeaseStatus.LOCKED {
				s="LOCKED"
			}
			self.status=s
			self.validUntil=network.getLeaseExpireTime(name)
			self.lockedUntil=network.getLeaseLockedUntil(name)
			self.address=status.owner!
			self.cost=network.calculateCost(name)
			if pointer.valid() {
				let lease = pointer.borrow()
				self.addons=lease.getAddon(name: name)
			} else {
				self.addons=[]
			}
		}

	}

	pub resource interface SaleItem {
		//this is the type of sale this is, active, cancelled etc
		pub fun getSaleType(): String
		pub fun getSeller(): Address
		pub fun getBuyer(): Address?

		pub fun getSellerName() : String?
		pub fun getBuyerName() : String?

		pub fun toLeaseInfo() : FindLeaseMarket.LeaseInfo
		pub fun checkPointer() : Bool 
		pub fun getListingType() : Type 
		pub fun getListingTypeIdentifier(): String

		//the Type of the item for sale
		pub fun getItemType(): Type
		//The id of the nft for sale
		pub fun getLeaseName() : String

		pub fun getBalance(): UFix64
		pub fun getAuction(): AuctionItem?
		pub fun getFtType() : Type //The type of FT used for this sale item
		pub fun getValidUntil() : UFix64? //A timestamp that says when this item is valid until

		pub fun getSaleItemExtraField() : {String : AnyStruct}
		pub fun getId() : UInt64
	}

	pub resource interface Bid {
		pub fun getBalance() : UFix64
		pub fun getSellerAddress() : Address 
		pub fun getBidExtraField() : {String : AnyStruct}
	}

	pub struct SaleItemInformation {
		pub let leaseIdentifier: String 
		pub let leaseName: String
		pub let seller: Address
		pub let sellerName: String?
		pub let amount: UFix64?
		pub let bidder: Address?
		pub var bidderName: String?
		pub let listingId: UInt64

		pub let saleType: String
		pub let listingTypeIdentifier: String
		pub let ftAlias: String 
		pub let ftTypeIdentifier: String
		pub let listingValidUntil: UFix64?

		pub var lease: LeaseInfo?
		pub let auction: AuctionItem?
		pub let listingStatus:String
		pub let saleItemExtraField: {String : AnyStruct}

		init(item: &{SaleItem}, status:String, leaseInfo: Bool) {
			self.leaseIdentifier= item.getItemType().identifier
			self.leaseName=item.getLeaseName()
			self.listingStatus=status
			self.saleType=item.getSaleType()
			self.listingTypeIdentifier=item.getListingTypeIdentifier()
			self.listingId=item.getId()
			self.amount=item.getBalance()
			self.bidder=item.getBuyer()
			self.bidderName=item.getBuyerName()
			self.seller=item.getSeller()
			self.sellerName=item.getSellerName()
			self.listingValidUntil=item.getValidUntil()
			self.lease=nil
			if leaseInfo {
				if status != "stopped" {
					self.lease=item.toLeaseInfo()
				}
			}
			let ftIdentifier=item.getFtType().identifier
			self.ftTypeIdentifier=ftIdentifier
			let ftInfo=FTRegistry.getFTInfoByTypeIdentifier(ftIdentifier)
			self.ftAlias=ftInfo?.alias ?? ""

			self.auction=item.getAuction()
			self.saleItemExtraField=item.getSaleItemExtraField()
		}
	}

	pub struct BidInfo{
		pub let name: String
		pub let bidAmount: UFix64
		pub let bidTypeIdentifier: String 
		pub let timestamp: UFix64
		pub let item: SaleItemInformation

		init(name: String, bidTypeIdentifier: String, bidAmount: UFix64, timestamp: UFix64, item:SaleItemInformation) {
			self.name=name
			self.bidAmount=bidAmount
			self.bidTypeIdentifier=bidTypeIdentifier
			self.timestamp=timestamp
			self.item=item
		}
	}

	pub struct AuctionItem {
		//end time
		//current time
		pub let startPrice: UFix64 
		pub let currentPrice: UFix64
		pub let minimumBidIncrement: UFix64 
		pub let reservePrice: UFix64 
		pub let extentionOnLateBid: UFix64 
		pub let auctionEndsAt: UFix64? 
		pub let timestamp: UFix64 

		init(startPrice: UFix64, currentPrice: UFix64, minimumBidIncrement: UFix64, reservePrice: UFix64, extentionOnLateBid: UFix64, auctionEndsAt: UFix64? , timestamp: UFix64){
			self.startPrice = startPrice 
			self.currentPrice = currentPrice
			self.minimumBidIncrement = minimumBidIncrement 
			self.reservePrice = reservePrice
			self.extentionOnLateBid = extentionOnLateBid
			self.auctionEndsAt = auctionEndsAt 
			self.timestamp = timestamp
		}
	}

	pub resource interface SaleItemCollectionPublic {
		pub fun getNameSales(): [String]
		pub fun containsNameSale(_ name: String): Bool
		access(account) fun borrowSaleItem(_ name: String) : &{SaleItem}
		pub fun getListingType() : Type 
	}

	pub resource interface MarketBidCollectionPublic {
		pub fun getNameBids() : [String] 
		pub fun containsNameBid(_ name: String): Bool
		pub fun getBidType() : Type 
		access(account) fun borrowBidItem(_ name: String) : &{Bid}
	}

	pub struct GhostListing{
		//		pub let listingType: Type
		pub let listingTypeIdentifier: String
		pub let name: String


		init(listingType:Type, name:String) {
			//			self.listingType=listingType
			self.listingTypeIdentifier=listingType.identifier
			self.name=name
		}
	}

	pub struct SaleItemCollectionReport {
		pub let items : [FindLeaseMarket.SaleItemInformation] 
		pub let ghosts: [FindLeaseMarket.GhostListing]

		init(items: [SaleItemInformation], ghosts: [GhostListing]) {
			self.items=items
			self.ghosts=ghosts
		}
	}

	pub struct BidItemCollectionReport {
		pub let items : [FindLeaseMarket.BidInfo] 
		pub let ghosts: [FindLeaseMarket.GhostListing]

		init(items: [BidInfo], ghosts: [GhostListing]) {
			self.items=items
			self.ghosts=ghosts
		}
	}

	access(contract) fun getNetwork() : &FIND.Network {
		return FindLeaseMarket.account.borrow<&FIND.Network>(from : FIND.NetworkStoragePath) ?? panic("Network is not up")
	}

	/* Admin Function */
	access(account) fun addSaleItemType(_ type: Type) {
		self.saleItemTypes.append(type)
		FindMarket.addPathMap(type)
		FindMarket.addListingName(type)
	}

	access(account) fun addMarketBidType(_ type: Type) {
		self.marketBidTypes.append(type)
		FindMarket.addPathMap(type)
		FindMarket.addListingName(type)
	}

	access(account) fun addSaleItemCollectionType(_ type: Type) {
		self.saleItemCollectionTypes.append(type)
		FindMarket.addPathMap(type)
		FindMarket.addListingName(type)
	}

	access(account) fun addMarketBidCollectionType(_ type: Type) {
		self.marketBidCollectionTypes.append(type)
		FindMarket.addPathMap(type)
		FindMarket.addListingName(type)
	}

	access(account) fun removeSaleItemType(_ type: Type) {
		var counter = 0 
		while counter < self.saleItemTypes.length {
			if type == self.saleItemTypes[counter] {
				self.saleItemTypes.remove(at: counter)
			}
			counter = counter + 1   
		}
	}

	access(account) fun removeMarketBidType(_ type: Type) {
		var counter = 0 
		while counter < self.marketBidTypes.length {
			if type == self.marketBidTypes[counter] {
				self.marketBidTypes.remove(at: counter)
			}
			counter = counter + 1   
		}
	}

	access(account) fun removeSaleItemCollectionType(_ type: Type) {
		var counter = 0 
		while counter < self.saleItemCollectionTypes.length {
			if type == self.saleItemCollectionTypes[counter] {
				self.saleItemCollectionTypes.remove(at: counter)
			}
			counter = counter + 1   
		}
	}

	access(account) fun removeMarketBidCollectionType(_ type: Type) {
		var counter = 0 
		while counter < self.marketBidCollectionTypes.length {
			if type == self.marketBidCollectionTypes[counter] {
				self.marketBidCollectionTypes.remove(at: counter)
			}
			counter = counter + 1   
		}
	}

	init() {
		
		self.saleItemTypes = []
		self.saleItemCollectionTypes = []
		self.marketBidTypes = []
		self.marketBidCollectionTypes = []

	}

}

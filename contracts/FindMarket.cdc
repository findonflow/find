import FungibleToken from "./standard/FungibleToken.cdc"
import MetadataViews from "./standard/MetadataViews.cdc"
import FindViews from "../contracts/FindViews.cdc"
import Profile from "./Profile.cdc"
import Clock from "./Clock.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"

pub contract FindMarket {
	access(contract) let  pathMap : {String: String}
	access(contract) let  listingName : {String: String}
	access(contract) let  saleItemTypes : [Type]
	access(contract) let  saleItemCollectionTypes : [Type]
	access(contract) let  marketBidTypes : [Type]
	access(contract) let  marketBidCollectionTypes : [Type]

	pub event RoyaltyPaid(tenant:String, id: UInt64, saleID: UInt64, address:Address, findName:String?, royaltyName:String, amount: UFix64, vaultType:String, nft:NFTInfo)
	pub event RoyaltyCouldNotBePaid(tenant:String, id: UInt64, saleID: UInt64, address:Address, findName:String?, royaltyName:String, amount: UFix64, vaultType:String, nft:NFTInfo, residualAddress: Address)
	pub event FindBlockRules(tenant: String, ruleName: String, ftTypes:[String], nftTypes:[String], listingTypes:[String], status:String)
	pub event TenantAllowRules(tenant: String, ruleName: String, ftTypes:[String], nftTypes:[String], listingTypes:[String], status:String)
	pub event FindCutRules(tenant: String, ruleName: String, cut:UFix64, ftTypes:[String], nftTypes:[String], listingTypes:[String], status:String)

	//Residual Royalty
	pub var residualAddress : Address

	// Tenant information
	pub let TenantClientPublicPath: PublicPath
	pub let TenantClientStoragePath: StoragePath

	access(contract) let tenantPathPrefix :String

	access(contract) let tenantNameAddress : {String:Address}
	access(contract) let tenantAddressName : {Address:String}



	// ========================================
	pub fun getPublicPath(_ type: Type, name:String) : PublicPath {

		let pathPrefix=self.pathMap[type.identifier]!
		let path=pathPrefix.concat("_").concat(name)

		return PublicPath(identifier: path) ?? panic("Cannot find public path for type ".concat(type.identifier))
	}

	pub fun getStoragePath(_ type: Type, name:String) : StoragePath {

		let pathPrefix=self.pathMap[type.identifier]!
		let path=pathPrefix.concat("_").concat(name)

		return StoragePath(identifier: path) ?? panic("Cannot find public path for type ".concat(type.identifier))
	}
	pub fun getFindTenantAddress() : Address {
		return FindMarket.account.address
	}

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

	pub fun getSaleItemCollectionCapabilities(tenantRef: &FindMarket.Tenant{FindMarket.TenantPublic}, address: Address) : [Capability<&{FindMarket.SaleItemCollectionPublic}>] {
		var caps : [Capability<&{FindMarket.SaleItemCollectionPublic}>] = []
		for type in self.getSaleItemCollectionTypes() {
			if type != nil {
				let cap = getAccount(address).getCapability<&{FindMarket.SaleItemCollectionPublic}>(tenantRef.getPublicPath(type))
				if cap.check() {
					caps.append(cap)
				}
			}
		}
		return caps
	}

	pub fun getSaleItemCollectionCapability(tenantRef: &FindMarket.Tenant{FindMarket.TenantPublic}, marketOption: String, address: Address) : Capability<&{FindMarket.SaleItemCollectionPublic}> {
		for type in self.getSaleItemCollectionTypes() {
			if self.getMarketOptionFromType(type) == marketOption{
				let cap = getAccount(address).getCapability<&{FindMarket.SaleItemCollectionPublic}>(tenantRef.getPublicPath(type))
				return cap
			}
		}
		panic("Cannot find market option : ".concat(marketOption))
	}



	/* Get Sale Reports and Sale Item */
	pub fun assertOperationValid(tenant: Address, address: Address, marketOption: String, id:UInt64) : &{SaleItem} {

		let tenantRef=self.getTenant(tenant)
		let collectionCap = self.getSaleItemCollectionCapability(tenantRef: tenantRef, marketOption: marketOption, address: address)
		let optRef = collectionCap.borrow() 
		if optRef == nil {
			panic("Account not properly set up, cannot borrow sale item collection")
		}
		let ref=optRef!
		let item=ref.borrowSaleItem(id)
		if !item.checkPointer() {
			panic("this is a ghost listing")
		} 

		return item
	}

	/* Get Sale Reports and Sale Item */
	pub fun getSaleInformation(tenant: Address, address: Address, marketOption: String, id:UInt64, getNFTInfo: Bool) : FindMarket.SaleItemInformation? {

		let tenantRef=self.getTenant(tenant)
		let info = self.checkSaleInformation(tenantRef: tenantRef, marketOption:marketOption, address: address, itemId: id, getGhost: false, getNFTInfo: getNFTInfo)
		if info.items.length > 0 {
			return info.items[0]
		}
		return nil
	}

	pub fun getSaleItemReport(tenant:Address, address: Address, getNFTInfo: Bool) : {String : FindMarket.SaleItemCollectionReport} {
		let tenantRef = self.getTenant(tenant)
		var report : {String : FindMarket.SaleItemCollectionReport} = {}
		for type in self.getSaleItemCollectionTypes() {
			let marketOption = self.getMarketOptionFromType(type)
			let returnedReport = self.checkSaleInformation(tenantRef: tenantRef, marketOption:marketOption, address: address, itemId: nil, getGhost: true, getNFTInfo: getNFTInfo)
			if returnedReport.items.length > 0 || returnedReport.ghosts.length > 0 {
				report[marketOption] = returnedReport
			}
		}
		return report
	}

	pub fun getSaleItems(tenant:Address, address: Address, id: UInt64, getNFTInfo: Bool) : {String : FindMarket.SaleItemCollectionReport} {
		let tenantRef = self.getTenant(tenant)
		var report : {String : FindMarket.SaleItemCollectionReport} = {}
		for type in self.getSaleItemCollectionTypes() {
			let marketOption = self.getMarketOptionFromType(type)
			let returnedReport = self.checkSaleInformation(tenantRef: tenantRef, marketOption:marketOption, address: address, itemId: id, getGhost: true, getNFTInfo: getNFTInfo)
			if returnedReport.items.length > 0 || returnedReport.ghosts.length > 0 {
				report[marketOption] = returnedReport
			}
		}
		return report
	}

	pub fun getNFTListing(tenant:Address, address: Address, id: UInt64, getNFTInfo: Bool) : {String : FindMarket.SaleItemInformation} {
		let tenantRef = self.getTenant(tenant)
		var report : {String : FindMarket.SaleItemInformation} = {}
		for type in self.getSaleItemCollectionTypes() {
			let marketOption = self.getMarketOptionFromType(type)
			let returnedReport = self.checkSaleInformation(tenantRef: tenantRef, marketOption:marketOption, address: address, itemId: id, getGhost: true, getNFTInfo: getNFTInfo)
			if returnedReport.items.length > 0 || returnedReport.ghosts.length > 0 {
				report[marketOption] = returnedReport.items[0]
			}
		}
		return report
	}

	access(contract) fun checkSaleInformation(tenantRef: &FindMarket.Tenant{FindMarket.TenantPublic}, marketOption: String, address: Address, itemId: UInt64?, getGhost: Bool, getNFTInfo: Bool) : FindMarket.SaleItemCollectionReport {
		let ghost: [FindMarket.GhostListing] =[]
		let info: [FindMarket.SaleItemInformation] =[]
		let collectionCap = self.getSaleItemCollectionCapability(tenantRef: tenantRef, marketOption: marketOption, address: address)
		let optRef = collectionCap.borrow() 
		if optRef == nil {
			return FindMarket.SaleItemCollectionReport(items: info, ghosts: ghost)
		}
		let ref=optRef!

		var listID : [UInt64]= []
		if let id = itemId{
			if !ref.containsId(id) {
				return FindMarket.SaleItemCollectionReport(items: info, ghosts: ghost)
			}
			listID=[id]
		} else {
			listID = ref.getIds()
		}

		let listingType = ref.getListingType()

		for id in listID {
			//if this id is not present in this Market option then we just skip it
			let item=ref.borrowSaleItem(id)
			if !item.checkPointer() {
				if getGhost {
					ghost.append(FindMarket.GhostListing(listingType: listingType, id:id))
				}
				continue
			} 
			let stopped=tenantRef.allowedAction(listingType: listingType, nftType: item.getItemType(), ftType: item.getFtType(), action: FindMarket.MarketAction(listing:false, "delist item for sale"), seller: address, buyer: nil)
			var status="active"

			if !stopped.allowed && stopped.message == "Seller banned by Tenant" {
				status="banned"
				info.append(FindMarket.SaleItemInformation(item, status, false))
				continue
			}

			if !stopped.allowed {
				status="stopped"
				info.append(FindMarket.SaleItemInformation(item, status, false))
				continue
			}

			let deprecated=tenantRef.allowedAction(listingType: listingType, nftType: item.getItemType(), ftType: item.getFtType(), action: FindMarket.MarketAction(listing:true, "delist item for sale"), seller: address, buyer: nil)

			if !deprecated.allowed {
				status="deprecated"
				info.append(FindMarket.SaleItemInformation(item, status, getNFTInfo))
				continue
			}

			if let validTime = item.getValidUntil() {
				if validTime <= Clock.time() {
					status="ended"
				}
			}
			info.append(FindMarket.SaleItemInformation(item, status, getNFTInfo))
		}

		return FindMarket.SaleItemCollectionReport(items: info, ghosts: ghost)
	}

	/* Get Bid Collections */
	pub fun getMarketBidTypes() : [Type] {
		return self.marketBidTypes
	}

	pub fun getMarketBidCollectionTypes() : [Type] {
		return self.marketBidCollectionTypes
	}

	pub fun getMarketBidCollectionCapabilities(tenantRef: &FindMarket.Tenant{FindMarket.TenantPublic}, address: Address) : [Capability<&{FindMarket.MarketBidCollectionPublic}>] {
		var caps : [Capability<&{FindMarket.MarketBidCollectionPublic}>] = []
		for type in self.getMarketBidCollectionTypes() {
			let cap = getAccount(address).getCapability<&{FindMarket.MarketBidCollectionPublic}>(tenantRef.getPublicPath(type))
			if cap.check() {
				caps.append(cap)
			}
		}
		return caps
	}

	pub fun getMarketBidCollectionCapability(tenantRef: &FindMarket.Tenant{FindMarket.TenantPublic}, marketOption: String, address: Address) : Capability<&{FindMarket.MarketBidCollectionPublic}> {
		for type in self.getMarketBidCollectionTypes() {
			if self.getMarketOptionFromType(type) == marketOption{
				let cap = getAccount(address).getCapability<&{FindMarket.MarketBidCollectionPublic}>(tenantRef.getPublicPath(type))
				return cap
			}
		}
		panic("Cannot find market option : ".concat(marketOption))
	}

	pub fun getBid(tenant: Address, address: Address, marketOption: String, id:UInt64, getNFTInfo: Bool) : FindMarket.BidInfo? {
		let tenantRef=self.getTenant(tenant)
		let bidInfo = self.checkBidInformation(tenantRef: tenantRef, marketOption: marketOption, address: address, itemId: id, getGhost: false, getNFTInfo: getNFTInfo)
		if bidInfo.items.length > 0 {
			return bidInfo.items[0]
		}
		return nil
	}

	pub fun getBidsReport(tenant:Address, address: Address, getNFTInfo: Bool) : {String : FindMarket.BidItemCollectionReport} {
		let tenantRef = self.getTenant(tenant)
		var report : {String : FindMarket.BidItemCollectionReport} = {}
		for type in self.getMarketBidCollectionTypes() {
			let marketOption = self.getMarketOptionFromType(type)
			let returnedReport = self.checkBidInformation(tenantRef: tenantRef, marketOption: marketOption, address: address, itemId: nil, getGhost: true, getNFTInfo: getNFTInfo)
			if returnedReport.items.length > 0 || returnedReport.ghosts.length > 0 {
				report[marketOption] = returnedReport
			}
		}
		return report
	}

	access(contract) fun checkBidInformation(tenantRef: &FindMarket.Tenant{FindMarket.TenantPublic}, marketOption: String, address: Address, itemId: UInt64?, getGhost:Bool, getNFTInfo: Bool) : FindMarket.BidItemCollectionReport {
		let ghost: [FindMarket.GhostListing] =[]
		let info: [FindMarket.BidInfo] =[]
		let collectionCap = self.getMarketBidCollectionCapability(tenantRef: tenantRef, marketOption: marketOption, address: address)

		let optRef = collectionCap.borrow()
		if optRef==nil {
			return FindMarket.BidItemCollectionReport(items: info, ghosts: ghost)
		}

		let ref=optRef!

		let listingType = ref.getBidType()
		var listID : [UInt64]= []
		if let id = itemId{
			if !ref.containsId(id) {
				return FindMarket.BidItemCollectionReport(items: info, ghosts: ghost)
			}
			listID=[id]
		} else {
			listID = ref.getIds()
		}

		for id in listID {

			let bid=ref.borrowBidItem(id)
			let item=self.getSaleInformation(tenant: tenantRef.owner!.address, address: bid.getSellerAddress(), marketOption: marketOption, id: id, getNFTInfo: getNFTInfo)
			if item == nil {
				if getGhost {
					ghost.append(FindMarket.GhostListing(listingType: listingType, id:id))
				}
				continue
			} 
			let bidInfo = FindMarket.BidInfo(id: id, bidTypeIdentifier: listingType.identifier,  bidAmount: bid.getBalance(), timestamp: Clock.time(), item:item!)
			info.append(bidInfo)

		}
		return FindMarket.BidItemCollectionReport(items: info, ghosts: ghost)
	}

	pub fun assertBidOperationValid(tenant: Address, address: Address, marketOption: String, id:UInt64) : &{SaleItem} {

		let tenantRef=self.getTenant(tenant)
		let collectionCap = self.getMarketBidCollectionCapability(tenantRef: tenantRef, marketOption: marketOption, address: address)
		let optRef = collectionCap.borrow() 
		if optRef == nil {
			panic("Account not properly set up, cannot borrow bid item collection. Account address : ".concat(collectionCap.address.toString()))
		}
		let ref=optRef!
		let bidItem=ref.borrowBidItem(id)

		let saleItemCollectionCap = self.getSaleItemCollectionCapability(tenantRef: tenantRef, marketOption: marketOption, address: bidItem.getSellerAddress())
		let saleRef = saleItemCollectionCap.borrow() 
		if saleRef == nil {
			panic("Seller account is not properly set up, cannot borrow sale item collection. Seller address : ".concat(saleItemCollectionCap.address.toString()))
		}
		let sale=saleRef!
		let item=sale.borrowSaleItem(id)
		if !item.checkPointer() {
			panic("this is a ghost listing")
		} 

		return item
	}

	/* Helper Function */
	pub fun getMarketOptionFromType(_ type:Type) : String {
		return self.listingName[type.identifier]!
	}

	pub fun typeToListingName(_ type: Type) : String {
		let identifier = type.identifier
		var dots = 0
		var start = 0 
		var end = 0 
		var counter = 0 
		while counter < identifier.length {
			if identifier[counter] == "." {
				dots = dots + 1
			}
			if start == 0 && dots == 2 {
				start = counter
			}
			if end == 0 && dots == 3 {
				end = counter
			}
			counter = counter + 1
		}
		return identifier.slice(from: start + 1, upTo: end)
	}

	/* Admin Function */
	access(account) fun addSaleItemType(_ type: Type) {
		self.saleItemTypes.append(type)
		self.pathMap[type.identifier]= self.typeToPathIdentifier(type)
		self.listingName[type.identifier] =self.typeToListingName(type)
	}

	access(account) fun addMarketBidType(_ type: Type) {
		self.marketBidTypes.append(type)
		self.pathMap[type.identifier]= self.typeToPathIdentifier(type)
		self.listingName[type.identifier] =self.typeToListingName(type)
	}

	access(account) fun addSaleItemCollectionType(_ type: Type) {
		self.saleItemCollectionTypes.append(type)
		self.pathMap[type.identifier]= self.typeToPathIdentifier(type)
		self.listingName[type.identifier] =self.typeToListingName(type)
	}

	access(account) fun addMarketBidCollectionType(_ type: Type) {
		self.marketBidCollectionTypes.append(type)
		self.pathMap[type.identifier]= self.typeToPathIdentifier(type)
		self.listingName[type.identifier] =self.typeToListingName(type)
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

	pub fun typeToPathIdentifier(_ type:Type) : String {
		let identifier=type.identifier

		var i=0
		var newIdentifier=""
		while i < identifier.length {

			let item= identifier.slice(from: i, upTo: i+1) 
			if item=="." {
				newIdentifier=newIdentifier.concat("_")
			} else {
				newIdentifier=newIdentifier.concat(item)
			}
			i=i+1
		}
		return newIdentifier
	}
	// ========================================

	/// A struct to return what action an NFT can execute 
	pub struct AllowedListing {
		pub let listingType: Type 
		pub let ftTypes: [Type]
		pub let status: String 

		init(listingType: Type, ftTypes: [Type], status: String) {
			self.listingType=listingType
			self.ftTypes=ftTypes 
			self.status=status 
		} 
	}

	/// If this is a listing action it will not be allowed if deprecated
	pub struct MarketAction{
		pub let listing:Bool
		pub let name:String

		init(listing:Bool, name:String){
			self.listing=listing
			self.name=name
		}
	}

	pub struct ActionResult {
		pub let allowed:Bool
		pub let message:String
		pub let name:String

		init(allowed:Bool, message:String, name:String) {
			self.allowed=allowed
			self.message=message
			self.name =name
		}
	}

	pub struct TenantRule{
		pub let name:String
		pub let types:[Type]
		pub let ruleType:String
		pub let allow:Bool

		init(name:String, types:[Type], ruleType:String, allow:Bool){

			pre {
				ruleType == "nft" || ruleType == "ft" || ruleType == "listing" : "Must be nft/ft/listing"
			}
			self.name=name
			self.types=types
			self.ruleType=ruleType
			self.allow=allow
		}


		pub fun accept(_ relevantType: Type): Bool {
			let contains=self.types.contains(relevantType)

			if self.allow && contains{
				return true
			}

			if !self.allow && !contains {
				return true
			}
			return false
		}
	}

	pub struct TenantSaleItem {
		pub let name:String
		pub let cut:MetadataViews.Royalty?
		pub let rules:[TenantRule]
		pub var status:String

		init(name:String, cut:MetadataViews.Royalty?, rules:[TenantRule], status:String){
			self.name=name
			self.cut=cut
			self.rules=rules
			self.status=status
		}

		access(contract) fun removeRules(_ index: Int) : TenantRule {
			return self.rules.remove(at: index)
		}

		access(contract) fun addRules(_ rule: TenantRule) {
			self.rules.append(rule)
		}

		access(contract) fun alterStatus(_ status : String) {
			self.status = status
		}

		access(contract) fun isValid(nftType: Type, ftType: Type, listingType: Type) : Bool {
			for rule in self.rules {

				var relevantType=nftType
				if rule.ruleType == "listing" {
					relevantType=listingType
				} else if rule.ruleType=="ft" {
					relevantType=ftType 
				} 

				if !rule.accept(relevantType) {
					return false
				}
			}		
			return true	
		}
	}

	pub struct TenantCuts {
		pub let findCut:MetadataViews.Royalty?
		pub let tenantCut:MetadataViews.Royalty?

		init(findCut:MetadataViews.Royalty?, tenantCut:MetadataViews.Royalty?) {
			self.findCut=findCut
			self.tenantCut=tenantCut
		}
	}

	pub resource interface TenantPublic {
		pub fun getStoragePath(_ type: Type) : StoragePath 
		pub fun getPublicPath(_ type: Type) : PublicPath
		pub fun allowedAction(listingType: Type, nftType:Type, ftType:Type, action: MarketAction, seller: Address? , buyer: Address?) : ActionResult
		pub fun getTeantCut(name:String, listingType: Type, nftType:Type, ftType:Type) : TenantCuts 
		pub fun getAllowedListings(nftType: Type, marketType: Type) : AllowedListing? 
		pub fun getBlockedNFT(marketType: Type) : [Type] 
		pub let name:String
	}

	//this needs to be a resource so that nobody else can make it.
	pub resource Tenant : TenantPublic{

		access(self) let findSaleItems : {String : TenantSaleItem}
		access(self) let tenantSaleItems : {String : TenantSaleItem}
		access(self) let findCuts : {String : TenantSaleItem}

		pub let name: String

		init(_ name:String) {
			self.name=name
			self.tenantSaleItems={}
			self.findSaleItems={}
			self.findCuts= {}
		}

		access(account) fun alterMarketOption(name: String, status: String) {
			pre{
				self.tenantSaleItems[name] != nil : "This saleItem does not exist. Item : ".concat(name)
			}
			self.tenantSaleItems[name]!.alterStatus(status)
			self.emitRulesEvent(item: self.tenantSaleItems[name]!, type: "tenant", status: status)
		}

		access(account) fun setTenantRule(optionName: String, tenantRule: TenantRule) {
			pre{
				self.tenantSaleItems[optionName] != nil : "This tenant does not exist. Tenant ".concat(optionName)
			}
			/* 
			let rules = self.tenantSaleItems[optionName]!.rules
			for rule in rules {
				assert(rule.name == tenantRule.name, message: "Rule with same name already exist. Name: ".concat(rule.name))
			}
			*/
			self.tenantSaleItems[optionName]!.addRules(tenantRule)
			self.emitRulesEvent(item: self.tenantSaleItems[optionName]!, type: "tenant", status: nil)
		}

		access(account) fun removeTenantRule(optionName: String, tenantRuleName: String) {
			pre{
				self.tenantSaleItems[optionName] != nil : "This Market Option does not exist. Option :".concat(optionName)
			}
			let rules : [TenantRule] = self.tenantSaleItems[optionName]!.rules
			var counter = 0
			while counter < rules.length {
				if rules[counter]!.name == tenantRuleName {
					break
				}
				counter = counter + 1
				assert(counter < rules.length, message: "This tenant rule does not exist. Rule :".concat(optionName))
			}
			self.tenantSaleItems[optionName]!.removeRules(counter)
			self.emitRulesEvent(item: self.tenantSaleItems[optionName]!, type: "tenant", status: nil)
		}

		pub fun getTeantCut(name:String, listingType: Type, nftType:Type, ftType:Type) : TenantCuts {

			let item = self.tenantSaleItems[name]!

			for findCut in self.findCuts.values {
				let valid = findCut.isValid(nftType: nftType, ftType: ftType, listingType: listingType)
				if valid{
					return TenantCuts(findCut:findCut.cut, tenantCut: item.cut)
				}
			}
			return TenantCuts(findCut:nil, tenantCut: item.cut)
		}

		access(account) fun addSaleItem(_ item: TenantSaleItem, type:String) {
			if type=="find" {
				self.findSaleItems[item.name]=item
				self.emitRulesEvent(item: item, type: "find", status: nil)
			} else if type=="tenant" {
				self.tenantSaleItems[item.name]=item
				self.emitRulesEvent(item: item, type: "tenant", status: nil)
			} else if type=="cut" {
				self.findCuts[item.name]=item
				self.emitRulesEvent(item: item, type: "cut", status: nil)
			} else{
				panic("Not valid type to add sale item for")
			}
		}

		access(account) fun removeSaleItem(_ name:String, type:String) : TenantSaleItem {
			if type=="find" {
				let item = self.findSaleItems.remove(key: name) ?? panic("This Find Sale Item does not exist. SaleItem : ".concat(name))
				self.emitRulesEvent(item: item, type: "find", status: "remove")
				return item
			} else if type=="tenant" {
				let item = self.tenantSaleItems.remove(key: name)?? panic("This Tenant Sale Item does not exist. SaleItem : ".concat(name))
				self.emitRulesEvent(item: item, type: "tenant", status: "remove")
				return item
			} else if type=="cut" {
				let item = self.findCuts.remove(key: name)?? panic("This Find Cut does not exist. Cut : ".concat(name))
				self.emitRulesEvent(item: item, type: "cut", status: "remove")
				return item
			}
			panic("Not valid type to add sale item for")

		}

		// if status is nil, will fetch the original rule status (use for removal of rules)
		access(contract) fun emitRulesEvent(item: TenantSaleItem, type: String, status: String?) {
			let tenant = self.name 
			let ruleName = item.name 
			var ftTypes : [String] = [] 
			var nftTypes : [String] = [] 
			var listingTypes : [String] = [] 
			var ruleStatus = status
			for rule in item.rules {
				var array : [String] = [] 
				for t in rule.types {
					array.append(t.identifier)
				}
				if rule.ruleType == "ft" {
					ftTypes = array
				} else if rule.ruleType == "nft" {
					nftTypes = array
				} else if rule.ruleType == "listing" {
					listingTypes = array 
				}
			}
			if ruleStatus == nil {
				ruleStatus = item.status
			}

			if type == "find" {
				emit FindBlockRules(tenant: tenant, ruleName: ruleName, ftTypes:ftTypes, nftTypes:nftTypes, listingTypes:listingTypes, status:ruleStatus!)
				return
			} else if type == "tenant" {
				emit TenantAllowRules(tenant: tenant, ruleName: ruleName, ftTypes:ftTypes, nftTypes:nftTypes, listingTypes:listingTypes, status:ruleStatus!)
				return
			} else if type == "cut" {
				emit FindCutRules(tenant: tenant, ruleName: ruleName, cut:item.cut!.cut, ftTypes:ftTypes, nftTypes:nftTypes, listingTypes:listingTypes, status:ruleStatus!)
				return
			}
			panic("Panic executing emitRulesEvent, Must be nft/ft/listing")
		}

		pub fun allowedAction(listingType: Type, nftType:Type, ftType:Type, action: MarketAction, seller: Address?, buyer: Address?) : ActionResult{
			/* Check for Honour Banning */
			let profile = getAccount(FindMarket.tenantNameAddress[self.name]!).getCapability<&Profile.User{Profile.Public}>(Profile.publicPath).borrow() ?? panic("Cannot get reference to Profile to check honour banning. Tenant Name : ".concat(self.name))
			if seller != nil && profile.isBanned(seller!) {
				return ActionResult(allowed:false, message: "Seller banned by Tenant", name: "Profile Ban")
			}
			if buyer != nil && profile.isBanned(buyer!) {
				return ActionResult(allowed:false, message: "Buyer banned by Tenant", name: "Profile Ban")
			}


			/* Check for Find Deny Rules */
			for item in self.findSaleItems.values {
				for rule in item.rules {
					var relevantType=nftType
					if rule.ruleType == "listing" {
						relevantType=listingType
					} else if rule.ruleType=="ft" {
						relevantType=ftType 
					} 

					if rule.accept(relevantType) {
						continue
					}
					return ActionResult(allowed:false, message: rule.name, name: item.name)
				}
				if item.status=="stopped" {
					return ActionResult(allowed:false, message: "Find has stopped this item", name:item.name)
				}

				if item.status=="deprecated" && action.listing{
					return ActionResult(allowed:false, message: "Find has deprected mutation options on this item", name:item.name)
				}
			}

			/* Check for Tenant Allow Rules */
			for item in self.tenantSaleItems.values {
				let valid = item.isValid(nftType: nftType, ftType: ftType, listingType: listingType)

				if !valid {
					continue
				}

				if item.status=="stopped" {
					return ActionResult(allowed:false, message: "Tenant has stopped this item", name:item.name)
				}

				if item.status=="deprecated" && action.listing{
					return ActionResult(allowed:false, message: "Tenant has deprected mutation options on this item", name:item.name)
				}
				return ActionResult(allowed:true, message:"OK!", name:item.name)
			}

			return ActionResult(allowed:false, message:"Nothing matches", name:"")
		}

		pub fun getPublicPath(_ type: Type) : PublicPath {
			return FindMarket.getPublicPath(type, name: self.name)
		}

		pub fun getStoragePath(_ type: Type) : StoragePath {
			return FindMarket.getStoragePath(type, name: self.name)
		}

		pub fun getAllowedListings(nftType: Type, marketType: Type) : AllowedListing? {

			// Find Rules have to be deny rules
			var containsNFTType = false
			var containsListingType = true
			for item in self.findSaleItems.values {
				for rule in item.rules {
					if rule.types.contains(nftType){
						containsNFTType = true
					} 
					if rule.ruleType == "listing" && !rule.types.contains(marketType) {
						containsListingType = false
					}
				}
				if containsListingType && containsNFTType {
						return nil
				}
				containsNFTType = false 
				containsListingType = true
			}

			// Tenant Rules have to be allow rules
			for item in self.tenantSaleItems.values {
				var allowedFTTypes : [Type] = []
				for rule in item.rules {
					if rule.ruleType == "ft"{
						allowedFTTypes = rule.types
					}
					if rule.types.contains(nftType) && rule.allow {
						containsNFTType = true
					} 
					if rule.ruleType == "listing" && !rule.types.contains(marketType) && rule.allow {
						containsListingType = false
					} 
				}				
				if containsListingType && containsNFTType {
					return AllowedListing(listingType: marketType, ftTypes: allowedFTTypes, status: item.status)
				}
				
				containsNFTType = false 
				containsListingType = true
			}
			return nil
		}

		pub fun getBlockedNFT(marketType: Type) : [Type] {
			// Find Rules have to be deny rules
			let list : [Type] = []
			var containsListingType = true
			var l : [Type] = []
			for item in self.findSaleItems.values {
				for rule in item.rules {
					if rule.ruleType == "listing" && !rule.types.contains(marketType){
						containsListingType = false
					}
					if rule.ruleType == "nft" {
						l.appendAll(rule.types)
					}
				}
				if containsListingType { 
					for type in l {
						if list.contains(type) {
							continue
						}
						list.append(type)
					}
				}
				l = []
				containsListingType = true
			}

			containsListingType = false
			// Tenant Rules have to be allow rules
			for item in self.tenantSaleItems.values {
				for rule in item.rules {
					if item.status != "stopped" {
						continue
					}
					if rule.ruleType == "nft"{
						l.appendAll(rule.types)
					}
					if rule.types.contains(marketType) && rule.allow {
						containsListingType = true
					} 				

				}
				if containsListingType { 
					for type in l {
						if list.contains(type) {
							continue
						}
						list.append(type)
					}
				}
				l = []
				containsListingType = false
			}
			return list
		}
	}

	// Tenant admin stuff
	//Admin client to use for capability receiver pattern
	pub fun createTenantClient() : @TenantClient {
		return <- create TenantClient()
	}


	//interface to use for capability receiver pattern
	pub resource interface TenantClientPublic  {
		pub fun addCapability(_ cap: Capability<&Tenant>)
	}

	/*

	A tenantClient should be able to:
	- deprecte a certain market type: No new listings can be made

	*/
	//admin proxy with capability receiver 
	pub resource TenantClient: TenantClientPublic {

		access(self) var capability: Capability<&Tenant>?

		pub fun addCapability(_ cap: Capability<&Tenant>) {
			pre {
				cap.check() : "Invalid tenant"
				self.capability == nil : "Server already set"
			}
			self.capability = cap
		}

		init() {
			self.capability = nil
		}

		pub fun setMarketOption(name: String, cut: MetadataViews.Royalty?, rules: [TenantRule]) {
			let tenant = self.getTenantRef() 
			tenant.addSaleItem(TenantSaleItem(
				name: name, 
				cut: cut, 
				rules: rules, 
				status:"active"
			), type: "tenant")
		}

		pub fun removeMarketOption(name: String) {
			let tenant = self.getTenantRef() 
			tenant.removeSaleItem(name, type: "tenant")
		}

		pub fun enableMarketOption(_ name: String) {
			let tenant = self.getTenantRef() 
			tenant.alterMarketOption(name: name, status: "active")
		}

		pub fun deprecateMarketOption(_ name: String) {
			let tenant = self.getTenantRef() 
			tenant.alterMarketOption(name: name, status: "deprecated")
		}

		pub fun stopMarketOption(_ name: String) {
			let tenant = self.getTenantRef() 
			tenant.alterMarketOption(name: name, status: "stopped")
		}

		pub fun setTenantRule(optionName: String, tenantRule: TenantRule) {
			let tenantRef = self.getTenantRef()
			tenantRef.setTenantRule(optionName: optionName, tenantRule: tenantRule)
		}

		pub fun removeTenantRule(optionName: String, tenantRuleName: String) {
			let tenantRef = self.getTenantRef()
			tenantRef.removeTenantRule(optionName: optionName, tenantRuleName: tenantRuleName)
		}

		pub fun getTenantRef() : &Tenant {
			pre {
				self.capability != nil: "TenantClient is not present"
				self.capability!.check()  : "Tenant client is not linked anymore"
			}

			return self.capability!.borrow()!
		}

	}

	access(account) fun createFindMarket(name: String, address:Address, defaultCutRules: [TenantRule]) : Capability<&Tenant> {
		let account=FindMarket.account

		let receiver=FindMarket.account.getCapability<&{FungibleToken.Receiver}>(Profile.publicReceiverPath)
		let findRoyalty=MetadataViews.Royalty(receiver: receiver, cut: 0.025, description: "find")

		let tenant <- create Tenant(name)
		//fetch the TenentRegistry from our storage path and add the new tenant with the given name and address

		//add to registry
		self.tenantAddressName[address]=name
		self.tenantNameAddress[name]=address

		tenant.addSaleItem(TenantSaleItem(
			name:"findRoyalty", 
			cut:findRoyalty, 
			rules: defaultCutRules, 
			status:"active"
		), type: "cut")
		//end do on outside

		let tenantPath=self.getTenantPathForName(name)
		let sp=StoragePath(identifier: tenantPath)!
		let pp=PrivatePath(identifier: tenantPath)!
		let pubp=PublicPath(identifier:tenantPath)!

		account.save(<- tenant, to: sp)
		account.link<&Tenant>(pp, target:sp)
		account.link<&Tenant{TenantPublic}>(pubp, target:sp)
		return account.getCapability<&Tenant>(pp)
	}

	pub fun getTenantPathForName(_ name:String) : String {
		pre {
			self.tenantNameAddress.containsKey(name) : "tenant is not registered in registry"
		}

		return self.tenantPathPrefix.concat("_").concat(name)
	}

	pub fun getTenantPathForAddress(_ address:Address) : String {
		pre {
			self.tenantAddressName.containsKey(address) : "tenant is not registered in registry"
		}

		return self.getTenantPathForName(self.tenantAddressName[address]!)
	}

	pub fun getTenantCapability(_ marketplace:Address) : Capability<&Tenant{TenantPublic}>? {
		pre {
			self.tenantAddressName.containsKey(marketplace) : "tenant is not registered in registry"
		}

		return FindMarket.account.getCapability<&Tenant{TenantPublic}>(PublicPath(identifier:self.getTenantPathForAddress(marketplace))!)
	}


	access(account) fun pay(tenant: String, id: UInt64, saleItem: &{SaleItem}, vault: @FungibleToken.Vault, royalty: MetadataViews.Royalties, nftInfo:NFTInfo, cuts:FindMarket.TenantCuts, resolver: ((Address) : String?)) {
		let buyer=saleItem.getBuyer()
		let seller=saleItem.getSeller()
		let oldProfile= getAccount(seller).getCapability<&{Profile.Public}>(Profile.publicPath).borrow()!
		let soldFor=vault.balance
		let ftType=vault.getType()

		/* Residual Royalty */
		let ftInfo = FTRegistry.getFTInfoByTypeIdentifier(ftType.identifier)! // If this panic, there is sth wrong in FT set up
		let residualVault = getAccount(FindMarket.residualAddress).getCapability<&{FungibleToken.Receiver}>(ftInfo.receiverPath)

		/* Check the total royalty to prevent changing of royalties */
		let royalties = royalty.getRoyalties()
		if royalties.length != 0 {
			var totalRoyalties : UFix64 = 0.0
			for royaltyItem in royalties {
				totalRoyalties = totalRoyalties + royaltyItem.cut
			}
			assert(totalRoyalties == saleItem.getTotalRoyalties(), message: "The total Royalties to be paid is changed after listing.")

			for royaltyItem in royalties {
				let description=royaltyItem.description
				let cutAmount= soldFor * royaltyItem.cut
				let receiver = royaltyItem.receiver.address
				let name = resolver(royaltyItem.receiver.address)

				var walletCheck = true 
				if !royaltyItem.receiver.check() { 
					// if the capability is not valid, royalty cannot be paid
					walletCheck = false 
				} else if royaltyItem.receiver.borrow()!.isInstance(Type<@Profile.User>()){ 
					// if the capability is valid -> it is a User resource -> check if the wallet is set up.
					let ref = getAccount(receiver).getCapability<&{Profile.Public}>(Profile.publicPath).borrow()! // If this is nil, there shouldn't be a wallet receiver
					walletCheck = ref.checkWallet(ftType.identifier)
				} else if !royaltyItem.receiver.borrow()!.isInstance(ftType){ 
					// if the capability is valid -> it is a FT Vault, check if it matches the paying vault type.
					walletCheck = false 
				}

				/* If the royalty receiver check failed */
				if !walletCheck {
					emit RoyaltyCouldNotBePaid(tenant:tenant, id: id, saleID: saleItem.uuid, address:receiver, findName: name, royaltyName: description, amount: cutAmount,  vaultType: ftType.identifier, nft:nftInfo, residualAddress: FindMarket.residualAddress)
					residualVault.borrow()!.deposit(from: <- vault.withdraw(amount: cutAmount))
					continue
				}

				/* If the royalty receiver check succeed */
				emit RoyaltyPaid(tenant:tenant, id: id, saleID: saleItem.uuid, address:royaltyItem.receiver.address, findName: name, royaltyName: description, amount: cutAmount,  vaultType: ftType.identifier, nft:nftInfo)
				royaltyItem.receiver.borrow()!.deposit(from: <- vault.withdraw(amount: cutAmount))
			}
		}

		if let findCut =cuts.findCut {
			let cutAmount= soldFor * findCut.cut
			let name = resolver(findCut.receiver.address)
			emit RoyaltyPaid(tenant: tenant, id: id, saleID: saleItem.uuid, address:findCut.receiver.address, findName: name , royaltyName: "find", amount: cutAmount,  vaultType: ftType.identifier, nft:nftInfo)
			let vaultRef = findCut.receiver.borrow() ?? panic("Find Royalty receiving account is not set up properly. Find Royalty account address : ".concat(findCut.receiver.address.toString()))
			vaultRef.deposit(from: <- vault.withdraw(amount: cutAmount))
		}

		if let tenantCut =cuts.tenantCut {
			let cutAmount= soldFor * tenantCut.cut
			let name = resolver(tenantCut.receiver.address)
			emit RoyaltyPaid(tenant: tenant, id: id, saleID: saleItem.uuid, address:tenantCut.receiver.address, findName: name, royaltyName: "marketplace", amount: cutAmount,  vaultType: ftType.identifier, nft:nftInfo)
			let vaultRef = tenantCut.receiver.borrow() ?? panic("Tenant Royalty receiving account is not set up properly. Tenant Royalty account address : ".concat(tenantCut.receiver.address.toString()))
			vaultRef.deposit(from: <- vault.withdraw(amount: cutAmount))
		}

		oldProfile.deposit(from: <- vault)
	}

	pub struct NFTInfo {
		pub let id: UInt64 
		pub let name:String
		pub let thumbnail:String
		pub let type: String
		pub var rarity:String?
		pub var editionNumber: UInt64? 
		pub var totalInEdition: UInt64?
		pub var scalars : {String: UFix64}
		pub var tags : {String: String}
		pub var collectionName: String? 
		pub var collectionDescription: String? 

		init(_ item: &{MetadataViews.Resolver}, id: UInt64){

			self.scalars={}
			self.tags={}

			self.collectionName=nil
			self.collectionDescription=nil

			if let ncd = MetadataViews.getNFTCollectionDisplay(item) {
				self.collectionName=ncd.name
				self.collectionDescription=ncd.description
			}

			self.rarity=nil
			if let rarity = FindViews.getRarity(item) {
				self.rarity=rarity.rarityName
			}

			if let tags = FindViews.getTags(item) {
				self.tags=tags.getTag()
			}

			if let scalar = FindViews.getScalar(item) {
				self.scalars=scalar.getScalar()
			}

			let display = MetadataViews.getDisplay(item) ?? panic("cannot get MetadataViews.Display View")
			self.name=display.name
			self.thumbnail=display.thumbnail.uri()
			self.type=item.getType().identifier
			self.id=id

			self.editionNumber=nil
			self.totalInEdition=nil

			if let editions = MetadataViews.getEditions(item) {
				for edition in editions.infoList {
					if edition.name == nil {
						self.editionNumber=edition.number
						self.totalInEdition=edition.max
					} else {
						self.scalars["edition_".concat(edition.name!).concat("_number")] = UFix64(edition.number)
						if edition.max != nil {
							self.scalars["edition_".concat(edition.name!).concat("_max")] = UFix64(edition.max!)
						}
					}
				}
			}
		}
	}

	pub struct GhostListing{
//		pub let listingType: Type
		pub let listingTypeIdentifier: String
		pub let id: UInt64


		init(listingType:Type, id:UInt64) {
//			self.listingType=listingType
			self.listingTypeIdentifier=listingType.identifier
			self.id=id
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
		pub fun getIds(): [UInt64]
		pub fun containsId(_ id: UInt64): Bool
		access(account) fun borrowSaleItem(_ id: UInt64) : &{SaleItem}
		pub fun getListingType() : Type 
	}

	pub struct SaleItemCollectionReport {
		pub let items : [FindMarket.SaleItemInformation] 
		pub let ghosts: [FindMarket.GhostListing]

		init(items: [SaleItemInformation], ghosts: [GhostListing]) {
			self.items=items
			self.ghosts=ghosts
		}
	}

	pub resource interface MarketBidCollectionPublic {
		pub fun getIds() : [UInt64] 
		pub fun containsId(_ id: UInt64): Bool
		pub fun getBidType() : Type 
		access(account) fun borrowBidItem(_ id: UInt64) : &{Bid}
	}

	pub struct BidItemCollectionReport {
		pub let items : [FindMarket.BidInfo] 
		pub let ghosts: [FindMarket.GhostListing]

		init(items: [BidInfo], ghosts: [GhostListing]) {
			self.items=items
			self.ghosts=ghosts
		}
	}

	pub resource interface Bid {
		pub fun getBalance() : UFix64
		pub fun getSellerAddress() : Address 
		pub fun getBidExtraField() : {String : AnyStruct}
	}

	pub resource interface SaleItem {

		//this is the type of sale this is, auction, direct offer etc
		pub fun getSaleType(): String
		pub fun getListingTypeIdentifier(): String

		pub fun getSeller(): Address
		pub fun getBuyer(): Address?

		pub fun getSellerName() : String?
		pub fun getBuyerName() : String?

		pub fun toNFTInfo() : FindMarket.NFTInfo
		pub fun checkPointer() : Bool 
		pub fun getListingType() : Type 

		// pub fun getFtAlias(): String 
		//the Type of the item for sale
		pub fun getItemType(): Type
		//The id of the nft for sale
		pub fun getItemID() : UInt64
		//The id of this sale item, ie the UUID of the item listed for sale
		pub fun getId() : UInt64

		pub fun getBalance(): UFix64
		pub fun getAuction(): AuctionItem?
		pub fun getFtType() : Type //The type of FT used for this sale item
		pub fun getValidUntil() : UFix64? //A timestamp that says when this item is valid until

		pub fun getSaleItemExtraField() : {String : AnyStruct}

		pub fun getTotalRoyalties() : UFix64 
		pub fun getDisplay() : MetadataViews.Display 
		pub fun getNFTCollectionData() : MetadataViews.NFTCollectionData
	}

	pub struct SaleItemInformation {
		pub let nftIdentifier: String 
		pub let nftId: UInt64
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

		pub var nft: NFTInfo?
		pub let auction: AuctionItem?
		pub let listingStatus:String
		pub let saleItemExtraField: {String : AnyStruct}

		init(item: &{SaleItem}, status:String, nftInfo: Bool) {
			self.nftIdentifier= item.getItemType().identifier
			self.nftId=item.getItemID()
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
			self.nft=nil
			if nftInfo {
				if status != "stopped" {
					self.nft=item.toNFTInfo()
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
		pub let id: UInt64
		pub let bidAmount: UFix64
		pub let bidTypeIdentifier: String 
		pub let timestamp: UFix64
		pub let item: SaleItemInformation

		init(id: UInt64, bidTypeIdentifier: String, bidAmount: UFix64, timestamp: UFix64, item:SaleItemInformation) {
			self.id=id
			self.bidAmount=bidAmount
			self.bidTypeIdentifier=bidTypeIdentifier
			self.timestamp=timestamp
			self.item=item
		}
	}

	access(account) fun setResidualAddress(_ address: Address) {
		FindMarket.residualAddress = address
	}

	init() {
		self.tenantAddressName={}
		self.tenantNameAddress={}

		self.TenantClientPublicPath=/public/findMarketClient
		self.TenantClientStoragePath=/storage/findMarketClient

		self.tenantPathPrefix=  FindMarket.typeToPathIdentifier(Type<@Tenant>())

		self.saleItemTypes = []
		self.saleItemCollectionTypes = []
		self.pathMap = {}
		self.listingName={}
		self.marketBidTypes = []
		self.marketBidCollectionTypes = []

		self.residualAddress = self.account.address // This has to be changed

	}

}

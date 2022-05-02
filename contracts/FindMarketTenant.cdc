import NonFungibleToken from "./standard/NonFungibleToken.cdc"
import MetadataViews from "./standard/MetadataViews.cdc"
import Profile from "./Profile.cdc"
import FungibleToken from "./standard/FungibleToken.cdc"
import FUSD from "./standard/FUSD.cdc"
import FlowToken from "./standard/FlowToken.cdc"
import FindViews from "../contracts/FindViews.cdc"

pub contract FindMarketTenant {

	pub let TenantClientPublicPath: PublicPath
	pub let TenantClientStoragePath: StoragePath

	//TODO: remove a tenant
	access(contract) let tenantNameAddress : {String:Address}
	access(contract) let tenantAddressName : {Address:String}

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

		//TODO : pre all the names that are unique
		init(name:String, cut:MetadataViews.Royalty?, rules:[TenantRule], status:String){
			self.name=name
			self.cut=cut
			self.rules=rules
			self.status=status
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
		pub fun allowedAction(listingType: Type, nftType:Type, ftType:Type, action: MarketAction) : ActionResult
		pub fun getTeantCut(name:String, listingType: Type, nftType:Type, ftType:Type) : TenantCuts 
		pub fun getSaleItems() : {String: {String: TenantSaleItem}} 
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

		access(contract) fun alterMarketOption(name: String, status: String) {
			pre{
				self.tenantSaleItems[name] != nil : "This saleItem does not exist. Item : ".concat(name)
			}
			self.tenantSaleItems[name]!.alterStatus(status)
		}

		access(contract) fun setTenantRule(optionName: String, tenantRule: TenantRule) {
			pre{
				self.tenantSaleItems[optionName] != nil : "This tenant does not exist. Tenant ".concat(optionName)
			}
			/* 
			let rules = self.tenantSaleItems[optionName]!.rules
			for rule in rules {
				assert(rule.name == tenantRule.name, message: "Rule with same name already exist. Name: ".concat(rule.name))
			}
			*/
			self.tenantSaleItems[optionName]!.rules.append(tenantRule)
		}

		access(contract) fun removeTenantRule(optionName: String, tenantRuleName: String) {
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
			self.tenantSaleItems[optionName]!.rules.remove(at: counter)
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
			} else if type=="tenant" {
				self.tenantSaleItems[item.name]=item
			} else if type=="cut" {
				self.findCuts[item.name]=item
			} else{
				panic("Not valid type to add sale item for")
			}
		}

		access(account) fun removeSaleItem(_ name:String, type:String) {
			if type=="find" {
				self.findSaleItems.remove(key: name) ?? panic("This Find Sale Item does not exist. SaleItem : ".concat(name))
			} else if type=="tenant" {
				self.tenantSaleItems.remove(key: name)?? panic("This Tenant Sale Item does not exist. SaleItem : ".concat(name))
			} else if type=="cut" {
				self.findCuts.remove(key: name)?? panic("This Find Cut does not exist. Cut : ".concat(name))
			} else{
				panic("Not valid type to add sale item for")
			}
		}

		pub fun allowedAction(listingType: Type, nftType:Type, ftType:Type, action: MarketAction) : ActionResult{

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
			//TODO: pre that this is a market?

			let pathPrefix=FindViews.typeToPathIdentifier(type)
			let path=pathPrefix.concat("_").concat(self.name)

			return PublicPath(identifier: path) ?? panic("Cannot find public path for type ".concat(type.identifier))
		}

		pub fun getStoragePath(_ type: Type) : StoragePath {

			let pathPrefix=FindViews.typeToPathIdentifier(type)
			let path=pathPrefix.concat("_").concat(self.name)

			return StoragePath(identifier: path) ?? panic("Cannot find storage path for type ".concat(type.identifier))
		}

		pub fun getSaleItems() : {String: {String: TenantSaleItem}} {
			var saleItems : {String: {String: TenantSaleItem} } = {}
			saleItems["findSaleItems"] = self.findSaleItems
			saleItems["tenantSaleItems"] = self.tenantSaleItems
			saleItems["findCuts"] = self.findCuts

			return saleItems
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


		/*
		//Add that i can list Dandy for Flow
		//list it
		//deprecte it
		//list another

		Add a new tenant rule, remove it from the above market tenant
		test that a tenant can then turn deprecate  a rule
		//TODO: creat a method to add these
		//TODO: put this in another transaction
		tenant.addSaleItem(TenantSaleItem(
			name:"AnyNFTFlow", 
			cut:nil, 
			rules:[ TenantRule( name:"flow", types:[flowType, fusdType], ruleType:"ft", allow:true) ], 
			status:"active"
		), type: "tenant")
		*/

		pub fun setMarketOption(name: String, cut: MetadataViews.Royalty?, rules: [TenantRule]) {
			let tenant = self.getTenantRef() 
			tenant.addSaleItem(TenantSaleItem(
				name: name, 
				cut: cut, 
				rules: rules, 
				status:"active"
				), type: "tenant")
			//Emit Event here
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

		//BAM: do admin operations on a tenant
		/*
		- not allow a certain market type
		*/
		// This is a function only for private use. Not exposed through public interface
		pub fun getTenantRef() : &Tenant {
			pre {
				self.capability != nil: "TenantClient is not present"
				self.capability!.check()  : "Tenant client is not linked anymore"
			}

			return self.capability!.borrow()!
		}
		
	}

	access(account) fun createFindMarketTenant(name: String, address:Address) : Capability<&Tenant> {
		let account=FindMarketTenant.account

		let receiver=FindMarketTenant.account.getCapability<&{FungibleToken.Receiver}>(Profile.publicReceiverPath)
		let findRoyalty=MetadataViews.Royalty(receiver: receiver, cut: 0.025, description: "find")

		let tenant <- create Tenant(name)
		//fetch the TenentRegistry from our storage path and add the new tenant with the given name and address

		//add to registry
		self.tenantAddressName[address]=name
		self.tenantNameAddress[name]=address

		let flowType=Type<@FlowToken.Vault>()
		let fusdType=Type<@FUSD.Vault>()

		tenant.addSaleItem(TenantSaleItem(
			name:"FlowFusdCut", 
			cut:findRoyalty, 
			rules:[TenantRule( name:"standard ft", types:[flowType, fusdType], ruleType:"ft", allow:true)], 
			status:"active"
		), type: "cut")

		//TODO: put this in another transaction
		/* 
		tenant.addSaleItem(TenantSaleItem(
			name:"AnyNFTFlow", 
			cut:nil, 
			rules:[ TenantRule( name:"flow", types:[flowType, fusdType], ruleType:"ft", allow:true) ], 
			status:"active"
		), type: "tenant")
		*/
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

		let path= FindViews.typeToPathIdentifier(Type<@Tenant>())

		return path.concat("_").concat(name)
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

		return FindMarketTenant.account.getCapability<&Tenant{TenantPublic}>(
			PublicPath(identifier:self.getTenantPathForAddress(marketplace))!)
	}

	pub fun getFindTenantCapability() : Capability<&Tenant{TenantPublic}> {
		return FindMarketTenant.getTenantCapability(FindMarketTenant.account.address) ?? panic("Find market tenant not set up correctly")
	}

	init() {
		self.tenantAddressName={}
		self.tenantNameAddress={}

		self.TenantClientPublicPath=/public/findMarketClient
		self.TenantClientStoragePath=/storage/findMarketClient
	}
}

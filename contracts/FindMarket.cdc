import FungibleToken from "./standard/FungibleToken.cdc"
import FlowToken from "./standard/FlowToken.cdc"
import NonFungibleToken from "./standard/NonFungibleToken.cdc"
import MetadataViews from "./standard/MetadataViews.cdc"
import FindViews from "../contracts/FindViews.cdc"
import Profile from "./Profile.cdc"
import Clock from "./Clock.cdc"
import Debug from "./Debug.cdc"

pub contract FindMarket {

	pub let TenantClientPublicPath: PublicPath
	pub let TenantClientStoragePath: StoragePath

	pub let TenantPrivatePath: PrivatePath
	pub let TenantStoragePath: StoragePath


	pub event RoyaltyPaid(tenant:String, id: UInt64, address:Address, findName:String?, royaltyName:String, amount: UFix64, vaultType:String, nft:NFTInfo)

	access(account) fun pay(tenant: String, id: UInt64, saleItem: &{SaleItem}, vault: @FungibleToken.Vault, royalty: MetadataViews.Royalties?, nftInfo:NFTInfo, cuts:TenantCuts) {
		let buyer=saleItem.getBuyer()
		let seller=saleItem.getSeller()
		let oldProfile= getAccount(seller).getCapability<&{Profile.Public}>(Profile.publicPath).borrow()!
		let soldFor=vault.balance
		let ftType=vault.getType()

		if royalty != nil {
			for royaltyItem in royalty!.getRoyalties() {
				let description=royaltyItem.description
				let cutAmount= soldFor * royaltyItem.cut
				//let name=FIND.reverseLookup(royaltyItem.receiver.address)
				let name=""
				emit RoyaltyPaid(tenant:name, id: id, address:royaltyItem.receiver.address, findName: name, royaltyName: description, amount: cutAmount,  vaultType: ftType.identifier, nft:nftInfo)
				royaltyItem.receiver.borrow()!.deposit(from: <- vault.withdraw(amount: cutAmount))
			}
		}

		if let findCut =cuts.findCut {
			let cutAmount= soldFor * findCut.cut
			//let name =FIND.reverseLookup(findCut.receiver.address)
			let name=""
			emit RoyaltyPaid(tenant: name, id: id, address:findCut.receiver.address, findName: name , royaltyName: "find", amount: cutAmount,  vaultType: ftType.identifier, nft:nftInfo)
			findCut.receiver.borrow()!.deposit(from: <- vault.withdraw(amount: cutAmount))
		}

		if let tenantCut =cuts.tenantCut {
			let cutAmount= soldFor * tenantCut.cut
			//let name=FIND.reverseLookup(tenantCut.receiver.address)
			let name=""
			emit RoyaltyPaid(tenant: name, id: id, address:tenantCut.receiver.address, findName: name, royaltyName: "marketplace", amount: cutAmount,  vaultType: ftType.identifier, nft:nftInfo)
			tenantCut.receiver.borrow()!.deposit(from: <- vault.withdraw(amount: cutAmount))
		}
		oldProfile.deposit(from: <- vault)
	}

	pub struct NFTInfo{
		pub let name:String
		pub let description:String
		pub let thumbnail:String
		pub let type: String
		//TODO: add more views here, like rarity

		init(_ item: &{MetadataViews.Resolver}){
			let display = item.resolveView(Type<MetadataViews.Display>())! as! MetadataViews.Display
			self.name=display.name
			self.description=display.description
			self.thumbnail=display.thumbnail.uri()
			self.type=item.getType().identifier
		}
	}

	pub struct MarketAction{
		pub let mutating:Bool
		pub let name:String

		init(mutating:Bool, name:String){
			self.mutating=mutating
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
		pub let status:String

		init(name:String, cut:MetadataViews.Royalty?, rules:[TenantRule], status:String){
			self.name=name
			self.cut=cut
			self.rules=rules
			self.status=status
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
		pub let name:String
	}

	//this needs to be a resource so that nobody else can make it.
	pub resource Tenant : TenantPublic{

		access(self) let findSaleItems : {String : TenantSaleItem}
		access(self) let tenantSaleItems : {String : TenantSaleItem}
		access(self) let findCuts : {String : TenantSaleItem}

		pub let publicPaths: { String: PublicPath}
		pub let storagePaths : { String: StoragePath}

		pub let name: String

		init(_ name:String) {
			self.name=name
			self.tenantSaleItems={}
			self.findSaleItems={}
			self.findCuts= {}
			self.publicPaths={}
			self.storagePaths={}
		}

		pub fun addSaleType(type:Type, public: PublicPath, storage:StoragePath) {
			let identifier= type.identifier
			self.publicPaths[identifier] = public
			self.storagePaths[identifier]=storage
		}


		pub fun getTeantCut(name:String, listingType: Type, nftType:Type, ftType:Type) : TenantCuts {

			let item = self.tenantSaleItems[name]!

			for findCut in self.findCuts.values {
				var valid=true
				for rule in findCut.rules {
					var relevantType=nftType
					if rule.ruleType == "listing" {
						relevantType=listingType
					} else if rule.ruleType=="ft" {
						relevantType=ftType 
					} 

					if !rule.accept(relevantType) {
						valid=false
					}
				}
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
				self.findSaleItems.remove(key: name)
			} else if type=="tenant" {
				self.tenantSaleItems.remove(key: name)
			} else if type=="cut" {
				self.findCuts.remove(key: name)
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

				if item.status=="deprecated" && action.mutating{
					return ActionResult(allowed:false, message: "Find has deprected mutation options on this item", name:item.name)
				}
			}


			for item in self.tenantSaleItems.values {
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

					return ActionResult(allowed:false, message: rule.name, name:item.name)
				}

				if item.status=="stopped" {
					return ActionResult(allowed:false, message: "Tenant has stopped this item", name:item.name)
				}

				if item.status=="deprecated" && action.mutating{
					return ActionResult(allowed:false, message: "Tenant has deprected mutation options on this item", name:item.name)
				}
				return ActionResult(allowed:true, message:"OK!", name:item.name)
			}

			return ActionResult(allowed:false, message:"Nothing matches", name:"")
		}

		pub fun getPublicPath(_ type: Type) : PublicPath {
			return self.publicPaths[type.identifier] ?? panic("Cannot find public path for type ".concat(type.identifier))
		}

		pub fun getStoragePath(_ type: Type) : StoragePath {
			return self.storagePaths[type.identifier] ?? panic("Cannot find storage path for type ".concat(type.identifier))
		}
	}

	access(account) fun createTenant(_ name: String) : @Tenant {
		return <- create Tenant(name)
	}

	// Tenant admin stuff
	//Admin client to use for capability receiver pattern
	pub fun createTenantClient() : @TenantClient {
		return <- create TenantClient()
	}


	//interface to use for capability receiver pattern
	pub resource interface TenantClientPublic  {
		pub fun getTenantCapability() : Capability<&Tenant{TenantPublic}>
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

		//Needs to return a capablity
		pub fun getTenantCapability() : Capability<&Tenant{TenantPublic}> {
			pre {
				self.capability != nil: "TenantClient is not present"
				self.capability!.check()  : "Tenant client is not linked anymore"
			}

			return self.capability! as Capability<&Tenant{TenantPublic}>
		}
	}


	pub struct interface AuctionItem {
		pub fun getReservePrice(): UFix64
		pub fun getExtentionOnLateBid(): UFix64
	}

	pub resource interface SaleItem {

		//this is the type of sale this is, auction, direct offer etc
		pub fun getSaleType(): String

		pub fun getSeller(): Address
		pub fun getBuyer(): Address?

		//TODO: The Path to store it in?
		//the Type of the item for sale
		pub fun getItemType(): Type
		//The id of the item for sale
		pub fun getItemID() : UInt64

		//The id of this sale item
		pub fun getId() : UInt64

		pub fun getBalance(): UFix64

		pub fun getAuction(): AnyStruct{AuctionItem}?
		pub fun getFtType() : Type //The type of FT used for this sale item
		pub fun getValidUntil() : UFix64? //A timestamp that says when this item is valid until
	}

	pub struct SaleItemInformation {

		//TODO: should we add typeIdentifier here?
		//TODO: call this nftType?
		pub let type:Type
		pub let typeId: UInt64
		pub let id:UInt64
		pub let owner: Address
		pub let amount: UFix64?
		pub let bidder: Address?
		pub let saleType:String
		pub let ftType: Type
		pub let ftTypeIdentifier: String
		pub let auctionReservePrice: UFix64?
		pub let extensionOnLateBid: UFix64?
		pub let listingValidUntil: UFix64?


		init(_ item: &{SaleItem}) {
			self.type= item.getItemType()
			self.typeId=item.getItemID()
			self.saleType=item.getSaleType()
			self.id= item.getId()
			self.amount=item.getBalance()
			self.bidder=item.getBuyer()
			self.owner=item.getSeller()
			self.auctionReservePrice=item.getAuction()?.getReservePrice()
			self.extensionOnLateBid=item.getAuction()?.getExtentionOnLateBid()
			self.ftType=item.getFtType()
			self.ftTypeIdentifier=item.getFtType().identifier
			self.listingValidUntil=item.getValidUntil()
		}
	}

	pub struct BidInfo{
		pub let id: UInt64
		pub let timestamp: UFix64
		pub let item: SaleItemInformation

		init(id: UInt64, amount: UFix64, timestamp: UFix64, item:SaleItemInformation) {
			self.id=id
			self.timestamp=timestamp
			self.item=item
		}
	}

	pub fun getFindTenantCapability() : Capability<&Tenant{TenantPublic}> {
		return FindMarket.getTenantCapability(FindMarket.account.address) ?? panic("Find market tenant not set up correctly")
	}

	//return Capability<Tenant{TenantPublic}>
	pub fun getTenantCapability(_ marketplace:Address) : Capability<&Tenant{TenantPublic}>? {
		return getAccount(marketplace).getCapability<&{FindMarket.TenantClientPublic}>(FindMarket.TenantClientPublicPath).borrow()?.getTenantCapability()
	}

	init() {
		self.TenantClientPublicPath=/public/findMarketClient
		self.TenantClientStoragePath=/storage/findMarketClient

		self.TenantPrivatePath=/private/findMarketTenant
		self.TenantStoragePath=/storage/findMarketTenant

	}
}

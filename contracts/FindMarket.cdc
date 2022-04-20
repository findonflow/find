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

	access(account) fun pay(tenant: TenantInformation, id: UInt64, saleItem: &{SaleItem}, vault: @FungibleToken.Vault, royalty: FindViews.Royalties?, nftInfo:NFTInfo) {
		let buyer=saleItem.getBuyer()
		let seller=saleItem.getSeller()
		let oldProfile= getAccount(seller).getCapability<&{Profile.Public}>(Profile.publicPath).borrow()!
		let soldFor=vault.balance
		let ftType=vault.getType()

		if royalty != nil {
			for royaltyItem in royalty!.getRoyalties() {
				let description=royaltyItem.description
				let cutAmount= soldFor * royaltyItem.cut
//				let name=FIND.reverseLookup(royaltyItem.receiver.address)
				let name=""
				emit RoyaltyPaid(tenant:tenant.name, id: id, address:royaltyItem.receiver.address, findName: name, royaltyName: description, amount: cutAmount,  vaultType: ftType.identifier, nft:nftInfo)
				royaltyItem.receiver.borrow()!.deposit(from: <- vault.withdraw(amount: cutAmount))
			}
		}

		if let findCut =tenant.findCut {
			let cutAmount= soldFor * tenant.findCut!.cut
			//let name =FIND.reverseLookup(findCut.receiver.address)
			let name=""
			emit RoyaltyPaid(tenant: tenant.name, id: id, address:findCut.receiver.address, findName: name , royaltyName: "find", amount: cutAmount,  vaultType: ftType.identifier, nft:nftInfo)
			findCut.receiver.borrow()!.deposit(from: <- vault.withdraw(amount: cutAmount))
		}

		if let tenantCut =tenant.tenantCut {
			let cutAmount= soldFor * tenant.findCut!.cut
			//let name=FIND.reverseLookup(tenantCut.receiver.address)
			let name=""
			emit RoyaltyPaid(tenant: tenant.name, id: id, address:tenantCut.receiver.address, findName: name, royaltyName: "marketplace", amount: cutAmount,  vaultType: ftType.identifier, nft:nftInfo)
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

	pub struct TenantInformation {

		//This is the name of the tenant, it will be in all the events and 
		pub let name: String

		//consider making an array of listingRules
		//TODO; add getters 
		//if this is not empty, only NFTs of that type can be sold at this tenant
		access(self) let validNFTTypes: [Type]

		//if this is not empty, only FTs of this type can be registered for sale/bid with on this tenant. No matter what the NFT support
		access(self) let ftTypes: [Type]

		pub let publicPaths: { String: PublicPath}
		pub let storagePaths : { String: StoragePath}

		pub let findCut: FindViews.Royalty?
		pub let tenantCut: FindViews.Royalty?


		init(name:String, validNFTTypes: [Type], ftTypes:[Type], findCut: FindViews.Royalty?, tenantCut: FindViews.Royalty?) {
			self.name=name
			self.validNFTTypes=validNFTTypes
			self.ftTypes=ftTypes
			self.findCut=findCut
			self.tenantCut=tenantCut

			self.publicPaths = {}
			self.storagePaths = {}
		}

		pub fun addSaleType(type:Type, public: PublicPath, storage:StoragePath) {
			let identifier= type.identifier
			self.publicPaths[identifier] = public
			self.storagePaths[identifier]=storage
		}
	}

	/*
	A tenant client needs to be able to list his own rules and add/modify them.

	A Tenant rule can match on
   - FT Type
	 - NFT Type 
	 - listing type

	In the tenant rule we will have a dict {String:[Type]} that can be used to be flexible. So you can have keys here that are
	 - denyFT
	 - allowFT
	 - denyNFT
	 - allowNFT
	 - denyListing

	A tenant rule will have the following data
	 - a name
	 - the cut of the underlying middlelayer (only set by us/find)
	 - each sale type will have a NFT Type, a PrivatePath for Provider and a PublicPath for Receiver/MetadataView
	 - contains paths of all valid types that you want to sell (see addSaleType above) 

	A tenant owner must be able to set cuts based on types that cannot be overwritten

	Both must be able to stop listings of all types or deprecate listings of all type
	 - deprecation means existing ones are valid, but you cannot list new ones
	 - stopped means they are not valid anymore and will not be shown
  
	A tenant and an admin must be allowed to ban a user, if they do all listings from that user becomes invalid and that user cannot interact with the market.
	*/
	
	pub resource interface TenantPublic {

		pub fun getTenantInformation() : TenantInformation

		//Check if an action is allowed
//		pub fun isActionAllowed() : Bool //TODO: what parameters is available here

		pub fun getStoragePath(_ type: Type) : StoragePath? 
		pub fun getPublicPath(_ type: Type) : PublicPath? 
	}


	//this needs to be a resource so that nobody else can make it.
	pub resource Tenant : TenantPublic{

		pub let information : TenantInformation

		init(_ tenant: TenantInformation) {
			self.information=tenant
		}
		pub fun getTenantInformation() : TenantInformation {
			return self.information
		}

		pub fun getPublicPath(_ type: Type) : PublicPath? {
			return self.information.publicPaths[type.identifier]
		}

		pub fun getStoragePath(_ type: Type) : StoragePath? {
			return self.information.storagePaths[type.identifier]
		}
	}

	access(account) fun createTenant(_ tenant: TenantInformation) : @Tenant {
		return <- create Tenant(tenant)
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

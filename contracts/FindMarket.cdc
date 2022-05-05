import FungibleToken from "./standard/FungibleToken.cdc"
import FlowToken from "./standard/FlowToken.cdc"
import NonFungibleToken from "./standard/NonFungibleToken.cdc"
import MetadataViews from "./standard/MetadataViews.cdc"
import FindViews from "../contracts/FindViews.cdc"
import Profile from "./Profile.cdc"
import Clock from "./Clock.cdc"
import Debug from "./Debug.cdc"
import FindMarketTenant from "../contracts/FindMarketTenant.cdc"

pub contract FindMarket {

	pub event RoyaltyPaid(tenant:String, id: UInt64, address:Address, findName:String?, royaltyName:String, amount: UFix64, vaultType:String, nft:NFTInfo)

	access(account) fun pay(tenant: String, id: UInt64, saleItem: &{SaleItem}, vault: @FungibleToken.Vault, royalty: MetadataViews.Royalties?, nftInfo:NFTInfo, cuts:FindMarketTenant.TenantCuts) {
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

	pub struct NFTInfo {
		pub let name:String
		pub let description:String
		pub let thumbnail:String
		pub let type: String
		pub let id: UInt64 //id of item
		//TODO: add more views here, like rarity

		//BAM: fix this 
		init(_ item: &{MetadataViews.Resolver}, id: UInt64){
			let display = item.resolveView(Type<MetadataViews.Display>())! as! MetadataViews.Display
			self.name=display.name
			self.description=display.description
			self.thumbnail=display.thumbnail.uri()
			self.type=item.getType().identifier
			self.id=id
		}
	}

	pub struct GhostListing{
		pub let listingType: Type
		pub let listingTypeIdentifier: String
		pub let id: UInt64


		init(listingType:Type, id:UInt64) {
			self.listingType=listingType
			self.listingTypeIdentifier=listingType.identifier
			self.id=id
		}
	}

	//BAM: make this a struct with fields
	pub struct AuctionItem {
		pub let startPrice: UFix64 
		pub let minimumBidIncrement: UFix64 
		pub let reservePrice: UFix64 
		pub let extentionOnLateBid: UFix64 

		init(startPrice: UFix64, minimumBidIncrement: UFix64, reservePrice: UFix64, extentionOnLateBid: UFix64){
			self.startPrice = startPrice 
			self.minimumBidIncrement = minimumBidIncrement 
			self.reservePrice = reservePrice
			self.extentionOnLateBid = extentionOnLateBid
		}
	}

	pub resource interface SaleItemCollectionPublic {
		pub fun getIds(): [UInt64]
		pub fun getItemForSaleInformation(_ id:UInt64) : FindMarket.SaleItemInformation?
		pub fun getItemsForSale(): [FindMarket.SaleItemInformation]
		pub fun getGhostListings(): [FindMarket.GhostListing]
		//BAM: implement
		pub fun getSaleItemReport() : SaleItemCollectionReport
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
		pub fun getBids() : [BidInfo]
		pub fun getGhostListings() : [GhostListing]
		//TODO: do we need a get bid? to get a single bid?
		pub fun getBidsReport() : BidItemCollectionReport
	}

	pub struct BidItemCollectionReport {
		pub let items : [FindMarket.BidInfo] 
		pub let ghosts: [FindMarket.GhostListing]

	  init(items: [BidInfo], ghosts: [GhostListing]) {
			self.items=items
			self.ghosts=ghosts
		}
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

		pub fun getFtAlias(): String 
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
		
	}

	pub struct SaleItemInformation {

		//BAM: nftIdentifier
		pub let nftIdentifier: String 
		pub let nftId: UInt64
		pub let seller: Address
		pub let sellerName: String?
		pub let amount: UFix64?
		pub let bidder: Address?
		pub var bidderName: String?
		pub let listingId: UInt64

		//add listingIdentifer
		pub let saleType: String
		pub let listingTypeIdentifier: String
		pub let ftAlias: String 
		pub let ftTypeIdentifier: String
		pub let listingValidUntil: UFix64?

		pub let nft: NFTInfo
		pub let auction: AuctionItem?
//TOOD: end time, current time

		init(_ item: &{SaleItem}) {
			self.nftIdentifier= item.getItemType().identifier
			self.nftId=item.getItemID()
			self.saleType=item.getSaleType()
			self.listingTypeIdentifier=item.getListingTypeIdentifier()
			self.listingId=item.getId()
			self.amount=item.getBalance()
			self.bidder=item.getBuyer()
			self.bidderName=item.getBuyerName()
			self.seller=item.getSeller()
			self.sellerName=item.getSellerName()

			self.ftAlias=item.getFtAlias()
			self.listingValidUntil=item.getValidUntil()

			self.ftTypeIdentifier=item.getFtType().identifier

			self.nft=item.toNFTInfo()
			self.auction=item.getAuction()
		}
	}

	pub struct BidInfo{
		pub let id: UInt64
		pub let bidTypeIdentifier: String 
		pub let timestamp: UFix64
		pub let item: SaleItemInformation

		init(id: UInt64, bidTypeIdentifier: String,  amount: UFix64, timestamp: UFix64, item:SaleItemInformation) {
			self.id=id
			self.bidTypeIdentifier=bidTypeIdentifier
			self.timestamp=timestamp
			self.item=item
		}
	}
}

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

	access(account) fun pay(tenant: String, id: UInt64, saleItem: &{SaleItem}, vault: @FungibleToken.Vault, royalty: MetadataViews.Royalties?, nftInfo:NFTInfo, cuts:FindMarketTenant.TenantCuts, resolver: ((Address) : String?)) {
		let buyer=saleItem.getBuyer()
		let seller=saleItem.getSeller()
		let oldProfile= getAccount(seller).getCapability<&{Profile.Public}>(Profile.publicPath).borrow()!
		let soldFor=vault.balance
		let ftType=vault.getType()

		if royalty != nil {
			for royaltyItem in royalty!.getRoyalties() {
				let description=royaltyItem.description
				let cutAmount= soldFor * royaltyItem.cut
				let name = resolver(royaltyItem.receiver.address)
				emit RoyaltyPaid(tenant:tenant, id: id, address:royaltyItem.receiver.address, findName: name, royaltyName: description, amount: cutAmount,  vaultType: ftType.identifier, nft:nftInfo)
				royaltyItem.receiver.borrow()!.deposit(from: <- vault.withdraw(amount: cutAmount))
			}
		}

		if let findCut =cuts.findCut {
			let cutAmount= soldFor * findCut.cut
			let name = resolver(findCut.receiver.address)
			emit RoyaltyPaid(tenant: tenant, id: id, address:findCut.receiver.address, findName: name , royaltyName: "find", amount: cutAmount,  vaultType: ftType.identifier, nft:nftInfo)
			findCut.receiver.borrow()!.deposit(from: <- vault.withdraw(amount: cutAmount))
		}

		if let tenantCut =cuts.tenantCut {
			let cutAmount= soldFor * tenantCut.cut
			let name = resolver(tenantCut.receiver.address)
			emit RoyaltyPaid(tenant: tenant, id: id, address:tenantCut.receiver.address, findName: name, royaltyName: "marketplace", amount: cutAmount,  vaultType: ftType.identifier, nft:nftInfo)
			tenantCut.receiver.borrow()!.deposit(from: <- vault.withdraw(amount: cutAmount))
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
			if item.resolveView(Type<FindViews.NFTCollectionDisplay>()) != nil {
				let view = item.resolveView(Type<FindViews.NFTCollectionDisplay>())!
				if view as? FindViews.NFTCollectionDisplay != nil {
					let grouping = view as! FindViews.NFTCollectionDisplay
					self.collectionName=grouping.name
					self.collectionDescription=grouping.description
				}
			}
			
			self.rarity=nil
			if item.resolveView(Type<FindViews.Rarity>()) != nil {
				let view = item.resolveView(Type<FindViews.Rarity>())!
				if view as? FindViews.Rarity != nil {
					let rarity = view as! FindViews.Rarity
					self.rarity=rarity.rarityName
				}
			} 

			if item.resolveView(Type<FindViews.Tag>()) != nil {
				let view = item.resolveView(Type<FindViews.Tag>())!
				if view as? FindViews.Tag != nil {
					let tags = view as! FindViews.Tag
					self.tags=tags.getTag()
				}
			}

			if item.resolveView(Type<FindViews.Scalar>()) != nil {
				let view = item.resolveView(Type<FindViews.Scalar>())!
				if view as? FindViews.Scalar != nil {
					let scalar = view as! FindViews.Scalar
					self.scalars=scalar.getScalar()
				}
			}
			
			let display = item.resolveView(Type<MetadataViews.Display>())! as! MetadataViews.Display
			self.name=display.name
			self.thumbnail=display.thumbnail.uri()
			self.type=item.getType().identifier
			self.id=id

			self.editionNumber=nil
			self.totalInEdition=nil
			if item.resolveView(Type<FindViews.Edition>()) != nil {
				let view = item.resolveView(Type<FindViews.Edition>())!
				if view as? FindViews.Edition != nil {
					let edition = view as! FindViews.Edition
					self.editionNumber=edition.editionNumber
					self.totalInEdition=edition.totalInEdition
				}
			} 
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

	//BAM; this needs to know if an item is deprectaed or stopped in some way
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

		pub let auction: AuctionItem?
		pub let listingStatus:String

		init(item: &{SaleItem}, status:String) {
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

			self.ftAlias=item.getFtAlias()
			self.listingValidUntil=item.getValidUntil()

			self.ftTypeIdentifier=item.getFtType().identifier

			self.auction=item.getAuction()
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
}

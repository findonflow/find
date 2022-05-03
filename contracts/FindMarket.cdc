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

	pub struct interface AuctionItem {
		pub fun getReservePrice(): UFix64
		pub fun getExtentionOnLateBid(): UFix64
	}

	pub resource interface SaleItem {

		//this is the type of sale this is, auction, direct offer etc
		pub fun getSaleType(): String

		pub fun getSeller(): Address
		pub fun getBuyer(): Address?

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
}

import FungibleToken from "./standard/FungibleToken.cdc"
import NonFungibleToken from "./standard/NonFungibleToken.cdc"
import MetadataViews from "./standard/MetadataViews.cdc"
import FindViews from "../contracts/FindViews.cdc"
import Clock from "./Clock.cdc"
import FIND from "./FIND.cdc"
import Profile from "./Profile.cdc"
import FindMarket from "./FindMarket.cdc"

/*

A Find Market for direct sales
*/
pub contract FindMarketSale {

	pub event Sale(tenant: String, id: UInt64, saleID: UInt64, seller: Address, sellerName: String?, amount: UFix64, status: String, vaultType:String, nft: FindMarket.NFTInfo?, buyer:Address?, buyerName:String?, buyerAvatar: String?, endsAt:UFix64?)

	//A sale item for a direct sale
	pub resource SaleItem : FindMarket.SaleItem{

		//this is set when bought so that pay will work
		access(self) var buyer: Address?

		access(contract) let vaultType: Type //The type of vault to use for this sale Item
		access(contract) var pointer: FindViews.AuthNFTPointer

		//this field is set if this is a saleItem
		access(contract) var salePrice: UFix64
		access(contract) var validUntil: UFix64? 
		access(contract) let saleItemExtraField: {String : AnyStruct}

		access(contract) let totalRoyalties: UFix64 
		init(pointer: FindViews.AuthNFTPointer, vaultType: Type, price:UFix64, validUntil: UFix64?, saleItemExtraField: {String : AnyStruct}) {
			self.vaultType=vaultType
			self.pointer=pointer
			self.salePrice=price
			self.buyer=nil
			self.validUntil=validUntil
			self.saleItemExtraField=saleItemExtraField
			var royalties : UFix64 = 0.0
			self.totalRoyalties=self.pointer.getTotalRoyaltiesCut()
		}

		pub fun getSaleType() : String {
			return "active_listed"
		}

		pub fun getListingType() : Type {
			return Type<@SaleItem>()
		}

		pub fun getListingTypeIdentifier(): String {
			return Type<@SaleItem>().identifier
		}

		pub fun setBuyer(_ address:Address) {
			self.buyer=address
		}

		pub fun getBuyer(): Address? {
			return self.buyer
		}

		pub fun getBuyerName() : String? {
			if let address = self.buyer {
				return FIND.reverseLookup(address)
			}
			return nil
		}

		pub fun getId() : UInt64{
			return self.pointer.getUUID()
		}

		pub fun getItemID() : UInt64 {
			return self.pointer.id
		}

		pub fun getItemType() : Type {
			return self.pointer.getItemType()
		}

		pub fun getRoyalty() : MetadataViews.Royalties {
			return self.pointer.getRoyalty()
		}

		pub fun getSeller() : Address {
			return self.pointer.owner()
		}

		pub fun getSellerName() : String? {
			let address = self.pointer.owner()
			return FIND.reverseLookup(address)
		}

		pub fun getBalance() : UFix64 {
			return self.salePrice
		}

		pub fun getAuction(): FindMarket.AuctionItem? {
			return nil
		}

		pub fun getFtType() : Type  {
			return self.vaultType
		}

		pub fun setValidUntil(_ time: UFix64?) {
			self.validUntil=time
		}

		pub fun getValidUntil() : UFix64? {
			return self.validUntil 
		}

		pub fun toNFTInfo() : FindMarket.NFTInfo{
			return FindMarket.NFTInfo(self.pointer.getViewResolver(), id: self.pointer.id)
		}

		pub fun checkPointer() : Bool {
			return self.pointer.valid()
		}

		pub fun getSaleItemExtraField() : {String : AnyStruct} {
			return self.saleItemExtraField
		}
		
		pub fun getTotalRoyalties() : UFix64 {
			return self.totalRoyalties
		}

		pub fun getDisplay() : MetadataViews.Display {
			return self.pointer.getDisplay()
		}

		pub fun getNFTCollectionData() : MetadataViews.NFTCollectionData {
			return self.pointer.getNFTCollectionData()
		}
	}

	pub resource interface SaleItemCollectionPublic {
		//fetch all the tokens in the collection
		pub fun getIds(): [UInt64]
		pub fun borrowSaleItem(_ id: UInt64) : &{FindMarket.SaleItem} //TODO: look if this is safe
		pub fun containsId(_ id: UInt64): Bool
		pub fun buy(id: UInt64, vault: @FungibleToken.Vault, nftCap: Capability<&{NonFungibleToken.Receiver}>) 
	}

	pub resource SaleItemCollection: SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic {
		//is this the best approach now or just put the NFT inside the saleItem?
		access(contract) var items: @{UInt64: SaleItem}

		access(contract) let tenantCapability: Capability<&FindMarket.Tenant{FindMarket.TenantPublic}>

		init (_ tenantCapability: Capability<&FindMarket.Tenant{FindMarket.TenantPublic}>) {
			self.items <- {}
			self.tenantCapability=tenantCapability
		}

		access(self) fun getTenant() : &FindMarket.Tenant{FindMarket.TenantPublic} {
			pre{
				self.tenantCapability.check() : "Tenant client is not linked anymore"
			}
			return self.tenantCapability.borrow()!
		}

		pub fun getListingType() : Type {
			return Type<@SaleItem>()
		}

		pub fun buy(id: UInt64, vault: @FungibleToken.Vault, nftCap: Capability<&{NonFungibleToken.Receiver}>) {
			pre {
				self.items.containsKey(id) : "Invalid id=".concat(id.toString())
				self.owner!.address != nftCap.address : "You cannot buy your own listing"
				nftCap.check() : "The nft receiver capability passed in is invalid."
			}

			//TOOD: method on saleItems that returns a cacheKey listingType-nftType-ftType

			let saleItem=self.borrow(id)
			//149
			if saleItem.salePrice != vault.balance {
				panic("Incorrect balance sent in vault. Expected ".concat(saleItem.salePrice.toString()).concat(" got ").concat(vault.balance.toString()))
			}
			//152

			if saleItem.validUntil != nil && saleItem.validUntil! < Clock.time() {
				panic("This sale item listing is already expired")
			}

			if saleItem.vaultType != vault.getType() {
				panic("This item can be baught using ".concat(saleItem.vaultType.identifier).concat(" you have sent in ").concat(vault.getType().identifier))
			}
			//158
			let tenant=self.getTenant()
			//164

			let actionResult=self.getTenant().allowedAction(listingType: Type<@FindMarketSale.SaleItem>(), nftType: saleItem.getItemType(), ftType: saleItem.getFtType(), action: FindMarket.MarketAction(listing:false, name: "buy item for sale"), seller: self.owner!.address, buyer: nftCap.address)

			if !actionResult.allowed {
				panic(actionResult.message)
			}

			let cuts= self.getTenant().getTeantCut(name: actionResult.name, listingType: Type<@FindMarketSale.SaleItem>(), nftType: saleItem.getItemType(), ftType: saleItem.getFtType())
			//272 -40

			let ftType=saleItem.vaultType
			let owner=saleItem.getSeller()
			//278


			/*
			let item=saleItem.pointer.getViewResolver()
			//286

			let ncd = MetadataViews.getNFTCollectionData(item) 
			//314

			let ncd2 = MetadataViews.getNFTCollectionDisplay(item) 
			//450 //a lot of this is minter
			*/
    
			let nftInfo= saleItem.toNFTInfo()
			//559


			let royalty=saleItem.getRoyalty()
			//624

			let soldFor=saleItem.getBalance()
			//627
			saleItem.setBuyer(nftCap.address)
			let buyer=nftCap.address
			//631
			let buyerName=FIND.reverseLookup(buyer)
			//676

			let profile= Profile.find(nftCap.address)
			//682

			emit Sale(tenant:self.getTenant().name, id: id, saleID: saleItem.uuid, seller:owner, sellerName: FIND.reverseLookup(owner), amount: soldFor, status:"sold", vaultType: ftType.identifier, nft:nftInfo, buyer: buyer, buyerName: buyerName, buyerAvatar: profile.getAvatar() ,endsAt:saleItem.validUntil)
			//735


			//TODO: make the resolver a little bit smarter, preresolve things like tenants and find?
			//Add seller/buyer/find/tenant to map and lookup in that before calling reverseLookup
			FindMarket.pay(tenant:self.getTenant().name, id:id, saleItem: saleItem, vault: <- vault, royalty:royalty, nftInfo:nftInfo, cuts:cuts, resolver: fun(address:Address): String? { return FIND.reverseLookup(address) }, rewardFN: FIND.rewardFN())
			//1351
			
				nftCap.borrow()!.deposit(token: <- saleItem.pointer.withdraw())
			//1564

			destroy <- self.items.remove(key: id)
		}

		pub fun listForSale(pointer: FindViews.AuthNFTPointer, vaultType: Type, directSellPrice:UFix64, validUntil: UFix64?, extraField: {String:AnyStruct}) {

			// What happends if we relist  
			let saleItem <- create SaleItem(pointer: pointer, vaultType:vaultType, price: directSellPrice, validUntil: validUntil, saleItemExtraField:extraField)

			let actionResult=self.getTenant().allowedAction(listingType: Type<@FindMarketSale.SaleItem>(), nftType: saleItem.getItemType(), ftType: saleItem.getFtType(), action: FindMarket.MarketAction(listing:true, name: "list item for sale"), seller: self.owner!.address, buyer: nil)

			if !actionResult.allowed {
				panic(actionResult.message)
				// let message = "vault : ".concat(vaultType.identifier).concat(" . NFT Type : ".concat(saleItem.getItemType().identifier))
				// panic(message)
			}

			let owner=self.owner!.address
			emit Sale(tenant: self.getTenant().name, id: pointer.getUUID(), saleID: saleItem.uuid, seller:owner, sellerName: FIND.reverseLookup(owner), amount: saleItem.salePrice, status: "active_listed", vaultType: vaultType.identifier, nft:FindMarket.NFTInfo(pointer.getViewResolver(), id: pointer.id), buyer: nil, buyerName:nil, buyerAvatar:nil, endsAt:saleItem.validUntil)
			let old <- self.items[pointer.getUUID()] <- saleItem
			destroy old

		}

		pub fun delist(_ id: UInt64) {
			pre {
				self.items.containsKey(id) : "Unknown item with id=".concat(id.toString())
			}

			let saleItem <- self.items.remove(key: id)!

			if saleItem.checkPointer() {
				let actionResult=self.getTenant().allowedAction(listingType: Type<@FindMarketSale.SaleItem>(), nftType: saleItem.getItemType(), ftType: saleItem.getFtType(), action: FindMarket.MarketAction(listing:false, name: "delist item for sale"), seller: nil, buyer: nil)

				if !actionResult.allowed {
					panic(actionResult.message)
				}
				let owner=self.owner!.address
				emit Sale(tenant:self.getTenant().name, id: id, saleID: saleItem.uuid, seller:owner, sellerName:FIND.reverseLookup(owner), amount: saleItem.salePrice, status: "cancel", vaultType: saleItem.vaultType.identifier,nft: FindMarket.NFTInfo(saleItem.pointer.getViewResolver(), id:saleItem.pointer.id), buyer:nil, buyerName:nil, buyerAvatar:nil, endsAt:saleItem.validUntil)
				destroy saleItem
				return
			}

			let owner=self.owner!.address
			if !saleItem.checkPointer() {
				emit Sale(tenant:self.getTenant().name, id: id, saleID: saleItem.uuid, seller:owner, sellerName:FIND.reverseLookup(owner), amount: saleItem.salePrice, status: "cancel", vaultType: saleItem.vaultType.identifier,nft: nil, buyer:nil, buyerName:nil, buyerAvatar:nil, endsAt:saleItem.validUntil)
			} else {
				emit Sale(tenant:self.getTenant().name, id: id, saleID: saleItem.uuid, seller:owner, sellerName:FIND.reverseLookup(owner), amount: saleItem.salePrice, status: "cancel", vaultType: saleItem.vaultType.identifier,nft: FindMarket.NFTInfo(saleItem.pointer.getViewResolver(), id:saleItem.pointer.id), buyer:nil, buyerName:nil, buyerAvatar:nil, endsAt:saleItem.validUntil)
			}
			destroy saleItem
		}

		pub fun getIds(): [UInt64] {
			return self.items.keys
		}

		pub fun containsId(_ id: UInt64): Bool {
			return self.items.containsKey(id)
		}
		
		pub fun borrow(_ id: UInt64): &SaleItem {
			return (&self.items[id] as &SaleItem?)!
		}

		pub fun borrowSaleItem(_ id: UInt64) : &{FindMarket.SaleItem} {
			pre{
				self.items.containsKey(id) : "This id does not exist : ".concat(id.toString())
			}
			return (&self.items[id] as &SaleItem{FindMarket.SaleItem}?)!
		}

		destroy() {
			destroy self.items
		}
	}

	//Create an empty lease collection that store your leases to a name
	pub fun createEmptySaleItemCollection(_ tenantCapability: Capability<&FindMarket.Tenant{FindMarket.TenantPublic}>): @SaleItemCollection {
		return <- create SaleItemCollection(tenantCapability)
	}

	pub fun getSaleItemCapability(marketplace:Address, user:Address) : Capability<&FindMarketSale.SaleItemCollection{FindMarketSale.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>? {
		if let  tenantCap=FindMarket.getTenantCapability(marketplace) {
			let tenant=tenantCap.borrow() ?? panic("Invalid tenant")
			return getAccount(user).getCapability<&FindMarketSale.SaleItemCollection{FindMarketSale.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(tenant.getPublicPath(Type<@SaleItemCollection>()))
		}
		return nil
	}


	init() {
		FindMarket.addSaleItemType(Type<@SaleItem>())
		FindMarket.addSaleItemCollectionType(Type<@SaleItemCollection>())
	}
}

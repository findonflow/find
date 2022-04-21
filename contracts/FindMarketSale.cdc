import FungibleToken from "./standard/FungibleToken.cdc"
import FlowToken from "./standard/FlowToken.cdc"
import NonFungibleToken from "./standard/NonFungibleToken.cdc"
import MetadataViews from "./standard/MetadataViews.cdc"
import FindViews from "../contracts/FindViews.cdc"
import Profile from "./Profile.cdc"
import Clock from "./Clock.cdc"
import Debug from "./Debug.cdc"
import FIND from "./FIND.cdc"
import FindMarket from "./FindMarket.cdc"
/*

A Find Market for direct sales
*/
pub contract FindMarketSale {

	pub event ForSale(tenant: String, id: UInt64, seller: Address, sellerName: String?, amount: UFix64, status: String, vaultType:String, nft: FindMarket.NFTInfo, buyer:Address?, buyerName:String?)

	//A sale item for a direct sale
	pub resource SaleItem : FindMarket.SaleItem{

		//this is set when bought so that pay will work
		access(self) var buyer: Address?

		access(contract) let vaultType: Type //The type of vault to use for this sale Item
		access(contract) var pointer: FindViews.AuthNFTPointer

		//this field is set if this is a saleItem
		access(contract) var salePrice: UFix64

		init(pointer: FindViews.AuthNFTPointer, vaultType: Type, price:UFix64) {
			self.vaultType=vaultType
			self.pointer=pointer
			self.salePrice=price
			self.buyer=nil
		}


		pub fun getSaleType() : String {
			return "directSale"
		}

		pub fun setBuyer(_ address:Address) {
			self.buyer=address
		}

		pub fun getBuyer(): Address? {
			return self.buyer
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

		pub fun getRoyalty() : FindViews.Royalties? {
			if self.pointer.getViews().contains(Type<FindViews.Royalties>()) {
				return self.pointer.resolveView(Type<FindViews.Royalties>())! as! FindViews.Royalties
			}

			return  nil
		}

		pub fun getSeller() : Address {
			return self.pointer.owner()
		}

		pub fun toNFTInfo() : FindMarket.NFTInfo{
			return FindMarket.NFTInfo(self.pointer.getViewResolver())
		}

		pub fun getBalance() : UFix64 {
			return self.salePrice
		}

		pub fun getAuction(): AnyStruct{FindMarket.AuctionItem}? {
			return nil
		}

		pub fun getFtType() : Type  {
			return self.vaultType
		}

		pub fun getValidUntil() : UFix64? {
			return nil 
		}
	}

	pub resource interface SaleItemCollectionPublic {
		//fetch all the tokens in the collection
		pub fun getIds(): [UInt64]
		//fetch all names that are for sale

		pub fun getItemsForSale(): [FindMarket.SaleItemInformation]

		pub fun getItemForSaleInformation(_ id:UInt64) : FindMarket.SaleItemInformation 

		pub fun buy(id: UInt64, vault: @FungibleToken.Vault, nftCap: Capability<&{NonFungibleToken.Receiver}>) 
	}

	pub resource SaleItemCollection: SaleItemCollectionPublic {
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

		pub fun getItemForSaleInformation(_ id:UInt64) : FindMarket.SaleItemInformation {
			pre {
				self.items.containsKey(id) : "Invalid id=".concat(id.toString())
			}
			return FindMarket.SaleItemInformation(self.borrow(id))

		}

		pub fun getItemsForSale(): [FindMarket.SaleItemInformation] {
			let info: [FindMarket.SaleItemInformation] =[]
			for id in self.getIds() {
				info.append(FindMarket.SaleItemInformation(self.borrow(id)))
			}
			return info
		}
	
		pub fun buy(id: UInt64, vault: @FungibleToken.Vault, nftCap: Capability<&{NonFungibleToken.Receiver}>) {
			pre {
				self.items.containsKey(id) : "Invalid id=".concat(id.toString())
			}

			let saleItem=self.borrow(id)

			if saleItem.salePrice != vault.balance {
				panic("Incorrect balance sent in vault. Expected ".concat(saleItem.salePrice.toString()).concat(" got ").concat(vault.balance.toString()))
			}

			if saleItem.vaultType != vault.getType() {
				panic("This item can be baught using ".concat(saleItem.vaultType.identifier).concat(" you have sent in ").concat(vault.getType().identifier))
			}

			let actionResult=self.getTenant().allowedAction(listingType: Type<@FindMarketSale.SaleItem>(), nftType: saleItem.getItemType(), ftType: saleItem.getFtType(), action: FindMarket.MarketAction(mutating:true, "buy"))

			if !actionResult.allowed {
				panic(actionResult.message)
			}

			let cuts= self.getTenant().getTeantCut(name: actionResult.name, listingType: Type<@FindMarketSale.SaleItem>(), nftType: saleItem.getItemType(), ftType: saleItem.getFtType())

			let ftType=saleItem.vaultType
			let owner=saleItem.getSeller()
			let nftInfo= saleItem.toNFTInfo()

			let royalty=saleItem.getRoyalty()
			let soldFor=saleItem.getBalance()
			saleItem.setBuyer(nftCap.address)
			let buyer=nftCap.address

			emit ForSale(tenant:self.getTenant().name, id: id, seller:owner, sellerName: FIND.reverseLookup(owner), amount: soldFor, status:"sold", vaultType: ftType.identifier, nft:nftInfo, buyer: buyer, buyerName: FIND.reverseLookup(buyer))

			FindMarket.pay(tenant:self.getTenant().name, id:id, saleItem: saleItem, vault: <- vault, royalty:royalty, nftInfo:nftInfo, cuts:cuts)
			nftCap.borrow()!.deposit(token: <- saleItem.pointer.withdraw())

  		destroy <- self.items.remove(key: id)
		}

		pub fun listForSale(pointer: FindViews.AuthNFTPointer, vaultType: Type, directSellPrice:UFix64) {
      
			// What happends if we relist  
			let saleItem <- create SaleItem(pointer: pointer, vaultType:vaultType, price: directSellPrice)
			let owner=self.owner!.address
			emit ForSale(tenant: self.getTenant().name, id: pointer.getUUID(), seller:owner, sellerName: FIND.reverseLookup(owner), amount: saleItem.salePrice, status: "listed", vaultType: vaultType.identifier, nft:FindMarket.NFTInfo(pointer.getViewResolver()), buyer: nil, buyerName:nil)
			let old <- self.items[pointer.getUUID()] <- saleItem
			destroy old

		}

		pub fun delist(_ id: UInt64) {
			pre {
				self.items.containsKey(id) : "Unknown item with id=".concat(id.toString())
			}

			let saleItem <- self.items.remove(key: id)!
			let owner=self.owner!.address
			emit ForSale(tenant:self.getTenant().name, id: id, seller:owner, sellerName:FIND.reverseLookup(owner), amount: saleItem.salePrice, status: "cancelled", vaultType: saleItem.vaultType.identifier,nft: FindMarket.NFTInfo(saleItem.pointer.getViewResolver()), buyer:nil, buyerName:nil)
			destroy saleItem
		}

		pub fun getIds(): [UInt64] {
			return self.items.keys
		}

		pub fun borrow(_ id: UInt64): &SaleItem {
			return &self.items[id] as &SaleItem
		}

		destroy() {
			destroy self.items
		}
	}



	//Create an empty lease collection that store your leases to a name
	pub fun createEmptySaleItemCollection(_ tenantCapability: Capability<&FindMarket.Tenant{FindMarket.TenantPublic}>): @SaleItemCollection {
		let wallet=FindMarketSale.account.getCapability<&{FungibleToken.Receiver}>(Profile.publicReceiverPath)
		return <- create SaleItemCollection(tenantCapability)
	}

	pub fun getFindSaleItemCapability(_ user: Address) : Capability<&FindMarketSale.SaleItemCollection{FindMarketSale.SaleItemCollectionPublic}>? {
		return FindMarketSale.getSaleItemCapability(marketplace: FindMarketSale.account.address, user:user) 
	}

	pub fun getSaleItemCapability(marketplace:Address, user:Address) : Capability<&FindMarketSale.SaleItemCollection{FindMarketSale.SaleItemCollectionPublic}>? {
		pre{
			FindMarket.getTenantCapability(marketplace) != nil : "Invalid tenant"
		}
		if let tenant=FindMarket.getTenantCapability(marketplace)!.borrow() {
			return getAccount(user).getCapability<&FindMarketSale.SaleItemCollection{FindMarketSale.SaleItemCollectionPublic}>(tenant.getPublicPath(Type<@FindMarketSale.SaleItemCollection>()))
		}
		return nil
	}
}

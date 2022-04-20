import FungibleToken from "./standard/FungibleToken.cdc"
import FUSD from "./standard/FUSD.cdc"
import NonFungibleToken from "./standard/NonFungibleToken.cdc"
import Profile from "./Profile.cdc"
import FIND from "./FIND.cdc"
import Debug from "./Debug.cdc"
import Dandy from "./Dandy.cdc"
import Clock from "./Clock.cdc"
import CharityNFT from "./CharityNFT.cdc"
import FindViews from "./FindViews.cdc"
import MetadataViews from "./standard/MetadataViews.cdc"
import FindMarket from "./FindMarket.cdc"
import FindMarketSale from "./FindMarketSale.cdc"
import FindMarketDirectOfferEscrow from "./FindMarketDirectOfferEscrow.cdc"
import FindMarketDirectOfferSoft from "./FindMarketDirectOfferSoft.cdc"
import FindMarketAuctionEscrow from "./FindMarketAuctionEscrow.cdc"
import FindMarketAuctionSoft from "./FindMarketAuctionSoft.cdc"
import FTRegistry from "./FTRegistry.cdc"
import NFTRegistry from "./NFTRegistry.cdc"


pub contract Admin {

	//store the proxy for the admin
	pub let AdminProxyPublicPath: PublicPath
	pub let AdminProxyStoragePath: StoragePath

	/// ===================================================================================
	// Admin things
	/// ===================================================================================

	//Admin client to use for capability receiver pattern
	pub fun createAdminProxyClient() : @AdminProxy {
		return <- create AdminProxy()
	}

	//interface to use for capability receiver pattern
	pub resource interface AdminProxyClient {
		pub fun addCapability(_ cap: Capability<&FIND.Network>)
	}

	//admin proxy with capability receiver 
	pub resource AdminProxy: AdminProxyClient {

		access(self) var capability: Capability<&FIND.Network>?

		pub fun addCapability(_ cap: Capability<&FIND.Network>) {
			pre {
				cap.check() : "Invalid server capablity"
				self.capability == nil : "Server already set"
			}
			self.capability = cap
		}

		pub fun createFindMarketTenant() : @FindMarket.Tenant {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}

			let saleItemPublicPath= /public/findfindMarketSale
			let saleItemStoragePath= /storage/findfindMarketSale

			let receiver=Admin.account.getCapability<&{FungibleToken.Receiver}>(Profile.publicReceiverPath)
			let findRoyalty=FindViews.Royalty(receiver: receiver, cut: 0.025, description: "find")
			let tenant=FindMarket.TenantInformation( name: "find", validNFTTypes: [], ftTypes:[], findCut: findRoyalty, tenantCut: nil)
			tenant.addSaleType(type: Type<@FindMarketSale.SaleItemCollection>(), public: saleItemPublicPath, storage: saleItemStoragePath) 


			//direct offfer escrowed
			let doeSaleItemPublicPath= /public/findfindMarketDOE
			let doeSaleItemStoragePath= /storage/findfindMarketDOE
			tenant.addSaleType(type: Type<@FindMarketDirectOfferEscrow.SaleItemCollection>(), public: doeSaleItemPublicPath, storage:doeSaleItemStoragePath) 

			let doeBidPublicPath= /public/findfindMarketDOEBid
			let doeBidStoragePath= /storage/findfindMarketDOEBid
			tenant.addSaleType(type: Type<@FindMarketDirectOfferEscrow.MarketBidCollection>(), public: doeBidPublicPath, storage:doeBidStoragePath) 


			//direct offfer soft
			let dosSaleItemPublicPath= /public/findfindMarketDOS
			let dosSaleItemStoragePath= /storage/findfindMarketDOS
			tenant.addSaleType(type: Type<@FindMarketDirectOfferSoft.SaleItemCollection>(), public: dosSaleItemPublicPath, storage:dosSaleItemStoragePath) 

			let dosBidPublicPath= /public/findfindMarketDOSBid
			let dosBidStoragePath= /storage/findfindMarketDOSBid
			tenant.addSaleType(type: Type<@FindMarketDirectOfferSoft.MarketBidCollection>(), public: dosBidPublicPath, storage:dosBidStoragePath) 


			//auction escrowed
			let aeSaleItemPublicPath= /public/findfindMarketAE
			let aeSaleItemStoragePath= /storage/findfindMarketAE
			tenant.addSaleType(type: Type<@FindMarketAuctionEscrow.SaleItemCollection>(), public: aeSaleItemPublicPath, storage:aeSaleItemStoragePath) 

			let aeBidPublicPath= /public/findfindMarketAEBid
			let aeBidStoragePath= /storage/findfindMarketAEBid
			tenant.addSaleType(type: Type<@FindMarketAuctionEscrow.MarketBidCollection>(), public: aeBidPublicPath, storage:aeBidStoragePath) 

			//auction 
			let asSaleItemPublicPath= /public/findfindMarketAS
			let asSaleItemStoragePath= /storage/findfindMarketAS
			tenant.addSaleType(type: Type<@FindMarketAuctionSoft.SaleItemCollection>(), public: asSaleItemPublicPath, storage:asSaleItemStoragePath) 

			let asBidPublicPath= /public/findfindMarketASBid
			let asBidStoragePath= /storage/findfindMarketASBid
			tenant.addSaleType(type: Type<@FindMarketAuctionSoft.MarketBidCollection>(), public: asBidPublicPath, storage:asBidStoragePath) 


			return <- FindMarket.createTenant(tenant)
		}

		/// Set the wallet used for the network
		/// @param _ The FT receiver to send the money to
		pub fun setWallet(_ wallet: Capability<&{FungibleToken.Receiver}>) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}

			self.capability!.borrow()!.setWallet(wallet)
		}

		/// Enable or disable public registration 
		pub fun setPublicEnabled(_ enabled: Bool) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}

			self.capability!.borrow()!.setPublicEnabled(enabled)
		}

		pub fun setAddonPrice(name: String, price: UFix64) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}

			self.capability!.borrow()!.setAddonPrice(name: name, price: price)
		}

		pub fun setPrice(default: UFix64, additional : {Int: UFix64}) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}

			self.capability!.borrow()!.setPrice(default: default, additionalPrices: additional)
		}

		pub fun register(name: String, profile: Capability<&{Profile.Public}>, leases: Capability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>){
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
				FIND.validateFindName(name) : "A FIND name has to be lower-cased alphanumeric or dashes and between 3 and 16 characters"
			}

			self.capability!.borrow()!.internal_register(name:name, profile: profile, leases: leases)
		}

		pub fun mintCharity(metadata : {String: String}, recipient: Capability<&{NonFungibleToken.CollectionPublic}>){
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}

			CharityNFT.mintCharity(metadata: metadata, recipient: recipient)
		}

		pub fun advanceClock(_ time: UFix64) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}
			Debug.enable(true)
			Clock.enable()
			Clock.tick(time)
		}


		pub fun debug(_ value: Bool) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}
			Debug.enable(value)
		}

		pub fun setViewConverters(from: Type, converters: [{Dandy.ViewConverter}]) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}

			Dandy.setViewConverters(from: from, converters: converters)
		}

		pub fun createForge(platform: Dandy.MinterPlatform) : @Dandy.Forge {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}
			return <- Dandy.createForge(platform:platform)
		}

		/// ===================================================================================
		// Fungible Token Registry 
		/// ===================================================================================

		// Registry FungibleToken Information
		pub fun setFTInfo(alias: String, type: Type, tag: [String], icon: String?, receiverPath: PublicPath, balancePath: PublicPath, vaultPath: StoragePath) {
			FTRegistry.setFTInfo(alias: alias, type: type, tag: tag, icon: icon, receiverPath: receiverPath, balancePath: balancePath, vaultPath:vaultPath)

		}

		// Remove FungibleToken Information by type identifier
		pub fun removeFTInfoByTypeIdentifier(_ typeIdentifier: String) {
			FTRegistry.removeFTInfoByTypeIdentifier(typeIdentifier)
		}


		// Remove FungibleToken Information by alias
		pub fun removeFTInfoByAlias(_ alias: String) {
			FTRegistry.removeFTInfoByAlias(alias)
		}

		/// ===================================================================================
		// NonFungibleToken Registry 
		/// ===================================================================================
		// Registry NonFungibleToken Information
		pub fun setNFTInfo(alias: String, type: Type, icon: String?, providerPath: PrivatePath, publicPath: PublicPath, storagePath: StoragePath, allowedFTTypes: [Type]?, address: Address) {
			NFTRegistry.setNFTInfo(alias: alias, type: type, icon: icon, providerPath: providerPath, publicPath: publicPath, storagePath: storagePath, allowedFTTypes: allowedFTTypes, address: address)

		}

		// Remove NonFungibleToken Information by type identifier
		pub fun removeNFTInfoByTypeIdentifier(_ typeIdentifier: String) {
			NFTRegistry.removeNFTInfoByTypeIdentifier(typeIdentifier)
		}

		// Remove NonFungibleToken Information by alias
		pub fun removeNFTInfoByAlias(_ alias: String) {
			NFTRegistry.removeNFTInfoByAlias(alias)
		}

		// Remove NonFungibleToken Information by alias
		pub fun removeNFTInfoByAlias(_ alias: String) {
			NFTRegistry.removeNFTInfoByAlias(alias)
		}


		//TODO: set that primary cut has been paid
		//TODO; ban a user and modify scripts/tx to honor ban
		init() {
			self.capability = nil
		}

	}

	init() {

		self.AdminProxyPublicPath= /public/findAdminProxy
		self.AdminProxyStoragePath=/storage/findAdminProxy
	}

}

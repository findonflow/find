import FungibleToken from "./standard/FungibleToken.cdc"
import NonFungibleToken from "./standard/NonFungibleToken.cdc"
import Profile from "./Profile.cdc"
import FIND from "./FIND.cdc"
import Debug from "./Debug.cdc"
import Dandy from "./Dandy.cdc"
import Clock from "./Clock.cdc"
import CharityNFT from "./CharityNFT.cdc"
import FindViews from "./FindViews.cdc"
import MetadataViews from "./standard/MetadataViews.cdc"
import FTRegistry from "./FTRegistry.cdc"
import NFTRegistry from "./NFTRegistry.cdc"
import FindMarket from "./FindMarket.cdc"

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

		/*
		pub fun addTenantItem(_ item: FindMarket.TenantSaleItem) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}

			self.capability!.borrow()!.addTenantItem(item)

		}
		*/

		pub fun createFindMarket(name: String, address:Address) : Capability<&FindMarket.Tenant> {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}

			return  FindMarket.createFindMarket(name:name, address:address)
		}

		/// Set the wallet used for the network
		/// @param _ The FT receiver to send the money to
		pub fun setWallet(_ wallet: Capability<&{FungibleToken.Receiver}>) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}

			self.capability!.borrow()!.setWallet(wallet)
		}

		pub fun getFindMarketClient():  &FindMarket.TenantClient{
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}

      let path = FindMarket.TenantClientStoragePath
      return Admin.account.borrow<&FindMarket.TenantClient>(from: path) ?? panic("Cannot borrow Reference.")
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
		pub fun setNFTInfo(alias: String, type: Type, icon: String?, providerPath: PrivatePath, publicPath: PublicPath, storagePath: StoragePath, allowedFTTypes: [Type]?, address: Address, externalFixedUrl: String) {
			NFTRegistry.setNFTInfo(alias: alias, type: type, icon: icon, providerPath: providerPath, publicPath: publicPath, storagePath: storagePath, allowedFTTypes: allowedFTTypes, address: address, externalFixedUrl: externalFixedUrl)

		}

		// Remove NonFungibleToken Information by type identifier
		pub fun removeNFTInfoByTypeIdentifier(_ typeIdentifier: String) {
			NFTRegistry.removeNFTInfoByTypeIdentifier(typeIdentifier)
		}

		// Remove NonFungibleToken Information by alias
		pub fun removeNFTInfoByAlias(_ alias: String) {
			NFTRegistry.removeNFTInfoByAlias(alias)
		}

		/// ===================================================================================
		// Find Market Options 
		/// ===================================================================================
		pub fun addSaleItemType(_ type: Type) {
			FindMarket.addSaleItemType(type) 
		}

		pub fun addMarketBidType(_ type: Type) {
			FindMarket.addMarketBidType(type) 
		}

		pub fun addSaleItemCollectionType(_ type: Type) {
			FindMarket.addSaleItemCollectionType(type) 
		}

		pub fun addMarketBidCollectionType(_ type: Type) {
			FindMarket.addMarketBidCollectionType(type) 
		}

		pub fun removeSaleItemType(_ type: Type) {
			FindMarket.removeSaleItemType(type) 
		}

		pub fun removeMarketBidType(_ type: Type) {
			FindMarket.removeMarketBidType(type) 
		}

		pub fun removeSaleItemCollectionType(_ type: Type) {
			FindMarket.removeSaleItemCollectionType(type) 
		}

		pub fun removeMarketBidCollectionType(_ type: Type) {
			FindMarket.removeMarketBidCollectionType(type) 
		}

		/// ===================================================================================
		// Tenant Rules Management
		/// ===================================================================================
		pub fun getTenantRef(_ tenant: Address) : &FindMarketTenant.Tenant {
			let string = FindMarketTenant.getTenantPathForAddress(tenant)
			let sp = StoragePath(identifier: string) ?? panic("Cannot generate storage path from string : ".concat(string))
			return Admin.account.borrow<&FindMarketTenant.Tenant>(from: sp) ?? panic("Cannot borrow tenant reference.")
		}

		pub fun setMarketOption(tenant: Address, name: String, cut: MetadataViews.Royalty?, rules: [FindMarketTenant.TenantRule]) {
			let tenant = self.getTenantRef(tenant) 
			tenant.addSaleItem(FindMarketTenant.TenantSaleItem(
				name: name, 
				cut: cut, 
				rules: rules, 
				status:"active"
			), type: "tenant")
			//Emit Event here
		}

		pub fun removeMarketOption(tenant: Address, name: String) {
			let tenant = self.getTenantRef(tenant) 
			tenant.removeSaleItem(name, type: "tenant")
		}

		pub fun enableMarketOption(tenant: Address, name: String) {
			let tenant = self.getTenantRef(tenant) 
			tenant.alterMarketOption(name: name, status: "active")
		}

		pub fun deprecateMarketOption(tenant: Address, name: String) {
			let tenant = self.getTenantRef(tenant) 
			tenant.alterMarketOption(name: name, status: "deprecated")
		}

		pub fun stopMarketOption(tenant: Address, name: String) {
			let tenant = self.getTenantRef(tenant) 
			tenant.alterMarketOption(name: name, status: "stopped")
		}

		pub fun setTenantRule(tenant: Address, optionName: String, tenantRule: FindMarketTenant.TenantRule) {
			let tenantRef = self.getTenantRef(tenant)
			tenantRef.setTenantRule(optionName: optionName, tenantRule: tenantRule)
		}

		pub fun removeTenantRule(tenant: Address, optionName: String, tenantRuleName: String) {
			let tenantRef = self.getTenantRef(tenant)
			tenantRef.removeTenantRule(optionName: optionName, tenantRuleName: tenantRuleName)
		}


		init() {
			self.capability = nil
		}

	}

	init() {

		self.AdminProxyPublicPath= /public/findAdminProxy
		self.AdminProxyStoragePath=/storage/findAdminProxy
	}

}

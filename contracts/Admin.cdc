import FungibleToken from "./standard/FungibleToken.cdc"
import NonFungibleToken from "./standard/NonFungibleToken.cdc"
import MetadataViews from "./standard/MetadataViews.cdc"
import Profile from "./Profile.cdc"
import FIND from "./FIND.cdc"
import Debug from "./Debug.cdc"
import Clock from "./Clock.cdc"
import FTRegistry from "./FTRegistry.cdc"
import FindMarket from "./FindMarket.cdc"
import FindForge from "./FindForge.cdc"
import FindForgeOrder from "./FindForgeOrder.cdc"
import FindPack from "./FindPack.cdc"
import NFTCatalog from "./standard/NFTCatalog.cdc"
import FINDNFTCatalogAdmin from "./FINDNFTCatalogAdmin.cdc"
import FindViews from "./FindViews.cdc"

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

		pub fun addPublicForgeType(name: String, forgeType : Type) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}

			FindForge.addPublicForgeType(forgeType: forgeType)
		}

		pub fun addPrivateForgeType(name: String, forgeType : Type) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}

			FindForge.addPrivateForgeType(name: name, forgeType: forgeType)
		}

		pub fun removeForgeType(_ type : Type) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}

			FindForge.removeForgeType(type: type)
		}

		pub fun addForgeContractData(lease: String, forgeType: Type , data: AnyStruct) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}

			FindForge.adminAddContractData(lease: lease, forgeType: forgeType , data: data)
		}

		pub fun addForgeMintType(_ mintType: String) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}

			FindForgeOrder.addMintType(mintType)
		}

		pub fun orderForge(leaseName: String, mintType: String, minterCut: UFix64?, collectionDisplay: MetadataViews.NFTCollectionDisplay) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}

			FindForge.adminOrderForge(leaseName: leaseName, mintType: mintType, minterCut: minterCut, collectionDisplay: collectionDisplay)
		}

		pub fun cancelForgeOrder(leaseName: String, mintType: String){
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}
			FindForge.cancelForgeOrder(leaseName: leaseName, mintType: mintType)
		}

		pub fun fulfillForgeOrder(contractName: String, forgeType: Type) : MetadataViews.NFTCollectionDisplay {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}

			return FindForge.fulfillForgeOrder(contractName, forgeType: forgeType)
		}

		/// Set the wallet used for the network
		/// @param _ The FT receiver to send the money to
		pub fun setWallet(_ wallet: Capability<&{FungibleToken.Receiver}>) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}

			let walletRef = self.capability!.borrow() ?? panic("Cannot borrow reference to receiver. receiver address: ".concat(self.capability!.address.toString()))
			walletRef.setWallet(wallet)
		}

		/// Enable or disable public registration
		pub fun setPublicEnabled(_ enabled: Bool) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}

			let walletRef = self.capability!.borrow() ?? panic("Cannot borrow reference to receiver. receiver address: ".concat(self.capability!.address.toString()))
			walletRef.setPublicEnabled(enabled)
		}

		pub fun setAddonPrice(name: String, price: UFix64) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}

			let walletRef = self.capability!.borrow() ?? panic("Cannot borrow reference to receiver. receiver address: ".concat(self.capability!.address.toString()))
			walletRef.setAddonPrice(name: name, price: price)
		}

		pub fun setPrice(default: UFix64, additional : {Int: UFix64}) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}

			let walletRef = self.capability!.borrow() ?? panic("Cannot borrow reference to receiver. receiver address: ".concat(self.capability!.address.toString()))
			walletRef.setPrice(default: default, additionalPrices: additional)
		}

		pub fun register(name: String, profile: Capability<&{Profile.Public}>, leases: Capability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>){
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
				FIND.validateFindName(name) : "A FIND name has to be lower-cased alphanumeric or dashes and between 3 and 16 characters"
			}

			let walletRef = self.capability!.borrow() ?? panic("Cannot borrow reference to receiver. receiver address: ".concat(self.capability!.address.toString()))
			walletRef.internal_register(name:name, profile: profile, leases: leases)
		}

		pub fun addAddon(name:String, addon:String){
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
				FIND.validateFindName(name) : "A FIND name has to be lower-cased alphanumeric or dashes and between 3 and 16 characters"
			}

			let user = FIND.lookupAddress(name) ?? panic("Cannot find lease owner. Lease : ".concat(name))
			let ref = getAccount(user).getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath).borrow() ?? panic("Cannot borrow reference to lease collection of user : ".concat(name))
			ref.adminAddAddon(name:name, addon:addon)
		}

		pub fun adminSetMinterPlatform(name: String, forgeType: Type, minterCut: UFix64?, description: String, externalURL: String, squareImage: String, bannerImage: String, socials: {String : String}) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
				FIND.validateFindName(name) : "A FIND name has to be lower-cased alphanumeric or dashes and between 3 and 16 characters"
			}

			FindForge.adminSetMinterPlatform(leaseName: name, forgeType: forgeType, minterCut: minterCut, description: description, externalURL: externalURL, squareImage: squareImage, bannerImage: bannerImage, socials: socials)
		}

		pub fun mintForge(name: String, forgeType: Type , data: AnyStruct, receiver: &{NonFungibleToken.Receiver, MetadataViews.ResolverCollection}) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}

			FindForge.mintAdmin(leaseName: name, forgeType: forgeType, data: data, receiver: receiver)
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

		/*
		pub fun setViewConverters(from: Type, converters: [{Dandy.ViewConverter}]) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}

			Dandy.setViewConverters(from: from, converters: converters)
		}
		*/

		/// ===================================================================================
		// Fungible Token Registry
		/// ===================================================================================

		// Registry FungibleToken Information
		pub fun setFTInfo(alias: String, type: Type, tag: [String], icon: String?, receiverPath: PublicPath, balancePath: PublicPath, vaultPath: StoragePath) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}
			FTRegistry.setFTInfo(alias: alias, type: type, tag: tag, icon: icon, receiverPath: receiverPath, balancePath: balancePath, vaultPath:vaultPath)

		}

		// Remove FungibleToken Information by type identifier
		pub fun removeFTInfoByTypeIdentifier(_ typeIdentifier: String) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}
			FTRegistry.removeFTInfoByTypeIdentifier(typeIdentifier)
		}


		// Remove FungibleToken Information by alias
		pub fun removeFTInfoByAlias(_ alias: String) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}
			FTRegistry.removeFTInfoByAlias(alias)
		}

		/// ===================================================================================
		// Find Pack
		/// ===================================================================================

		pub fun getAuthPointer(pathIdentifier: String, id: UInt64) : FindViews.AuthNFTPointer {
			pre {
				self.capability != nil: "Cannot create Admin, capability is not set"
			}

			let privatePath = PrivatePath(identifier: pathIdentifier)!
			var cap = Admin.account.getCapability<&{MetadataViews.ResolverCollection, NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(privatePath)
			if !cap.check() {
				let storagePath = StoragePath(identifier: pathIdentifier)!
				Admin.account.link<&{MetadataViews.ResolverCollection, NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(privatePath , target: storagePath)
				cap = Admin.account.getCapability<&{MetadataViews.ResolverCollection, NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(privatePath)
			}
			return FindViews.AuthNFTPointer(cap: cap, id: id)
		}

		pub fun getProviderCap(_ path: PrivatePath): Capability<&{NonFungibleToken.Provider, MetadataViews.ResolverCollection}> {
			pre {
				self.capability != nil: "Cannot create Admin, capability is not set"
			}
			return Admin.account.getCapability<&{NonFungibleToken.Provider, MetadataViews.ResolverCollection}>(path)
		}

		pub fun mintFindPack(packTypeName: String, typeId:UInt64,hash: String) {
			pre {
				self.capability != nil: "Cannot create Admin, capability is not set"
			}
			let pathIdentifier = FindPack.getPacksCollectionPath(packTypeName: packTypeName, packTypeId: typeId)
			let path = PublicPath(identifier: pathIdentifier)!
			let receiver = Admin.account.getCapability<&{NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(path).borrow() ?? panic("Cannot borrow reference to admin find pack collection public from Path : ".concat(pathIdentifier))
			let mintPackData = FindPack.MintPackData(packTypeName: packTypeName, typeId: typeId, hash: hash, verifierRef: FindForge.borrowVerifier())
			FindForge.adminMint(lease: packTypeName, forgeType: Type<@FindPack.Forge>() , data: mintPackData, receiver: receiver)
		}

		pub fun fulfillFindPack(packId:UInt64, types:[Type], rewardIds: [UInt64], salt:String) {
			pre {
				self.capability != nil: "Cannot create Admin, capability is not set"
			}
			FindPack.fulfill(packId:packId, types:types, rewardIds:rewardIds, salt:salt)
		}

		pub fun requeueFindPack(packId:UInt64) {
			pre {
				self.capability != nil: "Cannot create Admin, capability is not set"
			}

			let cap= Admin.account.borrow<&FindPack.Collection>(from: FindPack.DLQCollectionStoragePath)!
			cap.requeue(packId: packId)
		}

		pub fun getFindRoyaltyCap() : Capability<&{FungibleToken.Receiver}> {
			pre {
				self.capability != nil: "Cannot create Admin, capability is not set"
			}

			return Admin.account.getCapability<&{FungibleToken.Receiver}>(Profile.publicReceiverPath)
		}

		/// ===================================================================================
		// FINDNFTCatalog
		/// ===================================================================================

		pub fun addCatalogEntry(collectionIdentifier : String, metadata : NFTCatalog.NFTCatalogMetadata) {
			pre {
				self.capability != nil: "Cannot create Admin, capability is not set"
			}

			let FINDCatalogAdmin = Admin.account.borrow<&FINDNFTCatalogAdmin.Admin>(from: FINDNFTCatalogAdmin.AdminStoragePath) ?? panic("Cannot borrow reference to Find NFT Catalog admin resource")
        	FINDCatalogAdmin.addCatalogEntry(collectionIdentifier : collectionIdentifier, metadata : metadata)
		}

		pub fun removeCatalogEntry(collectionIdentifier : String) {
			pre {
				self.capability != nil: "Cannot create Admin, capability is not set"
			}

			let FINDCatalogAdmin = Admin.account.borrow<&FINDNFTCatalogAdmin.Admin>(from: FINDNFTCatalogAdmin.AdminStoragePath) ?? panic("Cannot borrow reference to Find NFT Catalog admin resource")
        	FINDCatalogAdmin.removeCatalogEntry(collectionIdentifier : collectionIdentifier)
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


import FungibleToken from "./standard/FungibleToken.cdc"
import FlowToken from "./standard/FlowToken.cdc"
import NonFungibleToken from "./standard/NonFungibleToken.cdc"
import MetadataViews from "./standard/MetadataViews.cdc"
import Profile from "./Profile.cdc"
import FIND from "./FIND.cdc"
import Debug from "./Debug.cdc"
import Clock from "./Clock.cdc"
import FTRegistry from "./FTRegistry.cdc"
import FindForge from "./FindForge.cdc"
import FindForgeOrder from "./FindForgeOrder.cdc"
import FindPack from "./FindPack.cdc"
import NFTCatalog from "./standard/NFTCatalog.cdc"
import FINDNFTCatalogAdmin from "./FINDNFTCatalogAdmin.cdc"
import FindViews from "./FindViews.cdc"
import NameVoucher from "./NameVoucher.cdc"
import ViewResolver from "./standard/ViewResolver.cdc"

access(all) contract Admin {

    //store the proxy for the admin
    access(all) let AdminProxyPublicPath: PublicPath
    access(all) let AdminProxyStoragePath: StoragePath

    /// ===================================================================================
    // Admin things
    /// ===================================================================================

    //Admin client to use for capability receiver pattern
    access(all) fun createAdminProxyClient() : @AdminProxy {
        return <- create AdminProxy()
    }

    //interface to use for capability receiver pattern
    access(all) resource interface AdminProxyClient {
        //TODO: all methods but this in here needs to be behind and entitlement
        //the rule is, any method that is publicly linked that was previously _not_ in the linked interface needs an entitlement
        access(all) fun addCapability(_ cap: Capability<&FIND.Network>)
    }

    //admin proxy with capability receiver
    access(all) resource AdminProxy: AdminProxyClient {

        access(self) var capability: Capability<&FIND.Network>?

        access(all) fun addCapability(_ cap: Capability<&FIND.Network>) {
            pre {
                cap.check() : "Invalid server capablity"
                self.capability == nil : "Server already set"
            }
            self.capability = cap
        }

        access(all) fun addPublicForgeType(name: String, forgeType : Type) {
            pre {
                self.capability != nil: "Cannot create FIND, capability is not set"
            }

            FindForge.addPublicForgeType(forgeType: forgeType)
        }

        access(all) fun addPrivateForgeType(name: String, forgeType : Type) {
            pre {
                self.capability != nil: "Cannot create FIND, capability is not set"
            }

            FindForge.addPrivateForgeType(name: name, forgeType: forgeType)
        }

        access(all) fun removeForgeType(_ type : Type) {
            pre {
                self.capability != nil: "Cannot create FIND, capability is not set"
            }

            FindForge.removeForgeType(type: type)
        }

        access(all) fun addForgeContractData(lease: String, forgeType: Type , data: AnyStruct) {
            pre {
                self.capability != nil: "Cannot create FIND, capability is not set"
            }

            FindForge.adminAddContractData(lease: lease, forgeType: forgeType , data: data)
        }

        access(all) fun addForgeMintType(_ mintType: String) {
            pre {
                self.capability != nil: "Cannot create FIND, capability is not set"
            }

            FindForgeOrder.addMintType(mintType)
        }

        access(all) fun orderForge(leaseName: String, mintType: String, minterCut: UFix64?, collectionDisplay: MetadataViews.NFTCollectionDisplay) {
            pre {
                self.capability != nil: "Cannot create FIND, capability is not set"
            }

            FindForge.adminOrderForge(leaseName: leaseName, mintType: mintType, minterCut: minterCut, collectionDisplay: collectionDisplay)
        }

        access(all) fun cancelForgeOrder(leaseName: String, mintType: String){
            pre {
                self.capability != nil: "Cannot create FIND, capability is not set"
            }
            FindForge.cancelForgeOrder(leaseName: leaseName, mintType: mintType)
        }

        access(all) fun fulfillForgeOrder(contractName: String, forgeType: Type) : MetadataViews.NFTCollectionDisplay {
            pre {
                self.capability != nil: "Cannot create FIND, capability is not set"
            }

            return FindForge.fulfillForgeOrder(contractName, forgeType: forgeType)
        }

        /// Set the wallet used for the network
        /// @param _ The FT receiver to send the money to
        access(all) fun setWallet(_ wallet: Capability<&{FungibleToken.Receiver}>) {
            pre {
                self.capability != nil: "Cannot create FIND, capability is not set"
            }

            let walletRef = self.capability!.borrow() ?? panic("Cannot borrow reference to receiver. receiver address: ".concat(self.capability!.address.toString()))
            walletRef.setWallet(wallet)
        }

        /// Enable or disable public registration
        access(all) fun setPublicEnabled(_ enabled: Bool) {
            pre {
                self.capability != nil: "Cannot create FIND, capability is not set"
            }

            let walletRef = self.capability!.borrow() ?? panic("Cannot borrow reference to receiver. receiver address: ".concat(self.capability!.address.toString()))
            walletRef.setPublicEnabled(enabled)
        }

        access(all) fun setAddonPrice(name: String, price: UFix64) {
            pre {
                self.capability != nil: "Cannot create FIND, capability is not set"
            }

            let walletRef = self.capability!.borrow() ?? panic("Cannot borrow reference to receiver. receiver address: ".concat(self.capability!.address.toString()))
            walletRef.setAddonPrice(name: name, price: price)
        }

        access(all) fun setPrice(defaultPrice: UFix64, additional : {Int: UFix64}) {
            pre {
                self.capability != nil: "Cannot create FIND, capability is not set"
            }

            let walletRef = self.capability!.borrow() ?? panic("Cannot borrow reference to receiver. receiver address: ".concat(self.capability!.address.toString()))
            walletRef.setPrice(defaultPrice: defaultPrice, additionalPrices: additional)
        }

        access(all) fun register(name: String, profile: Capability<&{Profile.Public}>, leases: Capability<&{FIND.LeaseCollectionPublic}>){
            pre {
                self.capability != nil: "Cannot create FIND, capability is not set"
            }

            if !FIND.validateFindName(name) {
                panic("A FIND name has to be lower-cased alphanumeric or dashes and between 3 and 16 characters")
            } 

            let walletRef = self.capability!.borrow() ?? panic("Cannot borrow reference to receiver. receiver address: ".concat(self.capability!.address.toString()))
            walletRef.internal_register(name:name, profile: profile, leases: leases)
        }

        access(all) fun addAddon(name:String, addon:String){
            pre {
                self.capability != nil: "Cannot create FIND, capability is not set"
            }

            if !FIND.validateFindName(name) {
                panic("A FIND name has to be lower-cased alphanumeric or dashes and between 3 and 16 characters")
            }

            let user = FIND.lookupAddress(name) ?? panic("Cannot find lease owner. Lease : ".concat(name))
            let ref = getAccount(user).capabilities.get<&{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)!.borrow() ?? panic("Cannot borrow reference to lease collection of user : ".concat(name))
            ref.adminAddAddon(name:name, addon:addon)
        }

        access(all) fun adminSetMinterPlatform(name: String, forgeType: Type, minterCut: UFix64?, description: String, externalURL: String, squareImage: String, bannerImage: String, socials: {String : String}) {
            pre {
                self.capability != nil: "Cannot create FIND, capability is not set"
            }

            if !FIND.validateFindName(name) {
                panic("A FIND name has to be lower-cased alphanumeric or dashes and between 3 and 16 characters")
            }

            FindForge.adminSetMinterPlatform(leaseName: name, forgeType: forgeType, minterCut: minterCut, description: description, externalURL: externalURL, squareImage: squareImage, bannerImage: bannerImage, socials: socials)
        }

        access(all) fun mintForge(name: String, forgeType: Type , data: AnyStruct, receiver: &{NonFungibleToken.Receiver, ViewResolver.ResolverCollection}) {
            pre {
                self.capability != nil: "Cannot create FIND, capability is not set"
            }

            FindForge.mintAdmin(leaseName: name, forgeType: forgeType, data: data, receiver: receiver)
        }

        access(all) fun advanceClock(_ time: UFix64) {
            pre {
                self.capability != nil: "Cannot create FIND, capability is not set"
            }
            Debug.enable(true)
            Clock.enable()
            Clock.tick(time)
        }


        access(all) fun debug(_ value: Bool) {
            pre {
                self.capability != nil: "Cannot create FIND, capability is not set"
            }
            Debug.enable(value)
        }

        /*
        access(all) fun setViewConverters(from: Type, converters: [{Dandy.ViewConverter}]) {
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
        access(all) fun setFTInfo(alias: String, type: Type, tag: [String], icon: String?, receiverPath: PublicPath, balancePath: PublicPath, vaultPath: StoragePath) {
            pre {
                self.capability != nil: "Cannot create FIND, capability is not set"
            }
            FTRegistry.setFTInfo(alias: alias, type: type, tag: tag, icon: icon, receiverPath: receiverPath, balancePath: balancePath, vaultPath:vaultPath)

        }

        // Remove FungibleToken Information by type identifier
        access(all) fun removeFTInfoByTypeIdentifier(_ typeIdentifier: String) {
            pre {
                self.capability != nil: "Cannot create FIND, capability is not set"
            }
            FTRegistry.removeFTInfoByTypeIdentifier(typeIdentifier)
        }


        // Remove FungibleToken Information by alias
        access(all) fun removeFTInfoByAlias(_ alias: String) {
            pre {
                self.capability != nil: "Cannot create FIND, capability is not set"
            }
            FTRegistry.removeFTInfoByAlias(alias)
        }

        /// ===================================================================================
        // Find Pack
        /// ===================================================================================

        access(all) fun getAuthPointer(pathIdentifier: String, id: UInt64) : FindViews.AuthNFTPointer {
            pre {
                self.capability != nil: "Cannot create Admin, capability is not set"
            }

            let storagePath = StoragePath(identifier: pathIdentifier)!
            var cap = Admin.account.capabilities.storage.issue<auth(NonFungibleToken.Withdrawable) &{ViewResolver.ResolverCollection, NonFungibleToken.Provider, NonFungibleToken.Collection}>(storagePath)
            return FindViews.AuthNFTPointer(cap: cap, id: id)
        }

        access(all) fun getProviderCap(_ path: StoragePath): Capability<&{NonFungibleToken.Provider, ViewResolver.ResolverCollection}> {
            pre {
                self.capability != nil: "Cannot create Admin, capability is not set"
            }
            return Admin.account.capabilities.storage.issue<&{ViewResolver.ResolverCollection, NonFungibleToken.Provider}>(path)!
        }

        access(all) fun mintFindPack(packTypeName: String, typeId:UInt64,hash: String) {
            pre {
                self.capability != nil: "Cannot create Admin, capability is not set"
            }
            let pathIdentifier = FindPack.getPacksCollectionPath(packTypeName: packTypeName, packTypeId: typeId)
            let path = PublicPath(identifier: pathIdentifier)!
            let receiver = Admin.account.capabilities.borrow<&{NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(path) ?? panic("Cannot borrow reference to receiver. receiver address: ".concat(path.toString()))
            let mintPackData = FindPack.MintPackData(packTypeName: packTypeName, typeId: typeId, hash: hash, verifierRef: FindForge.borrowVerifier())
            FindForge.adminMint(lease: packTypeName, forgeType: Type<@FindPack.Forge>() , data: mintPackData, receiver: receiver)
        }

        access(all) fun fulfillFindPack(packId:UInt64, types:[Type], rewardIds: [UInt64], salt:String) {
            pre {
                self.capability != nil: "Cannot create Admin, capability is not set"
            }
            FindPack.fulfill(packId:packId, types:types, rewardIds:rewardIds, salt:salt)
        }

        access(all) fun requeueFindPack(packId:UInt64) {
            pre {
                self.capability != nil: "Cannot create Admin, capability is not set"
            }

            let cap= Admin.account.storage.borrow<&FindPack.Collection>(from: FindPack.DLQCollectionStoragePath)!
            cap.requeue(packId: packId)
        }

        access(all) fun getFindRoyaltyCap() : Capability<&{FungibleToken.Receiver}> {
            pre {
                self.capability != nil: "Cannot create Admin, capability is not set"
            }

            return Admin.account.capabilities.get<&{FungibleToken.Receiver}>(Profile.publicReceiverPath)!
        }

        /// ===================================================================================
        // FINDNFTCatalog
        /// ===================================================================================

        access(all) fun addCatalogEntry(collectionIdentifier : String, metadata : NFTCatalog.NFTCatalogMetadata) {
            pre {
                self.capability != nil: "Cannot create Admin, capability is not set"
            }

            let FINDCatalogAdmin = Admin.account.storage.borrow<&FINDNFTCatalogAdmin.Admin>(from: FINDNFTCatalogAdmin.AdminStoragePath) ?? panic("Cannot borrow reference to Find NFT Catalog admin resource")
            FINDCatalogAdmin.addCatalogEntry(collectionIdentifier : collectionIdentifier, metadata : metadata)
        }

        access(all) fun removeCatalogEntry(collectionIdentifier : String) {
            pre {
                self.capability != nil: "Cannot create Admin, capability is not set"
            }

            let FINDCatalogAdmin = Admin.account.storage.borrow<&FINDNFTCatalogAdmin.Admin>(from: FINDNFTCatalogAdmin.AdminStoragePath) ?? panic("Cannot borrow reference to Find NFT Catalog admin resource")
            FINDCatalogAdmin.removeCatalogEntry(collectionIdentifier : collectionIdentifier)
        }

        access(all) fun getSwitchboardReceiverPublic() : Capability<&{FungibleToken.Receiver}> {
            // we hard code it here instead, to avoid importing just for path
            return Admin.account.capabilities.get<&{FungibleToken.Receiver}>(/public/GenericFTReceiver)!
        }

        /// ===================================================================================
        // Name Voucher
        /// ===================================================================================

        access(all) fun mintNameVoucher(receiver : &{NonFungibleToken.Receiver}, minCharLength : UInt64) : UInt64  {
            pre {
                self.capability != nil: "Cannot create Admin, capability is not set"
            }

            return NameVoucher.mintNFT(recipient: receiver, minCharLength: minCharLength)
        }

        access(all) fun mintNameVoucherToFind(minCharLength : UInt64) : UInt64 {
            pre {
                self.capability != nil: "Cannot create Admin, capability is not set"
            }

            let receiver = Admin.account.storage.borrow<&NameVoucher.Collection>(from: NameVoucher.CollectionStoragePath)!
            return NameVoucher.mintNFT(recipient: receiver, minCharLength: minCharLength)
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


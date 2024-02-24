import "NonFungibleToken"
import "FungibleToken"
import "MetadataViews"
import "ViewResolver"

access(all) contract FindViews {

    access(all) struct OnChainFile : MetadataViews.File{
        access(all) let content: String
        access(all) let mediaType: String
        access(all) let protocol: String

        init(content:String, mediaType: String) {
            self.content=content
            self.protocol="onChain"
            self.mediaType=mediaType
        }

        access(all) view fun uri(): String {
            return "data:".concat(self.mediaType).concat(",").concat(self.content)
        }
    }

    access(all) struct SharedMedia : MetadataViews.File {
        access(all) let mediaType: String
        access(all) let pointer: ViewReadPointer
        access(all) let protocol: String

        init(pointer: ViewReadPointer, mediaType: String) {
            self.pointer=pointer
            self.mediaType=mediaType
            self.protocol="shared"

            if pointer.resolveView(Type<OnChainFile>()) == nil {
                panic("Cannot create shared media if the pointer does not contain StringMedia")
            }
        }

        // todo: this is not working so we have a workaround in the contract
        access(all) view fun uri(): String {
            return "data:".concat(self.mediaType).concat(",").concat(self.protocol)
        }
    }

    access(all) resource interface VaultViews {
        access(all) var balance: UFix64
        access(all) view fun getViews() : [Type]
        access(all) fun resolveView(_ view: Type): AnyStruct?
    }

    access(all) struct FTVaultData {
        access(all) let tokenAlias: String
        access(all) let storagePath: StoragePath
        access(all) let receiverPath: PublicPath
        access(all) let balancePath: PublicPath
        access(all) let providerPath: PrivatePath
        access(all) let vaultType: Type
        access(all) let receiverType: Type
        access(all) let balanceType: Type
        access(all) let providerType: Type
        access(all) let createEmptyVault: (fun(): @{FungibleToken.Vault})

        init(
            tokenAlias: String,
            storagePath: StoragePath,
            receiverPath: PublicPath,
            balancePath: PublicPath,
            providerPath: PrivatePath,
            vaultType: Type,
            receiverType: Type,
            balanceType: Type,
            providerType: Type,
            createEmptyVault: (fun(): @{FungibleToken.Vault})
        ) {
            pre {
                receiverType.isSubtype(of: Type<&{FungibleToken.Receiver}>()): "Receiver type must include FungibleToken.Receiver interfaces."
                balanceType.isSubtype(of: Type<&{FungibleToken.Vault}>()): "Balance type must include FungibleToken.Vault interfaces."
                providerType.isSubtype(of: Type<&{FungibleToken.Provider}>()): "Provider type must include FungibleToken.Provider interface."
            }
            self.tokenAlias=tokenAlias
            self.storagePath=storagePath
            self.receiverPath=receiverPath
            self.balancePath=balancePath
            self.providerPath = providerPath
            self.vaultType=vaultType
            self.receiverType=receiverType
            self.balanceType=balanceType
            self.providerType = providerType
            self.createEmptyVault=createEmptyVault
        }
    }

    // This is an example taken from Versus
    access(all) struct CreativeWork {
        access(all) let artist: String
        access(all) let name: String
        access(all) let description: String
        access(all) let type: String

        init(artist: String, name: String, description: String, type: String) {
            self.artist=artist
            self.name=name
            self.description=description
            self.type=type
        }
    }

    /// A basic pointer that can resolve data and get owner/id/uuid and gype
    access(all) struct interface Pointer {
        access(all) let id: UInt64
        access(all) fun resolveView(_ type: Type) : AnyStruct?
        access(all) fun getUUID() :UInt64
        access(all) fun getViews() : [Type]
        access(all) fun owner() : Address
        access(all) fun valid() : Bool
        access(all) fun getItemType() : Type
        access(all) fun getViewResolver() : &{ViewResolver.Resolver}

        //There are just convenience functions for shared views in the standard
        access(all) fun getRoyalty() : MetadataViews.Royalties
        access(all) fun getTotalRoyaltiesCut() : UFix64

        //Requred views
        access(all) fun getDisplay() : MetadataViews.Display
        access(all) fun getNFTCollectionData() : MetadataViews.NFTCollectionData

        access(all) fun checkSoulBound() : Bool

    }

    //An interface to say that this pointer can withdraw
    access(all) struct interface AuthPointer {
        access(all) fun withdraw() : @AnyResource
    }

    access(all) struct ViewReadPointer : Pointer {
        access(self) let cap: Capability<&{NonFungibleToken.Collection}>
        access(all) let id: UInt64
        access(all) let uuid: UInt64
        access(all) let itemType: Type

        init(cap: Capability<&{NonFungibleToken.Collection}>, id: UInt64) {
            self.cap=cap
            self.id=id

            if !self.cap.check() {
                panic("The capability is not valid.")
            }
            let viewResolver=self.cap.borrow()!.borrowNFT(self.id)!
            let display = MetadataViews.getDisplay(viewResolver) ?? panic("MetadataViews Display View is not implemented on this NFT.")
            let nftCollectionData = MetadataViews.getNFTCollectionData(viewResolver) ?? panic("MetadataViews NFTCollectionData View is not implemented on this NFT.")
            self.uuid=viewResolver.uuid
            self.itemType=viewResolver.getType()
        }

        access(all) fun resolveView(_ type: Type) : AnyStruct? {
            return self.getViewResolver().resolveView(type)
        }

        access(all) fun getUUID() :UInt64{
            return self.uuid
        }

        access(all) fun getViews() : [Type]{
            return self.getViewResolver().getViews()
        }

        access(all) fun owner() : Address {
            return self.cap.address
        }

        access(all) fun getTotalRoyaltiesCut() :UFix64 {
            var total=0.0
            for royalty in self.getRoyalty().getRoyalties() {
                total = total + royalty.cut
            }
            return total
        }

        access(all) fun getRoyalty() : MetadataViews.Royalties {
            if let v = MetadataViews.getRoyalties(self.getViewResolver()) {
                return v
            }
            return MetadataViews.Royalties([])
        }

        access(all) fun valid() : Bool {
            if !self.cap.check() || self.cap.borrow()!.borrowNFT(self.id) == nil {
                return false
            }
            return true
        }

        access(all) fun getItemType() : Type {
            return self.itemType
        }

        access(all) fun getViewResolver() : &{ViewResolver.Resolver} {
            let nft=self.cap.borrow()!.borrowNFT(self.id) ?? panic("The capability of view pointer is not linked.")
            return nft

        }

        access(all) fun getDisplay() : MetadataViews.Display {
            if let v = MetadataViews.getDisplay(self.getViewResolver()) {
                return v
            }
            panic("MetadataViews Display View is not implemented on this NFT.")
        }

        access(all) fun getNFTCollectionData() : MetadataViews.NFTCollectionData {
            if let v = MetadataViews.getNFTCollectionData(self.getViewResolver()) {
                return v
            }
            panic("MetadataViews NFTCollectionData View is not implemented on this NFT.")
        }

        access(all) fun checkSoulBound() : Bool {
            return FindViews.checkSoulBound(self.getViewResolver())
        }
    }


    access(all) fun getNounce(_ viewResolver: &{ViewResolver.Resolver}) : UInt64 {
        if let nounce = viewResolver.resolveView(Type<FindViews.Nounce>()) {
            if let v = nounce as? FindViews.Nounce {
                return v.nounce
            }
        }
        return 0
    }

    access(all) struct AuthNFTPointer : Pointer, AuthPointer{
        access(self) let cap: Capability<auth(NonFungibleToken.Withdraw) &{NonFungibleToken.Collection}>
        access(all) let id: UInt64
        access(all) let nounce: UInt64
        access(all) let uuid: UInt64
        access(all) let itemType: Type

        init(cap: Capability<auth(NonFungibleToken.Withdraw) &{NonFungibleToken.Collection}>, id: UInt64) {
            self.cap=cap
            self.id=id

            if !self.cap.check() {
                panic("The capability is not valid.")
            }

            let viewResolver=self.cap.borrow()!.borrowNFT(self.id)!
            let display = MetadataViews.getDisplay(viewResolver) ?? panic("MetadataViews Display View is not implemented on this NFT.")
            let nftCollectionData = MetadataViews.getNFTCollectionData(viewResolver) ?? panic("MetadataViews NFTCollectionData View is not implemented on this NFT.")
            self.nounce=FindViews.getNounce(viewResolver)
            self.uuid=viewResolver.uuid
            self.itemType=viewResolver.getType()
        }

        access(all) fun getViewResolver() : &{ViewResolver.Resolver} {
            let cap = self.cap.borrow()!
            let viewResolver = cap.borrowNFT(self.id) ?? panic("The capability of view pointer is not linked.")
            return viewResolver 
        }

        access(all) fun resolveView(_ type: Type) : AnyStruct? {
            return self.getViewResolver().resolveView(type)
        }

        access(all) fun getUUID() :UInt64{
            return self.uuid
        }

        access(all) fun getViews() : [Type]{
            return self.getViewResolver().getViews()
        }

        access(all) fun valid() : Bool {
            if !self.cap.check() {
                return false
            }

            let nft= self.cap.borrow()!.borrowNFT(self.id)

            if nft ==nil {
                return false
            }

            if let nounce = nft!.resolveView(Type<FindViews.Nounce>()) {
                if let v = nounce as? FindViews.Nounce {
                    return v.nounce==self.nounce
                }
            }
            return true
        }

        access(all) fun getTotalRoyaltiesCut() :UFix64 {
            var total=0.0
            for royalty in self.getRoyalty().getRoyalties() {
                total = total + royalty.cut
            }
            return total
        }

        access(all) fun getRoyalty() : MetadataViews.Royalties {
            if let v = MetadataViews.getRoyalties(self.getViewResolver()) {
                return v
            }
            return MetadataViews.Royalties([])
        }

        access(all) fun getDisplay() : MetadataViews.Display {
            if let v = MetadataViews.getDisplay(self.getViewResolver()) {
                return v
            }
            panic("MetadataViews Display View is not implemented on this NFT.")
        }

        access(all) fun getNFTCollectionData() : MetadataViews.NFTCollectionData {
            if let v = MetadataViews.getNFTCollectionData(self.getViewResolver()) {
                return v
            }
            panic("MetadataViews NFTCollectionData View is not implemented on this NFT.")
        }

        access(all) fun withdraw() :@{NonFungibleToken.NFT} {
            if !self.cap.check() {
                panic("The pointer capability is invalid.")
            }
            return <- self.cap.borrow()!.withdraw(withdrawID: self.id)
        }

        access(all) fun deposit(_ nft: @{NonFungibleToken.NFT}){
            if !self.cap.check(){
                panic("The pointer capablity is invalid.")
            }
            self.cap.borrow()!.deposit(token: <- nft)
        }

        access(all) fun owner() : Address {
            return self.cap.address
        }

        access(all) fun getItemType() : Type {
            return self.itemType
        }

        access(all) fun checkSoulBound() : Bool {
            return FindViews.checkSoulBound(self.getViewResolver())
        }
    }

    access(all) fun createViewReadPointer(address:Address, path:PublicPath, id:UInt64) : ViewReadPointer {
        let cap=	getAccount(address).capabilities.get<&{NonFungibleToken.Collection}>(path)!
        let pointer= FindViews.ViewReadPointer(cap: cap, id: id)
        return pointer
    }

    access(all) struct Nounce {
        access(all) let nounce: UInt64

        init(_ nounce: UInt64) {
            self.nounce=nounce
        }
    }

    access(all) struct SoulBound {

        access(all) let message: String

        init(_ message:String) {
            self.message=message

        }
    }

    access(all) fun checkSoulBound(_ viewResolver: &{ViewResolver.Resolver}) : Bool {
        if let soulBound = viewResolver.resolveView(Type<FindViews.SoulBound>()) {
            if let v = soulBound as? FindViews.SoulBound {
                return true
            }
        }
        return false
    }

    access(all) fun getDapperAddress(): Address {
        switch FindViews.account.address.toString() {
        case "0x097bafa4e0b48eef":
            //mainnet
            return 0xead892083b3e2c6c
        case  "0x35717efbbce11c74":
            //testnet
            return 0x82ec283f88a62e65
        default:
            //emulator
            return 0x01cf0e2f2f715450
        }
    }
}

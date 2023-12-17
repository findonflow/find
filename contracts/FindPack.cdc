import NonFungibleToken from "./standard/NonFungibleToken.cdc"
import FungibleToken from "./standard/FungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import Crypto
import Clock from "../contracts/Clock.cdc"
import Debug from "./Debug.cdc"
import FindForge from "../contracts/FindForge.cdc"
import FindVerifier from "../contracts/FindVerifier.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
import ViewResolver from "../contracts/standard/ViewResolver.cdc"

access(all) contract FindPack {
    // Events
    access(all) event ContractInitialized()
    access(all) event Withdraw(id: UInt64, from: Address?)
    access(all) event Deposit(id: UInt64, to: Address?)
    access(all) event Minted(id: UInt64, typeId:UInt64)

    access(all) event Requeued(packId: UInt64, address:Address)

    access(all) event Opened(packTypeName: String, packTypeId:UInt64, packId: UInt64, address:Address, packFields: {String : String}, packNFTTypes: [String])
    access(all) event Fulfilled(packTypeName: String, packTypeId:UInt64, packId:UInt64, address:Address, packFields: {String : String}, packNFTTypes: [String])
    access(all) event PackReveal(packTypeName: String, packTypeId:UInt64, packId:UInt64, address:Address, rewardId:UInt64, rewardType:String, rewardFields:{String:String}, packFields: {String : String}, packNFTTypes: [String])

    access(all) event Purchased(packTypeName: String, packTypeId: UInt64, packId: UInt64, address: Address, amount:UFix64, packFields: {String : String}, packNFTTypes: [String])
    access(all) event MetadataRegistered(packTypeName: String, packTypeId: UInt64)
    access(all) event FulfilledError(packTypeName: String, packTypeId: UInt64, packId:UInt64, address:Address?, reason:String)

    access(all) let PackMetadataStoragePath: StoragePath

    access(all) let CollectionStoragePath: StoragePath
    access(all) let CollectionPublicPath: PublicPath
    access(all) let CollectionPrivatePath: PrivatePath

    access(all) let OpenedCollectionPublicPath: PublicPath
    access(all) let OpenedCollectionStoragePath: StoragePath


    access(all) let DLQCollectionPublicPath: PublicPath
    access(all) let DLQCollectionStoragePath: StoragePath

    access(all) var totalSupply: UInt64

    // Mapping of packTypeName (which is the find name) : {typeId : Metadata}
    access(contract) let packMetadata: {String : {UInt64: Metadata}}

    // this is a struct specific for airdropping packs
    access(all) struct AirdropInfo {
        access(all) let packTypeName: String
        access(all) let packTypeId: UInt64
        access(all) let users: [String]
        access(all) let message: String

        init(packTypeName: String , packTypeId: UInt64 , users: [String],  message: String){
            self.packTypeName = packTypeName
            self.packTypeId = packTypeId
            self.users = users
            self.message = message
        }
    }

    // this is a struct specific for registering pack metadata
    access(all) struct PackRegisterInfo {
        access(all) let forge: String
        access(all) let name: String
        access(all) let description: String
        access(all) let typeId: UInt64
        access(all) let externalURL: String
        access(all) let squareImageHash: String
        access(all) let bannerHash: String
        access(all) let socials: {String : String}
        access(all) let paymentAddress: Address
        access(all) let paymentType: String
        access(all) let openTime: UFix64
        access(all) let packFields: {String : String}
        access(all) let primaryRoyalty: [Royalty]
        access(all) let secondaryRoyalty: [Royalty]
        access(all) let requiresReservation: Bool
        access(all) let nftTypes: [String]
        access(all) let storageRequirement: UInt64
        access(all) let saleInfo: [PackRegisterSaleInfo]
        access(all) let extra: {String: AnyStruct}

        init(
            forge: String,
            name: String,
            description: String,
            typeId: UInt64,
            externalURL: String,
            squareImageHash: String,
            bannerHash: String,
            socials: {String : String},
            paymentAddress: Address,
            paymentType: String,
            openTime: UFix64,
            packFields: {String : String},
            primaryRoyalty: [Royalty],
            secondaryRoyalty: [Royalty],
            requiresReservation: Bool,
            nftTypes: [String],
            storageRequirement: UInt64,
            saleInfo: [PackRegisterSaleInfo]
        ) {
            self.forge=forge
            self.name=name
            self.description=description
            self.typeId=typeId
            self.externalURL=externalURL
            self.squareImageHash=squareImageHash
            self.bannerHash=bannerHash
            self.socials=socials
            self.paymentAddress=paymentAddress
            self.paymentType=paymentType
            self.openTime=openTime
            self.packFields=packFields
            self.primaryRoyalty=primaryRoyalty
            self.secondaryRoyalty=secondaryRoyalty
            self.requiresReservation=requiresReservation
            self.nftTypes=nftTypes
            self.storageRequirement=storageRequirement
            self.saleInfo=saleInfo
            self.extra={}
        }

        access(all) fun generateSaleInfo() : [SaleInfo] {
            let saleInfo : [SaleInfo] = []
            for s in self.saleInfo {
                saleInfo.append(s.generateSaleInfo())
            }
            return saleInfo
        }
    }

    access(all) struct Royalty {
        access(all) let recipient: Address
        access(all) let cut: UFix64
        access(all) let description: String
        access(contract) let extra: {String: AnyStruct}

        init(
            recipient: Address,
            cut: UFix64,
            description: String
        ) {
            self.recipient=recipient
            self.cut=cut
            self.description=description
            self.extra={}
        }
    }

    access(all) struct PackRegisterSaleInfo {
        access(all) let name : String
        access(all) let startTime : UFix64
        access(all) let price : UFix64
        access(all) let verifiers : [{FindVerifier.Verifier}]
        access(all) let verifyAll : Bool
        access(contract) let extra: {String: AnyStruct}

        init(
            name : String,
            startTime : UFix64,
            price : UFix64,
            verifiers : [{FindVerifier.Verifier}],
            verifyAll : Bool,
            extra: {String: AnyStruct}
        ) {
            self.name=name
            self.startTime=startTime
            self.price=price
            self.verifiers=verifiers
            self.verifyAll=verifyAll
            self.extra=extra
        }

        access(all) fun generateSaleInfo() : SaleInfo {
            var endTime : UFix64? = nil
            if let et = self.extra["endTime"] {
                endTime = et as? UFix64
            }

            var purchaseLimit : UInt64? = nil
            if let pl = self.extra["purchaseLimit"] {
                purchaseLimit = pl as? UInt64
            }

            return SaleInfo(
                name : self.name,
                startTime : self.startTime ,
                endTime : endTime,
                price : self.price,
                purchaseLimit : purchaseLimit,
                verifiers: self.verifiers,
                verifyAll : self.verifyAll
            )
        }
    }

    // Verifier container for packs
    // Each struct is one sale type. If they
    access(all) struct SaleInfo {
        access(all) let name : String
        access(all) let startTime : UFix64
        access(all) let endTime : UFix64?
        access(all) let price : UFix64
        access(all) let purchaseLimit : UInt64?
        access(all) let purchaseRecord : {Address : UInt64}
        access(all) let verifiers : [{FindVerifier.Verifier}]
        access(all) let verifyAll : Bool

        init(name : String, startTime : UFix64 , endTime : UFix64? , price : UFix64, purchaseLimit : UInt64?, verifiers: [{FindVerifier.Verifier}], verifyAll : Bool ) {
            self.name = name
            self.startTime = startTime
            self.endTime = endTime
            self.price = price
            self.purchaseLimit = purchaseLimit
            self.purchaseRecord = {}
            self.verifiers = verifiers
            self.verifyAll = verifyAll
        }

        access(all) fun inTime(_ time: UFix64) : Bool {
            let started = time >= self.startTime
            if self.endTime == nil {
                return started
            }

            return started && time <= self.endTime!
        }

        access(all) fun buy(_ addr: Address) {

            // If verified false, then panic

            if !self.verify(addr) {
                panic("You are not qualified to buy this pack at the moment")
            }

            let purchased = (self.purchaseRecord[addr] ?? 0 ) + 1
            if self.purchaseLimit != nil && self.purchaseLimit! < purchased {
                panic("You are only allowed to purchase ".concat(self.purchaseLimit!.toString()))
            }
            self.purchaseRecord[addr] = purchased
        }

        access(all) fun checkBought(_ addr: Address) : UInt64 {
            return self.purchaseRecord[addr] ?? 0
        }

        access(all) fun checkBuyable(addr: Address, time: UFix64) : Bool {
            // If not in time, return false
            if !self.inTime(time) {
                return false
            }

            // If verified false, then false
            if !self.verify(addr) {
                return false
            }

            // If exceed purchase limit, return false
            let purchased = (self.purchaseRecord[addr] ?? 0 ) + 1
            if self.purchaseLimit != nil && self.purchaseLimit! < purchased {
                return false
            }
            // else return true
            return true
        }

        access(contract) fun verify(_ addr: Address) : Bool {
            if self.verifiers.length == 0 {
                return true
            }

            if self.verifyAll {
                for verifier in self.verifiers {
                    if !verifier.verify(self.generateParam(addr)) {
                        return false
                    }
                }
                return true
            }
            // If only has to verify one
            for verifier in self.verifiers {
                if verifier.verify(self.generateParam(addr)) {
                    return true
                }
            }
            return false
        }

        access(contract) fun generateParam(_ addr: Address) : {String : AnyStruct} {
            return {
                "address" : addr
            }
        }

    }

    // Input for minting packs from forge
    access(all) struct MintPackData {
        access(all) let packTypeName: String
        access(all) let typeId: UInt64
        access(all) let hash: String
        access(all) let verifierRef: &FindForge.Verifier

        init(packTypeName: String, typeId: UInt64, hash: String, verifierRef: &FindForge.Verifier) {
            self.packTypeName = packTypeName
            self.typeId = typeId
            self.hash = hash
            self.verifierRef = verifierRef
        }
    }

    access(all) struct PackRevealData {

        access(all) let data: {String:String}

        init(_ data: {String:String}) {
            self.data=data
        }
    }

    access(all) struct Metadata {
        access(all) let name: String
        access(all) let description: String

        access(all) let thumbnailHash: String?
        access(all) let thumbnailUrl:String?

        access(all) let wallet: Capability<&{FungibleToken.Receiver}>
        access(all) let walletType: Type

        access(all) let openTime: UFix64
        access(all) let saleInfos: [SaleInfo]

        access(all) let storageRequirement: UInt64
        access(all) let collectionDisplay: MetadataViews.NFTCollectionDisplay

        access(all) let packFields: {String : String}
        access(all) let extraData : {String : AnyStruct}

        access(all) let itemTypes: [Type]
        access(contract) let providerCaps: {Type : Capability<&{NonFungibleToken.Provider, ViewResolver.ResolverCollection}>}

        access(contract) let primarySaleRoyalties : MetadataViews.Royalties
        access(contract) let royalties : MetadataViews.Royalties

        access(all) let requiresReservation: Bool

        init(name: String, description: String, thumbnailUrl: String?,thumbnailHash: String?, wallet: Capability<&{FungibleToken.Receiver}>, openTime:UFix64, walletType:Type, itemTypes: [Type],  providerCaps: {Type : Capability<&{NonFungibleToken.Provider, ViewResolver.ResolverCollection}>} , requiresReservation:Bool, storageRequirement: UInt64, saleInfos: [SaleInfo], primarySaleRoyalties : MetadataViews.Royalties, royalties : MetadataViews.Royalties, collectionDisplay: MetadataViews.NFTCollectionDisplay, packFields: {String : String} , extraData : {String : AnyStruct}) {
            self.name = name
            self.description = description
            self.thumbnailUrl = thumbnailUrl
            self.thumbnailHash = thumbnailHash
            self.wallet=wallet
            self.walletType=walletType

            self.openTime=openTime
            self.itemTypes=itemTypes
            self.providerCaps=providerCaps

            self.primarySaleRoyalties=primarySaleRoyalties
            self.royalties=royalties

            self.storageRequirement= storageRequirement
            self.collectionDisplay= collectionDisplay

            self.requiresReservation=requiresReservation
            self.packFields=packFields

            self.saleInfos=saleInfos
            self.extraData=extraData
        }

        access(all) fun getThumbnail() : {MetadataViews.File} {
            if let hash = self.thumbnailHash {
                return MetadataViews.IPFSFile(cid: hash, path: nil)
            }
            return MetadataViews.HTTPFile(url:self.thumbnailUrl!)
        }

        access(all) fun getItemTypesAsStringArray() : [String] {
            let types : [String] = []
            for t in self.itemTypes {
                types.append(t.identifier)
            }
            return types
        }

        access(all) fun canBeOpened() : Bool {
            return self.openTime <= Clock.time()
        }

        access(contract) fun borrowSaleInfo(_ i: Int) : &SaleInfo {
            return &self.saleInfos[i] as &FindPack.SaleInfo
        }
    }

    access(account) fun registerMetadata(packTypeName: String, typeId: UInt64, metadata: Metadata) {
        emit MetadataRegistered(packTypeName: packTypeName, packTypeId: typeId)
        let mappingMetadata = self.packMetadata[packTypeName] ?? {} //<- if this is empty then setup the storage slot for this pack type

        // first time we create this type ID, if its not there then we create it.
        if mappingMetadata[typeId] == nil {
            let pathIdentifier = self.getPacksCollectionPath(packTypeName: packTypeName, packTypeId: typeId)
            let storagePath = StoragePath(identifier: pathIdentifier) ?? panic("Cannot create path from identifier : ".concat(pathIdentifier))
            let publicPath = PublicPath(identifier: pathIdentifier) ?? panic("Cannot create path from identifier : ".concat(pathIdentifier))
            FindPack.account.storage.save<@{NonFungibleToken.Collection}>( <- FindPack.createEmptyCollection(), to: storagePath)
            let cap = FindPack.account.capabilities.storage.issue<&FindPack.Collection>(storagePath)
            FindPack.account.capabilities.publish(cap, at: publicPath)
        }

        mappingMetadata[typeId] = metadata
        self.packMetadata[packTypeName] = mappingMetadata
    }

    access(all) fun getMetadataById(packTypeName: String, typeId: UInt64): Metadata? {

        if self.packMetadata[packTypeName] != nil {
            return self.packMetadata[packTypeName]![typeId]
        }

        return nil
    }

    access(all) fun getMetadataByName(packTypeName: String): {UInt64 : Metadata} {

        if self.packMetadata[packTypeName] != nil {
            return self.packMetadata[packTypeName]!
        }

        return {}
    }

    access(all) resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver {
        // The token's ID
        access(all) let id: UInt64
        access(all) let packTypeName: String

        // The token's typeId
        access(self) var typeId: UInt64

        //this is added to the NFT when it is opened
        access(self) var openedBy: {Type : Capability<&{NonFungibleToken.Receiver}>}

        access(account) let hash: String

        access(self) let royalties : [MetadataViews.Royalty]

        // init
        //
        init(packTypeName: String, typeId: UInt64, hash:String, royalties: [MetadataViews.Royalty]) {
            self.id = self.uuid
            self.typeId = typeId
            self.openedBy={}
            self.hash=hash
            self.royalties=royalties
            self.packTypeName=packTypeName
        }

        access(all) fun getOpenedBy() : {Type : Capability<&{NonFungibleToken.Receiver}>} {
            if self.openedBy== nil {
                panic("Pack is not opened")
            }
            return self.openedBy!
        }

        access(all) fun getHash() : String{
            return self.hash
        }

        access(contract) fun setTypeId(_ id: UInt64) {
            self.typeId=id
        }

        access(contract) fun resetOpenedBy() : Address {
            if self.openedBy.length == 0 {
                panic("Pack is not opened")
            }
            let cap = self.openedBy!

            self.openedBy={}
            return cap.values[0].address
        }

        access(contract) fun setOpenedBy(_ cap:{Type : Capability<&{NonFungibleToken.Receiver}>}) {
            if self.openedBy.length != 0 {
                panic("Pack has already been opened")
            }
            self.openedBy=cap
        }

        access(all) fun getTypeID() :UInt64 {
            return self.typeId
        }

        access(all) fun getMetadata(): Metadata {
            return FindPack.getMetadataById(packTypeName: self.packTypeName, typeId: self.typeId)!
        }

        access(all) view fun getViews(): [Type] {
            return [
            Type<MetadataViews.Display>(),
            Type<Metadata>(),
            Type<String>(),
            Type<MetadataViews.ExternalURL>(),
            Type<MetadataViews.Royalties>(),
            Type<MetadataViews.NFTCollectionData>(),
            Type<MetadataViews.NFTCollectionDisplay>()
            ]
        }

        access(all) fun resolveView(_ view: Type): AnyStruct? {
            let metadata = self.getMetadata()
            switch view {
            case Type<MetadataViews.Display>():
                return MetadataViews.Display(
                    name: metadata.name,
                    description: metadata.description,
                    thumbnail: metadata.getThumbnail()
                )
            case Type<String>():
                return metadata.name

            case Type<FindPack.Metadata>():
                return metadata
            case Type<MetadataViews.ExternalURL>():
                if self.owner != nil {
                    return MetadataViews.ExternalURL("https://find.xyz/".concat(self.owner!.address.toString()).concat("/main/FindPackCollection/").concat(self.id.toString()))
                }
                return MetadataViews.ExternalURL("https://find.xyz/")

            case Type<MetadataViews.Royalties>():
                return MetadataViews.Royalties(self.royalties)

            case Type<MetadataViews.NFTCollectionData>():
                return MetadataViews.NFTCollectionData(
                    storagePath: FindPack.CollectionStoragePath,
                    publicPath: FindPack.CollectionPublicPath,
                    providerPath: FindPack.CollectionPrivatePath,
                    publicCollection: Type<&FindPack.Collection>(),
                    publicLinkedType: Type<&FindPack.Collection>(),
                    providerLinkedType: Type<&FindPack.Collection>(),
                    createEmptyCollectionFunction: fun () : @{NonFungibleToken.Collection} {
                        return <- FindPack.createEmptyCollection()
                    }
                )

            case Type<MetadataViews.NFTCollectionDisplay>():

                return self.getMetadata().collectionDisplay

                /* to be determined
                //let externalURL = MetadataViews.ExternalURL("https://find.xyz/mp/findPack")
                let externalURL = MetadataViews.ExternalURL("https://find.xyz/")
                let squareImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://pbs.twimg.com/profile_images/1467546091780550658/R1uc6dcq_400x400.jpg"), mediaType: "image")
                let bannerImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://pbs.twimg.com/profile_banners/1448245049666510848/1652452073/1500x500"), mediaType: "image")
                return MetadataViews.NFTCollectionDisplay(name: "find Pack",
                description: "Find pack",
                externalURL: externalURL,
                squareImage: squareImage,
                bannerImage: bannerImage,
                socials: {
                    "discord": MetadataViews.ExternalURL("https://discord.gg/ejdVgzWmYN"),
                    "twitter" : MetadataViews.ExternalURL("https://twitter.com/findonflow")
                })
                */
            }
            return nil
        }

    }

    access(all) resource interface CollectionPublic {
        access(all) fun deposit(token: @{NonFungibleToken.NFT})
        access(all) view fun getIDs(): [UInt64]
        access(all) fun contains(_ id: UInt64): Bool
        access(all) fun getPacksLeft() : Int   // returns the no of a type
        access(all) fun borrowNFT(id: UInt64): &{NonFungibleToken.NFT}
        access(all) fun borrowFindPack(id: UInt64): &FindPack.NFT?
        access(all) fun buyWithSignature(packId: UInt64, signature:String, vault: @{FungibleToken.Vault}, collectionCapability: Capability<&Collection>)
        access(all) fun buy(packTypeName: String, typeId: UInt64, vault: @{FungibleToken.Vault}, collectionCapability: Capability<&Collection>)
    }

    // Collection
    // A collection of FindPack NFTs owned by an account
    //
    access(all) resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, CollectionPublic, ViewResolver.ResolverCollection {
        // dictionary of NFT conforming tokens
        // NFT is a resource type with an `UInt64` ID field
        //
        access(all) var ownedNFTs: @{UInt64: {NonFungibleToken.NFT}}

        //this has to be called on the DLQ collection
        access(all) fun requeue(packId:UInt64) {
            let token <- self.withdraw(withdrawID: packId) as! @NFT

            let address=token.resetOpenedBy()
            let cap=getAccount(address).capabilities.get<&Collection>(FindPack.CollectionPublicPath)!
            let receiver = cap.borrow()!
            receiver.deposit(token: <- token)
            emit Requeued(packId:packId, address: cap.address)
        }

        access(all) fun open(packId: UInt64, receiverCap: {Type : Capability<&{NonFungibleToken.Receiver}>}) {
            for cap in receiverCap.values {
                if !cap.check() {
                    panic("Receiver cap is not valid")
                }
            }
            let pack=self.borrowFindPack(id:packId) ?? panic ("This pack is not in your collection")

            if !pack.getMetadata().canBeOpened() {
                panic("You cannot open the pack yet")
            }

            let token <- self.withdraw(withdrawID: packId) as! @FindPack.NFT
            token.setOpenedBy(receiverCap)

            // establish the receiver for Redeeming FindPack
            let receiver = FindPack.account.capabilities.get<&{NonFungibleToken.Receiver}>(FindPack.OpenedCollectionPublicPath)!.borrow()!

            let typeId=token.getTypeID()
            let packTypeName=token.packTypeName
            let metadata= token.getMetadata()
            // deposit for consumption
            receiver.deposit(token: <- token)

            let packFields = metadata.packFields
            packFields["packImage"] = packFields["packImage"] ?? metadata.getThumbnail().uri()
            let packNFTTypes = metadata.getItemTypesAsStringArray()
            emit Opened(packTypeName: packTypeName, packTypeId:typeId, packId: packId, address:self.owner!.address, packFields:packFields, packNFTTypes:packNFTTypes)
        }

        access(all) fun buyWithSignature(packId: UInt64, signature:String, vault: @{FungibleToken.Vault}, collectionCapability: Capability<&Collection>) {
            pre {
                self.owner!.address == FindPack.account.address : "You can only buy pack directly from the FindPack account"
            }

            let nft <- self.withdraw(withdrawID: packId) as!  @NFT
            let metadata= nft.getMetadata()

            // get the correct sale struct based on time and lowest price
            let timestamp=Clock.time()
            var lowestPrice : UFix64? = nil
            var saleInfo : SaleInfo? = nil
            var saleInfoIndex : Int? = nil
            for i, info in metadata.saleInfos {
                // for later implement : if it requires all sale info checks
                if info.checkBuyable(addr: collectionCapability.address, time:timestamp) {
                    if lowestPrice == nil || lowestPrice! > info.price {
                        lowestPrice = info.price
                        saleInfo = info
                        saleInfoIndex = i
                    }
                }
            }

            if saleInfo == nil || saleInfoIndex == nil || lowestPrice == nil {
                panic("You cannot buy the pack yet")
            }

            if !metadata.requiresReservation {
                panic("This pack type does not require reservation, use the open buy method")
            }

            if vault.getType() != metadata.walletType {
                panic("The vault sent in is not of the desired type ".concat(metadata.walletType.identifier))
            }

            if saleInfo!.price != vault.getBalance() {
                panic("Vault does not contain required amount of FT ".concat(saleInfo!.price.toString()))
            }
            let keyList = Crypto.KeyList()
            let accountKey = self.owner!.keys.get(keyIndex: 0)!.publicKey

            // Adds the public key to the keyList
            keyList.add(
                PublicKey(
                    publicKey: accountKey.publicKey,
                    signatureAlgorithm: accountKey.signatureAlgorithm
                ),
                hashAlgorithm: HashAlgorithm.SHA3_256,
                weight: 1.0
            )

            // Creates a Crypto.KeyListSignature from the signature provided in the parameters
            let signatureSet: [Crypto.KeyListSignature] = []
            signatureSet.append(
                Crypto.KeyListSignature(
                    keyIndex: 0,
                    signature: signature.decodeHex()
                )
            )

            // Verifies that the signature is valid and that it was generated from the
            // owner of the collection
            if(!keyList.verify(signatureSet: signatureSet, signedData: nft.hash.utf8)){
                panic("Unable to validate the signature for the pack!")
            }

            let packTypeId=nft.getTypeID()
            let packTypeName = nft.packTypeName

            for royalty in metadata.primarySaleRoyalties.getRoyalties() {
                if royalty.receiver.check(){
                    royalty.receiver.borrow()!.deposit(from: <- vault.withdraw(amount: saleInfo!.price * royalty.cut))
                } else {
                    //to-do :  emit events here ?
                }
            }

            let wallet = getAccount(FindPack.account.address).capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)!
            if wallet.check() {
                let r = MetadataViews.Royalty(receiver: wallet, cut: 0.15, description: ".find")
                r.receiver.borrow()!.deposit(from: <- vault.withdraw(amount: saleInfo!.price * r.cut))
            }

            metadata.wallet.borrow()!.deposit(from: <- vault)
            collectionCapability.borrow()!.deposit(token: <- nft)

            let packFields = metadata.packFields
            packFields["packImage"] = packFields["packImage"] ?? metadata.getThumbnail().uri()
            let packNFTTypes = metadata.getItemTypesAsStringArray()
            emit Purchased(packTypeName: packTypeName, packTypeId: packTypeId, packId: packId, address: collectionCapability.address, amount:saleInfo!.price, packFields:packFields, packNFTTypes:packNFTTypes)
        }

        access(all) fun buy(packTypeName: String, typeId: UInt64, vault: @{FungibleToken.Vault}, collectionCapability: Capability<&Collection>) {
            pre {
                self.owner!.address == FindPack.account.address : "You can only buy pack directly from the FindPack account"
            }

            let keys = self.ownedNFTs.keys
            if  keys.length == 0 {
                panic("No more packs of this type. PackName: ".concat(packTypeName).concat(" packId : ").concat(typeId.toString()))
            }

            let key=keys[0]
            let nft <- self.withdraw(withdrawID: key) as!  @NFT
            let metadata= nft.getMetadata()

            if metadata.requiresReservation {
                panic("Cannot buy a pack that requires reservation without a reservation signature and id")
            }

            let user=collectionCapability.address
            let timestamp=Clock.time()

            var lowestPrice : UFix64? = nil
            var saleInfo : SaleInfo? = nil
            var saleInfoIndex : Int? = nil
            for i, info in metadata.saleInfos {
                // for later implement : if it requires all sale info checks
                if info.checkBuyable(addr: collectionCapability.address, time:timestamp) {
                    if lowestPrice == nil || lowestPrice! > info!.price {
                        lowestPrice = info!.price
                        saleInfo = info
                        saleInfoIndex = i
                    }
                }
            }

            if saleInfo == nil || saleInfoIndex == nil || lowestPrice == nil {
                panic("You cannot buy the pack yet")
            }

            if vault.getType() != metadata.walletType {
                panic("The vault sent in is not of the desired type ".concat(metadata.walletType.identifier))
            }

            if saleInfo!.price != vault.getBalance() {
                panic("Vault does not contain required amount of FT ".concat(saleInfo!.price.toString()))
            }

            var royaltiesPaid=false
            for royalty in metadata.primarySaleRoyalties.getRoyalties() {
                if royalty.receiver.check(){
                    royalty.receiver.borrow()!.deposit(from: <- vault.withdraw(amount: saleInfo!.price * royalty.cut))
                    royaltiesPaid=true
                } else {
                    //to-do :  emit events here ?
                }
            }

            //TODO: REMOVE THIS
            if !royaltiesPaid {
                let wallet = getAccount(FindPack.account.address).capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)!
                if wallet.check() {
                    let r = MetadataViews.Royalty(receiver: wallet, cut: 0.10, description: ".find")
                    r.receiver.borrow()!.deposit(from: <- vault.withdraw(amount: saleInfo!.price * r.cut))
                }
            }

            // record buy
            FindPack.borrowSaleInfo(packTypeName: packTypeName, packTypeId: typeId, index: saleInfoIndex!).buy(collectionCapability.address)

            metadata.wallet.borrow()!.deposit(from: <- vault)
            collectionCapability.borrow()!.deposit(token: <- nft)

            let packFields = metadata.packFields
            packFields["packImage"] = packFields["packImage"] ?? metadata.getThumbnail().uri()
            let packNFTTypes = metadata.getItemTypesAsStringArray()
            emit Purchased(packTypeName: packTypeName, packTypeId: typeId, packId: key, address: collectionCapability.address, amount:saleInfo!.price, packFields: packFields, packNFTTypes:packNFTTypes)
        }

        // withdraw
        // Removes an NFT from the collection and moves it to the caller
        //
        access(NonFungibleToken.Withdrawable) fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT} {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Could not withdraw nft")

            let nft <- token as! @NFT

            emit Withdraw(id: nft.id, from: self.owner?.address)

            return <-nft
        }

        access(all) fun getSupportedNFTTypes() : [Type] {
            return [
            Type<@FindPack.NFT>()
            ]
        }

        access(all) fun isSupportedNFTType(_ type: Type) : Bool {
            return type == Type<@FindPack.NFT>()
        }

        access(all) fun createEmptyCollection(): @{NonFungibleToken.Collection} {
            return <- (create Collection() as @{NonFungibleToken.Collection})
        }

        access(NonFungibleToken.Withdrawable) fun transfer(id: UInt64, receiver: Capability<&{NonFungibleToken.Receiver}>): Bool {
            let token <- self.ownedNFTs.remove(key: id) ?? panic("Could not withdraw nft")

            let nft <- token as! @NFT

            emit Withdraw(id: nft.id, from: self.owner?.address)

            receiver.borrow().deposit(token: <-nft)

            return true
        }

        access(all) view fun getLength() : Int {
            return self.ownedNFTs.length
        }

        access(all) view fun getIDsWithTypes() : [{UInt64 : Type}] {
            let ids : [{UInt64 : Type}] = []
            return ids
        }

        // deposit
        // Takes a NFT and adds it to the collections dictionary
        // and adds the ID to the id array
        //
        access(all) fun deposit(token: @{NonFungibleToken.NFT}) {
            let token <- token as! @FindPack.NFT

            let id: UInt64 = token.id
            let tokenTypeId = token.getTypeID()

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token

            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }

        // getIDs
        // Returns an array of the IDs that are in the collection
        //
        access(all) view fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        access(all) fun contains(_ id: UInt64) : Bool {
            return self.ownedNFTs.containsKey(id)
        }

        //return the number of packs left of a type
        access(all) fun getPacksLeft() : Int {
            return self.ownedNFTs.length
        }

        // borrowNFT
        // Gets a reference to an NFT in the collection
        // so that the caller can read its metadata and call its methods
        //
        access(all) view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT} {
            return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
        }

        // borrowFindPack
        // Gets a reference to an NFT in the collection as a FindPack.NFT,
        // exposing all of its fields.
        // This is safe as there are no functions that can be called on the FindPack.
        //
        access(all) fun borrowFindPack(id: UInt64): &FindPack.NFT? {
            if self.ownedNFTs[id] != nil {
                let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
                return ref as! &FindPack.NFT
            } else {
                return nil
            }
        }

        access(all) view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver} {
            let nft =  (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
            let exampleNFT = nft as! &NFT
            return exampleNFT
        }

        // destructor
        //
        destroy() {
            destroy self.ownedNFTs
        }

        // initializer
        //
        init () {
            self.ownedNFTs <- {}
        }
    }

    access(all) fun createEmptyCollection(): @{NonFungibleToken.Collection} {
        return <- (create Collection() as @{NonFungibleToken.Collection})
    }

    access(account) fun mintNFT(packTypeName: String, typeId: UInt64, hash: String, royalties: [MetadataViews.Royalty]) : @{NonFungibleToken.NFT} {

        let nft <- create FindPack.NFT(packTypeName: packTypeName, typeId: typeId, hash:hash, royalties:royalties)
        emit Minted(id: nft.id, typeId:typeId)

        // deposit it in the recipient's account using their reference
        return <- (nft as @{NonFungibleToken.NFT})
    }

    access(account) fun fulfill(packId: UInt64, types:[Type], rewardIds: [UInt64], salt:String) {

        let openedPacksCollection = FindPack.account.storage.borrow<auth (NonFungibleToken.Withdrawable) &{FindPack.Collection}>(from: FindPack.OpenedCollectionStoragePath)!
        let pack <- openedPacksCollection.withdraw(withdrawID: packId) as! @FindPack.NFT
        let packTypeName = pack.packTypeName
        let packTypeId = pack.getTypeID()
        let metadata = FindPack.getMetadataById(packTypeName:packTypeName, typeId:packTypeId)!
        let packFields = metadata.packFields
        let packNFTTypes = metadata.getItemTypesAsStringArray()

        let firstType = types[0]
        let receiver= pack.getOpenedBy()
        let	receivingAddress = receiver[firstType]!.address
        let hash= pack.getHash()
        let rewards=pack.getMetadata().providerCaps

        let receiverAccount=getAccount(receivingAddress)
        var freeStorage=UInt64(0)
        // prevent underflow
        if receiverAccount.storage.capacity >= receiverAccount.storage.used {
            freeStorage = receiverAccount.storage.capacity- receiverAccount.storage.used
        }
        Debug.log("Free capacity from account ".concat(freeStorage.toString()))
        if pack.getMetadata().storageRequirement > freeStorage {
            emit FulfilledError(packTypeName: packTypeName, packTypeId: packTypeId, packId:packId, address:receivingAddress, reason: "Not enough flow to hold the content of the pack. Please top up your account")
            self.transferToDLQ(<- pack)
            return
        }

        let receiverCheck :{Type: Bool} = {}
        var hashString = salt
        for i, type in types {

            if receiverCheck[type] == nil {
                if !receiver[type]!.check() {
                    emit FulfilledError(packTypeName: packTypeName, packTypeId: packTypeId, packId:packId, address:receiver[type]!.address, reason: "The receiver registered in this pack is not valid")
                    self.transferToDLQ(<- pack)
                    return
                }

                if !rewards[type]!.check() {
                    emit FulfilledError(packTypeName: packTypeName, packTypeId: packTypeId, packId:packId, address:receiver[type]!.address, reason: "Cannot borrow provider capability to withdraw nfts")
                    self.transferToDLQ(<- pack)
                    return
                }
                receiverCheck[type]=true
            }

            let id = rewardIds[i]
            hashString= hashString.concat(",").concat(type.identifier).concat(";").concat(id.toString())
        }

        let digest = HashAlgorithm.SHA3_384.hash(hashString.utf8)
        let digestAsString=String.encodeHex(digest)
        if digestAsString != hash {
            emit FulfilledError(packTypeName: packTypeName, packTypeId: packTypeId, packId:packId, address:receivingAddress, reason: "The content of the pack was not verified with the hash provided at mint")
            Debug.log("digestAsString : ".concat(hashString))
            Debug.log("hash : ".concat(hash))
            self.transferToDLQ(<- pack)
            return
        }

        for i, type in types {
            let id = rewardIds[i]
            let target=receiver[type]!.borrow()!
            let source=rewards[type]!.borrow<auth (NonFungibleToken.Withdrawable)>()!

            let viewType= Type<PackRevealData>()
            let nft=source.borrowViewResolver(id: id)!

            var fields : {String: String}= {}
            if nft.getViews().contains(viewType) {
                let view=nft.resolveView(viewType)! as! PackRevealData
                fields=view.data
            } else {
                if let display=MetadataViews.getDisplay(nft) {
                    fields["nftName"]=display.name
                    fields["nftImage"]=display.thumbnail.uri()
                }
            }

            if let cd = MetadataViews.getNFTCollectionData(nft) {
                fields["path"]=cd.storagePath.toString()
            }
            let token <- source.withdraw(withdrawID: id)

            emit PackReveal(
                packTypeName: packTypeName,
                packTypeId: packTypeId,
                packId:packId,
                address:receiver[type]!.address,
                rewardId: id,
                rewardType: token.getType().identifier,
                rewardFields: fields,
                packFields: packFields,
                packNFTTypes: packNFTTypes
            )
            target.deposit(token: <-token)
        }
        emit Fulfilled(packTypeName: packTypeName, packTypeId: packTypeId, packId:packId, address:receivingAddress!, packFields:packFields, packNFTTypes:packNFTTypes)

        destroy pack
    }

    access(account) fun transferToDLQ(_ pack: @NFT) {
        let dlq = FindPack.account.storage.borrow<&FindPack.Collection>(from: FindPack.DLQCollectionStoragePath)!
        dlq.deposit(token: <- pack)
    }

    access(account) fun getPacksCollectionPath(packTypeName: String, packTypeId: UInt64) : String {
        return "FindPack_".concat(packTypeName).concat("_").concat(packTypeId.toString())
    }

    access(all) fun getPacksCollection(packTypeName: String, packTypeId: UInt64) : &FindPack.Collection {

        let pathIdentifier = self.getPacksCollectionPath(packTypeName: packTypeName, packTypeId: packTypeId)
        let path = PublicPath(identifier: pathIdentifier) ?? panic("Cannot create path from identifier : ".concat(pathIdentifier))
        return FindPack.account.capabilities.get<&FindPack.Collection>(path)!.borrow() ?? panic("Could not borow FindPack collection for path : ".concat(pathIdentifier))
    }

    // given a path, lookin to the NFT Collection and return a new empty collection
    access(all) fun createEmptyCollectionFromPackData(packData: FindPack.Metadata, type: Type) : @{NonFungibleToken.Collection} {
        let cap = packData.providerCaps[type] ?? panic("Type passed in does not exist in this pack ".concat(type.identifier))
        if !cap.check() {
            panic("Provider capability of pack is not valid Name and ID".concat(type.identifier))
        }
        let ref = cap.borrow()!
        let resolver = ref.borrowViewResolver(id : ref.getIDs()[0])!  // if the ID length is 0, there must be some problem
        let collectionData = MetadataViews.getNFTCollectionData(resolver) ?? panic("Collection Data for this NFT Type is missing. Type : ".concat(resolver.getType().identifier))
        return <- collectionData.createEmptyCollection()
    }

    access(all) fun canBuy(packTypeName: String, packTypeId:UInt64, user:Address) : Bool {

        let packs=FindPack.getPacksCollection(packTypeName: packTypeName, packTypeId:packTypeId)

        let packsLeft= packs.getPacksLeft()
        if packsLeft == 0 {
            return false
        }

        let packMetadata=FindPack.getMetadataById(packTypeName: packTypeName, typeId: packTypeId)

        if packMetadata==nil {
            return false
        }
        let timestamp=Clock.time()

        let metadata=packMetadata!

        for info in metadata.saleInfos {
            if info.checkBuyable(addr: user, time:timestamp) {
                return true
            }
        }

        return false
    }

    access(all) fun getCurrentPrice(packTypeName: String, packTypeId:UInt64, user:Address) : UFix64? {

        let packs=FindPack.getPacksCollection(packTypeName: packTypeName, packTypeId:packTypeId)

        let packsLeft= packs.getPacksLeft()
        if packsLeft == 0 {
            return nil
        }

        let packMetadata=FindPack.getMetadataById(packTypeName: packTypeName, typeId: packTypeId)

        if packMetadata==nil {
            return nil
        }
        let timestamp=Clock.time()

        let metadata=packMetadata!

        var lowestPrice : UFix64? = nil
        for info in metadata.saleInfos {
            if info.checkBuyable(addr: user, time:timestamp) {
                if lowestPrice == nil || lowestPrice! > info!.price {
                    lowestPrice = info!.price
                }
            }
        }

        return lowestPrice
    }

    access(contract) fun borrowSaleInfo(packTypeName: String, packTypeId: UInt64, index: Int) : &FindPack.SaleInfo {
        let mappingRef = (&FindPack.packMetadata[packTypeName] as &{UInt64: FindPack.Metadata}?)!
        let ref = (mappingRef[packTypeId] as &FindPack.Metadata?)!
        return ref.borrowSaleInfo(index)
    }

    access(all) fun getOwnerCollection() : Capability<&FindPack.Collection> {
        return FindPack.account.capabilities.get<&FindPack.Collection>(FindPack.CollectionPublicPath)!
    }

    access(all) resource Forge: FindForge.Forge {
        access(all) fun mint(platform: FindForge.MinterPlatform, data: AnyStruct, verifier: &FindForge.Verifier) : @{NonFungibleToken.NFT} {

            let royalties : [MetadataViews.Royalty] = []
            // there should be no find cut for the pack.
            if platform.minterCut != nil && platform.minterCut! != 0.0 {
                royalties.append(MetadataViews.Royalty(receiver:platform.getMinterFTReceiver(), cut: platform.minterCut!, description: "creator"))
            }
            let input = data as? MintPackData ?? panic("The data passed in is not in MintPackData Struct")
            return <- FindPack.mintNFT(packTypeName: platform.name, typeId: input.typeId , hash: input.hash, royalties: royalties)
        }

        access(all) fun addContractData(platform: FindForge.MinterPlatform, data: AnyStruct, verifier: &FindForge.Verifier) {
            let type = data.getType()

            switch type {
            case Type<{UInt64 : Metadata}>() :
                let typedData = data as! {UInt64 : Metadata}
                for key in typedData.keys {
                    FindPack.registerMetadata(packTypeName: platform.name, typeId: key, metadata: typedData[key]!)
                }
                return

                default :
                panic("Type : ".concat(data.getType().identifier).concat("is not supported in Find Pack"))
            }
        }
    }

    access(account) fun createForge() : @{FindForge.Forge} {
        return <- create Forge()
    }

    // initializer
    //
    init() {
        self.CollectionStoragePath = /storage/FindPackCollection
        self.CollectionPublicPath = /public/FindPackCollection
        self.CollectionPrivatePath = /private/FindPackCollection

        self.OpenedCollectionStoragePath = /storage/FindPackOpenedCollection
        self.OpenedCollectionPublicPath = /public/FindPackOpenedCollection

        self.DLQCollectionStoragePath = /storage/FindPackDLQCollection
        self.DLQCollectionPublicPath = /public/FindPackDLQCollection

        self.PackMetadataStoragePath= /storage/FindPackMetadata

        //this will not be used, we use UUID as id
        self.totalSupply = 0

        self.packMetadata={}

        // this contract will hold a Collection that FindPack can be deposited to and Admins can Consume them to transfer nfts to the depositing account
        let openedCollection <- create Collection()
        self.account.storage.save(<- openedCollection, to: self.OpenedCollectionStoragePath)
        let cap = self.account.capabilities.storage.issue<&Collection>(self.OpenedCollectionStoragePath)
        self.account.capabilities.publish(cap, at: self.OpenedCollectionPublicPath)

        //a DLQ storage slot so that the opener can put items that cannot be opened/transferred here.
        let dlqCollection <- create Collection()
        self.account.storage.save(<- dlqCollection, to: self.DLQCollectionStoragePath)
        let dlqCap = self.account.capabilities.storage.issue<&Collection>(self.DLQCollectionStoragePath)
        self.account.capabilities.publish(dlqCap, at: self.DLQCollectionPublicPath)

        FindForge.addForgeType(<- create Forge())

        //TODO: Add the Forge resource aswell
        FindForge.addPublicForgeType(forgeType: Type<@Forge>())

        emit ContractInitialized()

    }
}




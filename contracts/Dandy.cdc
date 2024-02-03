import NonFungibleToken from "./standard/NonFungibleToken.cdc"
import FungibleToken from "./standard/FungibleToken.cdc"
import MetadataViews from "./standard/MetadataViews.cdc"
import FindViews from "./FindViews.cdc"
import FindForge from "./FindForge.cdc"
import ViewResolver from "./standard/ViewResolver.cdc"

access(all) contract Dandy :ViewResolver{

    access(all) let CollectionStoragePath: StoragePath
    access(all) let CollectionPrivatePath: PrivatePath
    access(all) let CollectionPublicPath: PublicPath
    access(all) var totalSupply: UInt64

    /*store all valid type converters for Dandys
    This is to be able to make the contract compatible with the forthcomming NFT standard. 

    If a Dandy supports a type with the same Identifier as a key here all the ViewConverters convertTo types are added to the list of available types
    When resolving a type if the Dandy does not itself support this type check if any viewConverters do
    */
    access(account) var viewConverters: {String: [{ViewConverter}]}

    access(all) event ContractInitialized()
    access(all) event Withdraw(id: UInt64, from: Address?)
    access(all) event Deposit(id: UInt64, to: Address?)
    access(all) event Minted(id:UInt64, minter:String, name:String, description:String)

    access(all) struct ViewInfo {
        access(contract) let typ: Type
        access(contract) let result: AnyStruct

        init(typ:Type, result:AnyStruct) {
            self.typ=typ
            self.result=result
        }
    }

    access(all) struct DandyInfo {
        access(all) let name: String
        access(all) let description: String
        access(all) let thumbnail: MetadataViews.Media
        access(all) let schemas: [AnyStruct]
        access(all) let externalUrlPrefix:String?

        init(name: String, description: String, thumbnail: MetadataViews.Media, schemas: [AnyStruct], externalUrlPrefix:String?) {
            self.name=name 
            self.description=description 
            self.thumbnail=thumbnail 
            self.schemas=schemas 
            self.externalUrlPrefix=externalUrlPrefix 
        }
    }
    access(all) resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver {
        access(all) let id: UInt64
        access(self) var nounce: UInt64

        access(self) var primaryCutPaid: Bool
        access(contract) let schemas: {String : ViewInfo}
        access(contract) let name: String
        access(contract) let description: String
        access(contract) let thumbnail: MetadataViews.Media
        access(contract) let platform: FindForge.MinterPlatform

        init(name: String, description: String, thumbnail: MetadataViews.Media, schemas: {String: ViewInfo}, platform: FindForge.MinterPlatform, externalUrlPrefix: String?) {
            self.id = self.uuid
            self.schemas=schemas
            self.thumbnail=thumbnail
            self.name=name
            self.description=description
            self.nounce=0
            self.primaryCutPaid=false
            self.platform=platform
            if externalUrlPrefix != nil {
                let mvt = Type<MetadataViews.ExternalURL>()
                self.schemas[mvt.identifier] = ViewInfo(typ:mvt, result: MetadataViews.ExternalURL(externalUrlPrefix!.concat("/").concat(self.id.toString())))
            }
        }


        access(all) view fun getID() : UInt64{
            return self.id
        }

        access(all) fun increaseNounce() {
            self.nounce=self.nounce+1
        }

        access(all) fun getMinterPlatform() : FindForge.MinterPlatform {
            if let fetch = FindForge.getMinterPlatform(name: self.platform.name, forgeType: Dandy.getForgeType()) {

                let platform = &self.platform as &FindForge.MinterPlatform
                platform.updateExternalURL(fetch.externalURL)
                platform.updateDesription(fetch.description)
                platform.updateSquareImagen(fetch.squareImage)
                platform.updateBannerImage(fetch.bannerImage)
                platform.updateSocials(fetch.socials)

            }

            return self.platform
        }

        access(all) view fun getViews() : [Type] {

            let views = [
            Type<FindViews.Nounce>(),
            Type<MetadataViews.NFTCollectionData>(),
            Type<MetadataViews.NFTCollectionDisplay>(),
            Type<MetadataViews.Display>(),
            Type<MetadataViews.Royalties>()]


            //TODO: fix
            //if any specific here they will override
            for s in self.schemas.keys {
                if !views.contains(self.schemas[s]!.typ) {
                    views.concat([self.schemas[s]!.typ])
                }
            }

            return views
        }

        access(self) fun resolveRoyalties() : MetadataViews.Royalties {
            let royalties : [MetadataViews.Royalty] = []

            if self.schemas.containsKey(Type<MetadataViews.Royalties>().identifier) {
                let multipleRoylaties=self.schemas[Type<MetadataViews.Royalties>().identifier]!.result as! MetadataViews.Royalties
                royalties.appendAll(multipleRoylaties.getRoyalties())
            }

            if self.platform.minterCut != nil && self.platform.minterCut! != 0.0 {
                let royalty = MetadataViews.Royalty(receiver: self.platform.getMinterFTReceiver(), cut: self.platform.minterCut!, description: "creator")
                royalties.append(royalty)
            }

            if self.platform.platformPercentCut != 0.0 {
                let royalty = MetadataViews.Royalty(receiver: self.platform.platform, cut: self.platform.platformPercentCut, description: "find forge")
                royalties.append(royalty)
            }

            return MetadataViews.Royalties(royalties)
        }

        access(all) fun resolveDisplay() : MetadataViews.Display {
            return MetadataViews.Display(
                name: self.name,
                description: self.description,
                thumbnail: self.thumbnail.file
            )
        }

        //Note that when resolving schemas shared data are loaded last, so use schema names that are unique. ie prefix with shared/ or something
        //NB! This will _not_ error out if it does not return Optional!
        access(all) fun resolveView(_ type: Type): AnyStruct? {

            if type == Type<MetadataViews.NFTCollectionDisplay>() {
                let minterPlatform = self.getMinterPlatform()
                let externalURL = MetadataViews.ExternalURL(minterPlatform.externalURL)
                let squareImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: minterPlatform.squareImage), mediaType: "image")
                let bannerImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: minterPlatform.bannerImage), mediaType: "image")

                let socialMap : {String : MetadataViews.ExternalURL} = {}
                for social in minterPlatform.socials.keys {
                    socialMap[social] = MetadataViews.ExternalURL(minterPlatform.socials[social]!)
                }
                return MetadataViews.NFTCollectionDisplay(name: minterPlatform.name, description: minterPlatform.description, externalURL: externalURL, squareImage: squareImage, bannerImage: bannerImage, socials: socialMap)
            }


            if type == Type<FindViews.Nounce>() {
                return FindViews.Nounce(self.nounce)
            }

            if type == Type<MetadataViews.Royalties>() {
                return self.resolveRoyalties()
            }

            if type == Type<MetadataViews.Display>() {
                return self.resolveDisplay()
            }


            if type == Type<MetadataViews.NFTCollectionData>() {
                return Dandy.resolveContractView(resourceType: Type<@NFT>(), viewType: Type<MetadataViews.NFTCollectionData>())
            }

            if self.schemas.keys.contains(type.identifier) {
                return self.schemas[type.identifier]!.result
            }
            return nil
        }

        access(all) fun createEmptyCollection(): @{NonFungibleToken.Collection} {
            return <-Dandy.createEmptyCollection()
        }
    }

    access(all) view fun getContractViews(resourceType: Type?): [Type] {
        return [
            Type<MetadataViews.NFTCollectionData>()
        ]
    }

    access(all) fun resolveContractView(resourceType: Type?, viewType: Type): AnyStruct? {
        switch viewType {
            case Type<MetadataViews.NFTCollectionData>():
                let collectionRef = self.account.storage.borrow<&Dandy.Collection>(
                        from: Dandy.CollectionStoragePath
                    ) ?? panic("Could not borrow a reference to the stored collection")
                let collectionData = MetadataViews.NFTCollectionData(
                    storagePath: Dandy.CollectionStoragePath,
                    publicPath: Dandy.CollectionPublicPath,
                    publicCollection: Type<&Dandy.Collection>(),
                    publicLinkedType: Type<&Dandy.Collection>(),
                    createEmptyCollectionFunction: (fun(): @{NonFungibleToken.Collection} {
                        return <-Dandy.createEmptyCollection()
                    })
                )
                return collectionData
        }
        return nil
    }


    access(all) resource interface CollectionPublic {
        access(all) fun getIDsFor(minter: String): [UInt64] 
        access(all) fun getMinters(): [String] 
    }

    access(all) resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, ViewResolver.ResolverCollection, CollectionPublic {
        // dictionary of NFT conforming tokens
        // NFT is a resource type with an `UInt64` ID field
        access(all) var ownedNFTs: @{UInt64: {NonFungibleToken.NFT}}

        // Mapping of {Minter Platform Name : [NFT ID]}
        access(self) let nftIndex: {String : {UInt64 : Bool}}


        init () {
            self.ownedNFTs <- {}
            self.nftIndex = {}
        }


        access(NonFungibleToken.Withdraw | NonFungibleToken.Owner) fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT} {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT. withdrawID : ".concat(withdrawID.toString()))

            let dandyToken <- token as! @NFT
            let minterPlatform = dandyToken.getMinterPlatform()
            let minterName = minterPlatform.name 
            if self.nftIndex.containsKey(minterName) {
                self.nftIndex[minterName]!.remove(key: withdrawID)
                if self.nftIndex[minterName]!.length < 1 {
                    self.nftIndex.remove(key: minterName)
                }
            }

            emit Withdraw(id: dandyToken.id, from: self.owner?.address)


            return <- dandyToken
        }


        // deposit takes a NFT and adds it to the collections dictionary
        // and adds the ID to the id array
        access(all) fun deposit(token: @{NonFungibleToken.NFT}) {
            let token <- token as! @Dandy.NFT

            let minterPlatform = token.getMinterPlatform()
            let minterName = minterPlatform.name 
            if self.nftIndex.containsKey(minterName) {
                self.nftIndex[minterName]!.insert(key: token.id, false)
            } else {
                self.nftIndex[minterName] = {}
                self.nftIndex[minterName]!.insert(key: token.id, false)
            }

            token.increaseNounce()

            let id: UInt64 = token.id

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token

            emit Deposit(id: id, to: self.owner?.address)


            destroy oldToken
        }

        access(all) fun getMinters(): [String] {
            return self.nftIndex.keys
        }

        access(all) fun getIDsFor(minter: String): [UInt64] {
            return self.nftIndex[minter]?.keys ?? []
        }

        // getIDs returns an array of the IDs that are in the collection
        access(all) view fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        // borrowNFT gets a reference to an NFT in the collection
        // so that the caller can read its metadata and call its methods
        access(all) view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}? {
            return &self.ownedNFTs[id]
        }


        /// Borrow the view resolver for the specified NFT ID
        access(all) view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?   {
            return (&self.ownedNFTs[id] as &{ViewResolver.Resolver}?)!
        }

        access(all) view fun getDefaultStoragePath() : StoragePath {
            return Dandy.CollectionStoragePath
        }

        access(all) view fun getDefaultPublicPath() : PublicPath {
            return Dandy.CollectionPublicPath
        }

        access(all) view fun getIDsWithTypes(): {Type: [UInt64]} {
            return { Type<@NFT>() : self.ownedNFTs.keys}
        }

        access(all) view fun getSupportedNFTTypes(): {Type: Bool} {
            return { Type<@NFT>() : true}
        }

        access(all) fun createEmptyCollection(): @{NonFungibleToken.Collection} {
            return <- create Collection() 
        }

        access(all) view fun getLength() : Int {
            return self.ownedNFTs.length
        }

        access(all) view fun isSupportedNFTType(type: Type) : Bool {
            return type == Type<@NFT>()
        }

    }

    access(account) fun mintNFT(name: String, description: String, thumbnail: MetadataViews.Media,  platform:FindForge.MinterPlatform, schemas: [AnyStruct], externalUrlPrefix:String?) : @NFT {
        let views : {String: ViewInfo} = {}
        for s in schemas {
            //if you send in display we ignore it, this will be made for you
            if s.getType() != Type<MetadataViews.Display>() {
                views[s.getType().identifier]=ViewInfo(typ:s.getType(), result: s)
            }
        }

        let nft <-  create NFT(name: name, description:description,thumbnail: thumbnail, schemas:views, platform: platform, externalUrlPrefix:externalUrlPrefix)

        //TODO: remove this
        emit Minted(id:nft.id, minter:nft.platform.name, name: name, description:description)
        return <-  nft
    }

    access(all) resource Forge: FindForge.Forge {
        access(FindForge.ForgeOwner) fun mint(platform: FindForge.MinterPlatform, data: AnyStruct, verifier: &FindForge.Verifier) : @{NonFungibleToken.NFT} {
            let info = data as? DandyInfo ?? panic("The data passed in is not in form of DandyInfo.")
            return <- Dandy.mintNFT(name: info.name, description: info.description, thumbnail: info.thumbnail, platform: platform, schemas: info.schemas, externalUrlPrefix:info.externalUrlPrefix)
        }

        access(FindForge.ForgeOwner) fun addContractData(platform: FindForge.MinterPlatform, data: AnyStruct, verifier: &FindForge.Verifier) {
            // not used here 

            panic("Not supported for Dandy Contract") 
        }
    }

    access(account) fun createForge() : @{FindForge.Forge} {
        return <- create Forge()
    }

    // public function that anyone can call to create a new empty collection
    access(all) fun createEmptyCollection(): @{NonFungibleToken.Collection} {
        return <- create Collection()
    }

    access(all) fun getForgeType() : Type {
        return Type<@Forge>()
    }

    /// This struct interface is used on a contract level to convert from one View to another. 
    /// See Dandy nft for an example on how to convert one type to another
    access(all) struct interface ViewConverter {
        access(all) let to: Type
        access(all) let from: Type

        access(all) fun convert(_ value:AnyStruct) : AnyStruct
    }

    init() {
        // Initialize the total supply
        self.totalSupply=0
        self.CollectionPublicPath = /public/findDandy
        self.CollectionPrivatePath = /private/findDandy
        self.CollectionStoragePath = /storage/findDandy
        self.viewConverters={}

        FindForge.addForgeType(<- create Forge())

        //TODO: Add the Forge resource aswell
        FindForge.addPublicForgeType(forgeType: Type<@Forge>())

        emit ContractInitialized()
    }
}

import NonFungibleToken from "./standard/NonFungibleToken.cdc"
import FungibleToken from "./standard/FungibleToken.cdc"
import MetadataViews from "./standard/MetadataViews.cdc"
import FindForge from "./FindForge.cdc"
import FindPack from "./FindPack.cdc"

pub contract GeneratedExperiences: NonFungibleToken {

    pub var totalSupply: UInt64

    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event Minted(id:UInt64, season: UInt64, name: String, thumbnail: String, fullsize: String, artist: String, rarity: String, edition: UInt64, maxEdition: UInt64)
    pub event SeasonAdded(season:UInt64, squareImage: String, bannerImage: String)

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPrivatePath: PrivatePath
    pub let CollectionPublicPath: PublicPath
    pub let MinterStoragePath: StoragePath

    pub let CollectionName : String

    // {Season : CollectionInfo}
    pub let collectionInfo: {UInt64 : CollectionInfo}

    pub struct CollectionInfo {
        pub let season: UInt64
        pub var royalties: [MetadataViews.Royalty]
        // This is only used internally for fetching royalties in
        pub let royaltiesInput: [FindPack.Royalty]
        pub let squareImage: MetadataViews.Media
        pub let bannerImage: MetadataViews.Media
        pub let description: String
        pub let socials: {String : String}
        pub let extra: {String: AnyStruct}

        init(
            season: UInt64,
            royalties: [MetadataViews.Royalty],
            royaltiesInput: [FindPack.Royalty],
            squareImage: MetadataViews.Media,
            bannerImage: MetadataViews.Media,
            socials: {String : String},
            description: String
        ) {
            self.season = season
            self.royalties = royalties
            self.royaltiesInput = royaltiesInput
            self.squareImage = squareImage
            self.bannerImage = bannerImage
            self.description = description
            self.socials = socials
            self.extra={}
        }

        // This is only used internally for fetching royalties in
        access(contract) fun setRoyalty(r: [MetadataViews.Royalty])  {
            self.royalties = r
        }
    }

    pub struct Info {
        pub let season: UInt64
        pub let name: String
        pub let description: String
        pub let thumbnail: {MetadataViews.File}
        pub let fullsize: {MetadataViews.File}
        pub let edition: UInt64
        pub let maxEdition: UInt64
        pub let artist: String
        pub let rarity: String
        access(self) let extra: {String: AnyStruct}

        init(season: UInt64, name: String, description: String, thumbnail: {MetadataViews.File}, edition:UInt64, maxEdition:UInt64, fullsize: {MetadataViews.File}, artist: String, rarity: String) {
            self.season=season
            self.name=name
            self.description=description
            self.thumbnail=thumbnail
            self.fullsize=fullsize
            self.edition=edition
            self.maxEdition=maxEdition
            self.artist=artist
            self.rarity=rarity
            self.extra={}
        }
    }

    pub resource NFT: NonFungibleToken.INFT, ViewResolver.Resolver {
        pub let id: UInt64
        pub let info: Info

        init(
            info: Info
        ) {
            self.id = self.uuid
            self.info=info
        }

        pub fun getViews(): [Type] {
            return [
            Type<MetadataViews.Display>(),
            Type<MetadataViews.Royalties>(),
            Type<MetadataViews.Editions>(),
            Type<MetadataViews.Traits>(),
            Type<MetadataViews.ExternalURL>(),
            Type<MetadataViews.NFTCollectionData>(),
            Type<MetadataViews.NFTCollectionDisplay>(),
            Type<MetadataViews.Medias>(),
            Type<MetadataViews.Rarity>(),
            Type<FindPack.PackRevealData>()
            ]
        }

        pub fun resolveView(_ view: Type): AnyStruct? {

            let collection = GeneratedExperiences.collectionInfo[self.info.season]!

            switch view {

            case Type<FindPack.PackRevealData>():
                let data : {String : String} = {
                    "nftImage" : self.info.thumbnail.uri() ,
                    "nftName" : self.info.name,
                    "packType" : GeneratedExperiences.CollectionName
                }
                return FindPack.PackRevealData(data)

            case Type<MetadataViews.Display>():
                return MetadataViews.Display(
                    name: self.info.name,
                    description: self.info.description,
                    thumbnail: self.info.thumbnail
                )
            case Type<MetadataViews.Editions>():
                // We do not show season here unless there are more than 1 collectionInfo (that is indexed by season)
                let editionName = GeneratedExperiences.CollectionName.toLower()
                let editionInfo = MetadataViews.Edition(name: editionName, number: self.info.edition, max: self.info.maxEdition)
                let editionList: [MetadataViews.Edition] = [editionInfo]
                return MetadataViews.Editions(
                    editionList
                )
            case Type<MetadataViews.Royalties>():
                return MetadataViews.Royalties(collection.royalties)

            case Type<MetadataViews.ExternalURL>():
                if self.owner != nil {
                    return MetadataViews.ExternalURL("https://find.xyz/".concat(self.owner!.address.toString()).concat("/collection/main/").concat(GeneratedExperiences.CollectionName).concat("/").concat(self.id.toString()))
                }
                return MetadataViews.ExternalURL("https://find.xyz/")

            case Type<MetadataViews.NFTCollectionData>():
                return MetadataViews.NFTCollectionData(
                    storagePath: GeneratedExperiences.CollectionStoragePath,
                    publicPath: GeneratedExperiences.CollectionPublicPath,
                    providerPath: GeneratedExperiences.CollectionPrivatePath,
                    publicCollection: Type<&GeneratedExperiences.Collection{NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,ViewResolver.ResolverCollection}>(),
                    publicLinkedType: Type<&GeneratedExperiences.Collection{NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,ViewResolver.ResolverCollection}>(),
                    providerLinkedType: Type<&GeneratedExperiences.Collection{NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,ViewResolver.ResolverCollection}>(),
                    createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                        return <-GeneratedExperiences.createEmptyCollection()
                    })
                )
            case Type<MetadataViews.NFTCollectionDisplay>():

                var square = collection.squareImage

                var banner = collection.bannerImage

                let social : {String : MetadataViews.ExternalURL} = {}
                for s in collection.socials.keys {
                    social[s] = MetadataViews.ExternalURL(collection.socials[s]!)
                }

                return MetadataViews.NFTCollectionDisplay(
                    name: GeneratedExperiences.CollectionName,
                    description: collection.description,
                    externalURL: MetadataViews.ExternalURL("https://find.xyz/mp/".concat(GeneratedExperiences.CollectionName)),
                    squareImage: square,
                    bannerImage: banner,
                    socials: social
                )

            case Type<MetadataViews.Traits>() :

                let traits = [
                MetadataViews.Trait(name: "Artist", value: self.info.artist, displayType: "String", rarity: nil)
                ]

                if GeneratedExperiences.collectionInfo.length > 1 {
                    traits.append(MetadataViews.Trait(name: "Season", value: self.info.season, displayType: "Numeric", rarity: nil))
                }

                return MetadataViews.Traits(traits)

            case Type<MetadataViews.Medias>() :
                return MetadataViews.Medias([
                MetadataViews.Media(file: self.info.thumbnail, mediaType: "image"),
                MetadataViews.Media(file: self.info.fullsize, mediaType: "image")
                ])

            case Type<MetadataViews.Rarity>() :
                return MetadataViews.Rarity(score: nil, max: nil, description: self.info.rarity)
            }
            return nil
        }
    }

    pub resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection {
        // dictionary of NFT conforming tokens
        // NFT is a resource type with an `UInt64` ID field
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        init () {
            self.ownedNFTs <- {}
        }

        // withdraw removes an NFT from the collection and moves it to the caller
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

            emit Withdraw(id: token.id, from: self.owner?.address)

            return <-token
        }

        // deposit takes a NFT and adds it to the collections dictionary
        // and adds the ID to the id array
        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @GeneratedExperiences.NFT

            let id: UInt64 = token.id

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token

            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }

        // getIDs returns an array of the IDs that are in the collection
        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        // borrowNFT gets a reference to an NFT in the collection
        // so that the caller can read its metadata and call its methods
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }

        pub fun borrowViewResolver(id: UInt64): &AnyResource{ViewResolver.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let ge = nft as! &GeneratedExperiences.NFT
            return ge as &AnyResource{ViewResolver.Resolver}
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    // public function that anyone can call to create a new empty collection
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    pub resource Forge: FindForge.Forge {
        pub fun mint(platform: FindForge.MinterPlatform, data: AnyStruct, verifier: &FindForge.Verifier) : @NonFungibleToken.NFT {
            let info = data as? Info ?? panic("The data passed in is not in form as needed. Needed: ".concat(Type<Info>().identifier))

            // create a new NFT
            var newNFT <- create NFT(
                info: info,
            )

            GeneratedExperiences.totalSupply = GeneratedExperiences.totalSupply + 1
            emit Minted(id:newNFT.id, season: info.season, name: info.name, thumbnail: info.thumbnail.uri(), fullsize: info.fullsize.uri(), artist: info.artist, rarity: info.rarity, edition: info.edition, maxEdition: info.maxEdition)
            return <- newNFT
        }

        pub fun addContractData(platform: FindForge.MinterPlatform, data: AnyStruct, verifier: &FindForge.Verifier) {
            let collectionInfo = data as? CollectionInfo ?? panic("The data passed in is not in form as needed. Needed: ".concat(Type<CollectionInfo>().identifier))

            // We cannot send in royalties directly, therefore we have to send in FindPack Royalties and generate it during minting
            let arr : [MetadataViews.Royalty] = []
            for r in collectionInfo.royaltiesInput {
                // Try to get Token Switchboard
                var receiverCap = getAccount(r.recipient).getCapability<&{FungibleToken.Receiver}>(/public/GenericFTReceiver)
                // If it fails, try to get Find Profile
                if !receiverCap.check(){
                    receiverCap = getAccount(r.recipient).getCapability<&{FungibleToken.Receiver}>(/public/findProfileReceiver)
                }

                arr.append(MetadataViews.Royalty(recipient: receiverCap, cut: r.cut, description: r.description))
            }
            collectionInfo.setRoyalty(r: arr)

            GeneratedExperiences.collectionInfo[collectionInfo.season] = collectionInfo
            emit SeasonAdded(season:collectionInfo.season, squareImage: collectionInfo.squareImage.file.uri(), bannerImage: collectionInfo.bannerImage.file.uri())
        }
    }

    pub fun getForgeType() : Type {
        return Type<@Forge>()
    }

    init() {
        self.CollectionName = "GeneratedExperiences"
        // Initialize the total supply
        self.totalSupply = 0

        // Set the named paths
        self.CollectionStoragePath = StoragePath(identifier: self.CollectionName)!
        self.CollectionPrivatePath = PrivatePath(identifier: self.CollectionName)!
        self.CollectionPublicPath = PublicPath(identifier: self.CollectionName)!
        self.MinterStoragePath = StoragePath(identifier: self.CollectionName.concat("Minter"))!

        self.collectionInfo = {}

        // Create a Collection resource and save it to storage
        let collection <- create Collection()
        self.account.save(<-collection, to: self.CollectionStoragePath)

        // create a public capability for the collection
        self.account.link<&GeneratedExperiences.Collection{NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection}>(
            self.CollectionPublicPath,
            target: self.CollectionStoragePath
        )
        FindForge.addForgeType(<- create Forge())
        emit ContractInitialized()
    }
}



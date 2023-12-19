import NonFungibleToken from "./standard/NonFungibleToken.cdc"
import FungibleToken from "./standard/FungibleToken.cdc"
import MetadataViews from "./standard/MetadataViews.cdc"
import FindForge from "./FindForge.cdc"
import FindPack from "./FindPack.cdc"

access(all) contract GeneratedExperiences: NonFungibleToken {

    access(all) var totalSupply: UInt64

    access(all) event ContractInitialized()
    access(all) event Withdraw(id: UInt64, from: Address?)
    access(all) event Deposit(id: UInt64, to: Address?)
    access(all) event Minted(id:UInt64, season: UInt64, name: String, thumbnail: String, fullsize: String, artist: String, rarity: String, edition: UInt64, maxEdition: UInt64)
    access(all) event SeasonAdded(season:UInt64, squareImage: String, bannerImage: String)

    access(all) let CollectionStoragePath: StoragePath
    access(all) let CollectionPrivatePath: PrivatePath
    access(all) let CollectionPublicPath: PublicPath
    access(all) let MinterStoragePath: StoragePath

    access(all) let CollectionName : String

    // {Season : CollectionInfo}
    access(all) let collectionInfo: {UInt64 : CollectionInfo}

    access(all) struct CollectionInfo {
        access(all) let season: UInt64
        access(all) var royalties: [MetadataViews.Royalty]
        // This is only used internally for fetching royalties in
        access(all) let royaltiesInput: [FindPack.Royalty]
        access(all) let squareImage: MetadataViews.Media
        access(all) let bannerImage: MetadataViews.Media
        access(all) let description: String
        access(all) let socials: {String : String}
        access(all) let extra: {String: AnyStruct}

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

    access(all) struct Info {
        access(all) let season: UInt64
        access(all) let name: String
        access(all) let description: String
        access(all) let thumbnail: {MetadataViews.File}
        access(all) let fullsize: {MetadataViews.File}
        access(all) let edition: UInt64
        access(all) let maxEdition: UInt64
        access(all) let artist: String
        access(all) let rarity: String
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

    access(all) resource NFT: NonFungibleToken.INFT, ViewResolver.Resolver {
        access(all) let id: UInt64
        access(all) let info: Info

        init(
            info: Info
        ) {
            self.id = self.uuid
            self.info=info
        }

        access(all) getViews(): [Type] {
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

        access(all) resolveView(_ view: Type): AnyStruct? {

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
                    publicCollection: Type<&GeneratedExperiences.Collection{NonFungibleToken.Collection,NonFungibleToken.Receiver,ViewResolver.ResolverCollection}>(),
                    publicLinkedType: Type<&GeneratedExperiences.Collection{NonFungibleToken.Collection,NonFungibleToken.Receiver,ViewResolver.ResolverCollection}>(),
                    providerLinkedType: Type<&GeneratedExperiences.Collection{NonFungibleToken.Collection,NonFungibleToken.Provider,ViewResolver.ResolverCollection}>(),
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

    access(all) resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, ViewResolver.ResolverCollection {
        // dictionary of NFT conforming tokens
        // NFT is a resource type with an `UInt64` ID field
        access(all) var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        init () {
            self.ownedNFTs <- {}
        }

        // withdraw removes an NFT from the collection and moves it to the caller
        access(all) withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

            emit Withdraw(id: token.id, from: self.owner?.address)

            return <-token
        }

        // deposit takes a NFT and adds it to the collections dictionary
        // and adds the ID to the id array
        access(all) deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @GeneratedExperiences.NFT

            let id: UInt64 = token.id

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token

            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }

        // getIDs returns an array of the IDs that are in the collection
        access(all) getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        // borrowNFT gets a reference to an NFT in the collection
        // so that the caller can read its metadata and call its methods
        access(all) borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }

        access(all) borrowViewResolver(id: UInt64): &AnyResource{ViewResolver.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let ge = nft as! &GeneratedExperiences.NFT
            return ge as &AnyResource{ViewResolver.Resolver}
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    // public function that anyone can call to create a new empty collection
    access(all) createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    access(all) resource Forge: FindForge.Forge {
        access(all) mint(platform: FindForge.MinterPlatform, data: AnyStruct, verifier: &FindForge.Verifier) : @NonFungibleToken.NFT {
            let info = data as? Info ?? panic("The data passed in is not in form as needed. Needed: ".concat(Type<Info>().identifier))

            // create a new NFT
            var newNFT <- create NFT(
                info: info,
            )

            GeneratedExperiences.totalSupply = GeneratedExperiences.totalSupply + 1
            emit Minted(id:newNFT.id, season: info.season, name: info.name, thumbnail: info.thumbnail.uri(), fullsize: info.fullsize.uri(), artist: info.artist, rarity: info.rarity, edition: info.edition, maxEdition: info.maxEdition)
            return <- newNFT
        }

        access(all) addContractData(platform: FindForge.MinterPlatform, data: AnyStruct, verifier: &FindForge.Verifier) {
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

    access(all) getForgeType() : Type {
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
        self.account.storage.save(<-collection, to: self.CollectionStoragePath)

        // create a public capability for the collection
        self.account.link<&GeneratedExperiences.Collection{NonFungibleToken.Collection, ViewResolver.ResolverCollection}>(
            self.CollectionPublicPath,
            target: self.CollectionStoragePath
        )
        FindForge.addForgeType(<- create Forge())
        emit ContractInitialized()
    }
}



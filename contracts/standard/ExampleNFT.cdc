/*
*
*  This is an example implementation of a Flow Non-Fungible Token
*  It is not part of the official standard but it assumed to be
*  similar to how many NFTs would implement the core functionality.
*
*  This contract does not implement any sophisticated classification
*  system for its NFTs. It defines a simple NFT with minimal metadata.
*
*/

import "NonFungibleToken"
import "FungibleToken"
import "MetadataViews"
import "FindViews"
import "FindForge"
import "DapperUtilityCoin"
import "ViewResolver"


access(all) contract ExampleNFT: ViewResolver {

    access(all) var totalSupply: UInt64

    access(all) event ContractInitialized()

    access(all) let CollectionStoragePath: StoragePath
    access(all) let CollectionPublicPath: PublicPath

    access(all) let traits : {UInt64 : MetadataViews.Trait}

    access(all) struct ExampleNFTInfo {
        access(all) let name: String
        access(all) let description: String
        access(all) let soulBound: Bool
        access(all) let traits : [UInt64]
        access(all) let thumbnail: String

        init(name: String, description: String, soulBound: Bool, traits : [UInt64], thumbnail: String) {
            self.name=name
            self.description=description
            self.thumbnail=thumbnail
            self.traits=traits
            self.soulBound=soulBound
        }
    }


    access(all) resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver {
        access(all) let id: UInt64

        access(all) let name: String
        access(all) let description: String
        access(all) let thumbnail: String
        access(all) var soulBound: Bool
        // For testing
        access(all) let traits : [UInt64]
        access(self) let royalties: MetadataViews.Royalties

        access(all) var changedRoyalties: Bool

        init(
            id: UInt64,
            name: String,
            description: String,
            thumbnail: String,
            soulBound: Bool,
            traits : [UInt64],
            royalties: MetadataViews.Royalties
        ) {
            self.id = id
            self.name = name
            self.description = description
            self.thumbnail = thumbnail
            self.soulBound = soulBound
            self.royalties = royalties

            for traitId in traits {
                if !ExampleNFT.traits.containsKey(traitId) {
                    panic("This trait does not exist ID :".concat(traitId.toString()))
                }
            }
            self.traits=traits
            self.changedRoyalties = false
        }

        access(all) view fun getID(): UInt64 {
            return self.id
        }

        access(all) fun toggleSoulBound(_ status: Bool) {
            self.soulBound = status
        }

        access(all) fun changeRoyalties(_ bool: Bool) {
            self.changedRoyalties = bool
        }

        access(all) view fun getViews(): [Type] {
            var views = [
            Type<MetadataViews.Display>(),
            Type<MetadataViews.Royalties>(),
            Type<MetadataViews.Editions>(),
            Type<MetadataViews.ExternalURL>(),
            Type<MetadataViews.NFTCollectionData>(),
            Type<MetadataViews.NFTCollectionDisplay>(),
            Type<MetadataViews.Serial>(),
            Type<MetadataViews.Rarity>()
            ]

            if self.soulBound {
                views=views.concat([Type<FindViews.SoulBound>()])
            }

            return views
        }

        access(all) fun resolveView(_ view: Type): AnyStruct? {
            switch view {
            case Type<MetadataViews.Display>():
                return MetadataViews.Display(
                    name: self.name,
                    description: self.description,
                    thumbnail: MetadataViews.HTTPFile(
                        url: self.thumbnail
                    )
                )
            case Type<MetadataViews.Editions>():
                // There is no max number of NFTs that can be minted from this contract
                // so the max edition field value is set to nil
                let editionInfo = MetadataViews.Edition(name: "Example NFT Edition", number: self.id, max: nil)
                let editionList: [MetadataViews.Edition] = [editionInfo]
                return MetadataViews.Editions(
                    editionList
                )
            case Type<MetadataViews.Serial>():
                return MetadataViews.Serial(
                    self.id
                )
            case Type<MetadataViews.Royalties>():
                if !self.changedRoyalties {
                    return self.royalties
                }
                return MetadataViews.Royalties([
                MetadataViews.Royalty(receiver:ExampleNFT.account.capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)!, cut: 0.99, description: "cheater")
                ])
            case Type<MetadataViews.ExternalURL>():
                return MetadataViews.ExternalURL("https://example-nft.onflow.org/".concat(self.id.toString()))
            case Type<MetadataViews.NFTCollectionData>():
                return ExampleNFT.getCollectionData(nftType: Type<@ExampleNFT.NFT>())
            case Type<MetadataViews.NFTCollectionDisplay>():
                return ExampleNFT.getCollectionDisplay(nftType: Type<@ExampleNFT.NFT>())
            case Type<FindViews.SoulBound>() :
                if !self.soulBound {
                    return nil
                }
                return FindViews.SoulBound(
                    "This NFT is soulbound."
                )

            case Type<MetadataViews.Rarity>() :
                return MetadataViews.Rarity(score: 1.0, max: 2.0, description: "rarity description")

            }
            return nil
        }

        access(all) fun createEmptyCollection(): @{NonFungibleToken.Collection} {
            return <-ExampleNFT.createEmptyCollection()
        }
    }

    access(all) view fun getContractViews(resourceType: Type?): [Type] {
        return [
        Type<MetadataViews.NFTCollectionData>(),
        Type<MetadataViews.NFTCollectionDisplay>()
        ]
    }

    access(all) fun resolveContractView(resourceType: Type?, viewType: Type): AnyStruct? {
        switch viewType {
        case Type<MetadataViews.NFTCollectionData>():
            let collectionData = MetadataViews.NFTCollectionData(
                storagePath: ExampleNFT.CollectionStoragePath,
                publicPath: ExampleNFT.CollectionPublicPath,
                publicCollection: Type<&ExampleNFT.Collection>(),
                publicLinkedType: Type<&ExampleNFT.Collection>(),
                createEmptyCollectionFunction: (fun(): @{NonFungibleToken.Collection} {
                    return <-ExampleNFT.createEmptyCollection()
                })
            )
            return collectionData
        }
        return nil
    }

    access(all) resource Collection: NonFungibleToken.Collection, ViewResolver.ResolverCollection {
        /// dictionary of NFT conforming tokens
        /// NFT is a resource type with an `UInt64` ID field
        access(contract) var ownedNFTs: @{UInt64: ExampleNFT.NFT}

        access(self) var storagePath: StoragePath
        access(self) var publicPath: PublicPath

        /// Return the default storage path for the collection
        access(all) view fun getDefaultStoragePath(): StoragePath? {
            return self.storagePath
        }

        /// Return the default public path for the collection
        access(all) view fun getDefaultPublicPath(): PublicPath? {
            return self.publicPath
        }

        init () {
            self.ownedNFTs <- {}
            let identifier = "exampleNFTCollection"
            self.storagePath = StoragePath(identifier: identifier)!
            self.publicPath = PublicPath(identifier: identifier)!
        }

        /// getSupportedNFTTypes returns a list of NFT types that this receiver accepts
        access(all) view fun getSupportedNFTTypes(): {Type: Bool} {
            let supportedTypes: {Type: Bool} = {}
            supportedTypes[Type<@ExampleNFT.NFT>()] = true
            return supportedTypes
        }

        /// Returns whether or not the given type is accepted by the collection
        /// A collection that can accept any type should just return true by default
        access(all) view fun isSupportedNFTType(type: Type): Bool {
            if type == Type<@ExampleNFT.NFT>() {
                return true
            } else {
                return false
            }
        }

        /// withdraw removes an NFT from the collection and moves it to the caller
        access(NonFungibleToken.Withdraw | NonFungibleToken.Owner) fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT} {
            let token <- self.ownedNFTs.remove(key: withdrawID)
            ?? panic("Could not withdraw an NFT with the provided ID from the collection")

            return <-token
        }

        /// deposit takes a NFT and adds it to the collections dictionary
        /// and adds the ID to the id array
        access(all) fun deposit(token: @{NonFungibleToken.NFT}) {
            let token <- token as! @ExampleNFT.NFT

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[token.getID()] <- token

            destroy oldToken
        }

        /// getIDs returns an array of the IDs that are in the collection
        access(all) view fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        /// Gets the amount of NFTs stored in the collection
        access(all) view fun getLength(): Int {
            return self.ownedNFTs.keys.length
        }

        access(all) view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}? {
            return &self.ownedNFTs[id] 
        }

        /// Borrow the view resolver for the specified NFT ID
        access(all) view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}? {
            if let nft = &self.ownedNFTs[id] as &ExampleNFT.NFT? {
                return nft as &{ViewResolver.Resolver}
            }
            return nil
        }

        /// public function that anyone can call to create a new empty collection
        access(all) fun createEmptyCollection(): @{NonFungibleToken.Collection} {
            return <- create ExampleNFT.Collection()
        }
    }



    /// public function that anyone can call to create a new empty collection
    /// Since multiple collection types can be defined in a contract,
    /// The caller needs to specify which one they want to create
    access(all) fun createEmptyCollection(): @ExampleNFT.Collection {
        return <- create Collection()
    }


    /* Find Forge Specific code  */
    // mintNFT mints a new NFT with a new ID
    // and deposit it in the recipients collection using their collection reference
    access(all) fun mintNFT(
        name: String,
        description: String,
        thumbnail: String,
        soulBound: Bool ,
        traits: [UInt64] ,
        royalties: MetadataViews.Royalties
    ) : @{NonFungibleToken.NFT} {

        // create a new NFT
        var newNFT <- create NFT(
            id: ExampleNFT.totalSupply,
            name: name,
            description: description,
            thumbnail: thumbnail,
            soulBound: soulBound,
            traits: traits,
            royalties: royalties
        )

        ExampleNFT.totalSupply = ExampleNFT.totalSupply + 1 
        return <- newNFT
    }


    access(all) view fun getViews(): [Type] {
        return  [ Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>() ]
    }


    /// Function that resolves a metadata view for this contract.
    ///
    /// @param view: The Type of the desired view.
    /// @return A structure representing the requested view.
    ///
    access(all) fun resolveView(_ view: Type): AnyStruct? {
        switch view {
        case Type<MetadataViews.NFTCollectionData>():
            return ExampleNFT.getCollectionData(nftType: Type<@ExampleNFT.NFT>())
        case Type<MetadataViews.NFTCollectionDisplay>():
            return ExampleNFT.getCollectionDisplay(nftType: Type<@ExampleNFT.NFT>())
        }
        return nil
    }

    /// resolve a type to its CollectionData so you know where to store it
    /// Returns `nil` if no collection type exists for the specified NFT type
    access(all) view fun getCollectionData(nftType: Type): MetadataViews.NFTCollectionData? {
        switch nftType {
        case Type<@ExampleNFT.NFT>():
            let collectionData = MetadataViews.NFTCollectionData(
                storagePath: ExampleNFT.CollectionStoragePath,
                publicPath: ExampleNFT.CollectionPublicPath,
                publicCollection: Type<&ExampleNFT.Collection>(),
                publicLinkedType: Type<&ExampleNFT.Collection>(),
                createEmptyCollectionFunction: (fun(): @{NonFungibleToken.Collection} {
                    return <-ExampleNFT.createEmptyCollection()
                })
            )
            return collectionData
        default:
            return nil
        }
    }

    /// Returns the CollectionDisplay view for the NFT type that is specified
    access(all) view fun getCollectionDisplay(nftType: Type): MetadataViews.NFTCollectionDisplay? {
        switch nftType {
        case Type<@ExampleNFT.NFT>():
            let media = MetadataViews.Media(
                file: MetadataViews.HTTPFile(
                    url: "https://assets.website-files.com/5f6294c0c7a8cdd643b1c820/5f6294c0c7a8cda55cb1c936_Flow_Wordmark.svg"
                ),
                mediaType: "image/svg+xml"
            )
            return MetadataViews.NFTCollectionDisplay(
                name: "The Example Collection",
                description: "This collection is used as an example to help you develop your next Flow NFT.",
                externalURL: MetadataViews.ExternalURL("https://example-nft.onflow.org"),
                squareImage: media,
                bannerImage: media,
                socials: {
                    "twitter": MetadataViews.ExternalURL("https://twitter.com/flow_blockchain")
                }
            )
        default:
            return nil
        }
    }



    access(all)resource Forge: FindForge.Forge {
        access(FindForge.ForgeOwner) fun mint(platform: FindForge.MinterPlatform, data: AnyStruct, verifier: &FindForge.Verifier) : @{NonFungibleToken.NFT} {
            let info = data as? ExampleNFTInfo ?? panic("The data passed in is not in form of ExampleNFTInfo.")
            let royalties : [MetadataViews.Royalty] = []
            if platform.platformPercentCut != 0.0 {
                royalties.append(MetadataViews.Royalty(receiver:platform.platform, cut: platform.platformPercentCut, description: "find forge"))
            }
            if platform.minterCut != nil && platform.minterCut! != 0.0 {
                royalties.append(MetadataViews.Royalty(receiver:platform.getMinterFTReceiver(), cut: platform.minterCut!, description: "creator"))
            }
            return <- ExampleNFT.mintNFT(name: info.name,
            description: info.description,
            thumbnail: info.thumbnail,
            soulBound: info.soulBound,
            traits: info.traits,
            royalties: MetadataViews.Royalties(royalties))
        }

        access(FindForge.ForgeOwner) fun addContractData(platform: FindForge.MinterPlatform, data: AnyStruct, verifier: &FindForge.Verifier) {
            let type = data.getType()

            switch type {
            case Type<{UInt64 : MetadataViews.Trait}>() :
                // for duplicated indexes, the new one will replace the old one
                let typedData = data as! {UInt64 : MetadataViews.Trait}
                for key in typedData.keys {
                    ExampleNFT.traits[key] = ExampleNFT.traits[key] ?? typedData[key]
                }
                return

            }
        }
    }

    access(account) fun createForge() : @{FindForge.Forge} {
        return <- create Forge()
    }

    access(all) fun getForgeType() : Type {
        return Type<@Forge>()
    }

    init() {
        // Initialize the total supply
        self.totalSupply = 0

        // Set the named paths
        self.CollectionStoragePath = /storage/exampleNFTCollection
        self.CollectionPublicPath = /public/exampleNFTCollection

        self.traits={
            1 : MetadataViews.Trait(name: "head", value: "hat", displayType: "string", rarity: nil),
            2 : MetadataViews.Trait(name: "shoulder", value: "shoulder pad", displayType: "string", rarity: MetadataViews.Rarity(score: nil, max: nil, description: "Common")),
            3 : MetadataViews.Trait(name: "knees", value: "knee pad", displayType: "string", rarity: nil)
        }

        // Create a Collection resource and save it to storage
        let collection <- create Collection()
        self.account.storage.save(<-collection, to: self.CollectionStoragePath)

        // create a public capability for the collection
        let collectionCap = self.account.capabilities.storage.issue<&ExampleNFT.Collection>(self.CollectionStoragePath)
        self.account.capabilities.publish(collectionCap, at: self.CollectionPublicPath)

        FindForge.addForgeType(<- create Forge())

        FindForge.addPublicForgeType(forgeType: Type<@Forge>())
    }
}

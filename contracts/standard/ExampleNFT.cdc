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

import NonFungibleToken from "./NonFungibleToken.cdc"
import FungibleToken from "./FungibleToken.cdc"
import MetadataViews from "./MetadataViews.cdc"
import FindViews from "../FindViews.cdc"
import FindForge from "../FindForge.cdc"
import DapperUtilityCoin from "./DapperUtilityCoin.cdc"

pub contract ExampleNFT: NonFungibleToken {

    pub var totalSupply: UInt64

    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPrivatePath: PrivatePath
    pub let CollectionPublicPath: PublicPath
    pub let MinterStoragePath: StoragePath

    pub let traits : {UInt64 : MetadataViews.Trait}

    pub struct ExampleNFTInfo {
        pub let name: String
        pub let description: String
        pub let soulBound: Bool 
        pub let traits : [UInt64]
        pub let thumbnail: String

        init(name: String, description: String, soulBound: Bool, traits : [UInt64], thumbnail: String) {
            self.name=name 
            self.description=description 
            self.thumbnail=thumbnail 
            self.traits=traits
            self.soulBound=soulBound
        }
    }

    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        pub let id: UInt64

        pub let name: String
        pub let description: String
        pub let thumbnail: String
        pub var soulBound: Bool
        // For testing 
        pub let traits : [UInt64]
        access(self) let royalties: MetadataViews.Royalties

        pub var changedRoyalties: Bool

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

        pub fun toggleSoulBound(_ status: Bool) {
            self.soulBound = status
        }

        pub fun changeRoyalties() {
            self.changedRoyalties = !self.changedRoyalties
        }
    
        pub fun getViews(): [Type] {
            let views = [
                Type<MetadataViews.Display>(),
                Type<MetadataViews.Royalties>(),
                Type<MetadataViews.Editions>(),
                Type<MetadataViews.ExternalURL>(),
                Type<MetadataViews.NFTCollectionData>(),
                Type<MetadataViews.NFTCollectionDisplay>(),
                Type<MetadataViews.Serial>()
            ]

            if self.soulBound {
                views.append(Type<FindViews.SoulBound>())
            }

            return views
        }

        pub fun resolveView(_ view: Type): AnyStruct? {
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
                    } else {
                        return MetadataViews.Royalties([MetadataViews.Royalty(receiver:ExampleNFT.account.getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver), cut: 0.99, description: "cheater")])

                    }
                    

                case Type<MetadataViews.ExternalURL>():
                    return MetadataViews.ExternalURL("https://example-nft.onflow.org/".concat(self.id.toString()))
                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: ExampleNFT.CollectionStoragePath,
                        publicPath: ExampleNFT.CollectionPublicPath,
                        providerPath: /private/exampleNFTCollection,
                        publicCollection: Type<&ExampleNFT.Collection{ExampleNFT.ExampleNFTCollectionPublic}>(),
                        publicLinkedType: Type<&ExampleNFT.Collection{ExampleNFT.ExampleNFTCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
                        providerLinkedType: Type<&ExampleNFT.Collection{ExampleNFT.ExampleNFTCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
                        createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                            return <-ExampleNFT.createEmptyCollection()
                        })
                    )
                case Type<MetadataViews.NFTCollectionDisplay>():
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

                case Type<FindViews.SoulBound>() :
                    if !self.soulBound {
                        return nil
                    }
                    return FindViews.SoulBound(
                         "This NFT is soulbound."
                    )

            }
            return nil
        }
    }

    pub resource interface ExampleNFTCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowExampleNFT(id: UInt64): &ExampleNFT.NFT? {
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow ExampleNFT reference: the ID of the returned reference is incorrect"
            }
        }
    }

    pub resource Collection: ExampleNFTCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
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
            let token <- token as! @ExampleNFT.NFT

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
 
        pub fun borrowExampleNFT(id: UInt64): &ExampleNFT.NFT? {
            if self.ownedNFTs[id] != nil {
                // Create an authorized reference to allow downcasting
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &ExampleNFT.NFT
            }

            return nil
        }

        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let exampleNFT = nft as! &ExampleNFT.NFT
            return exampleNFT as &AnyResource{MetadataViews.Resolver}
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    // public function that anyone can call to create a new empty collection
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }


    /* Find Forge Specific code  */
    // mintNFT mints a new NFT with a new ID
    // and deposit it in the recipients collection using their collection reference
    access(account) fun mintNFT(
        name: String,
        description: String,
        thumbnail: String,
        soulBound: Bool ,
        traits: [UInt64] ,
        royalties: MetadataViews.Royalties
    ) : @NonFungibleToken.NFT
    {

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

        ExampleNFT.totalSupply = ExampleNFT.totalSupply + UInt64(1)
        return <- newNFT
    }

    pub resource Forge: FindForge.Forge {
		pub fun mint(platform: FindForge.MinterPlatform, data: AnyStruct, verifier: &FindForge.Verifier) : @NonFungibleToken.NFT {
			let info = data as? ExampleNFTInfo ?? panic("The data passed in is not in form of ExampleNFTInfo.")
            let royalties : [MetadataViews.Royalty] = []
            if platform.platformPercentCut! != 0.0 {
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

        pub fun addContractData(platform: FindForge.MinterPlatform, data: AnyStruct, verifier: &FindForge.Verifier) {
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

    pub fun getForgeType() : Type {
		return Type<@Forge>()
	}

    init() {
        // Initialize the total supply
        self.totalSupply = 0

        // Set the named paths
        self.CollectionStoragePath = /storage/exampleNFTCollection
        self.CollectionPrivatePath = /private/exampleNFTCollection
        self.CollectionPublicPath = /public/exampleNFTCollection
        self.MinterStoragePath = /storage/exampleNFTMinter

        self.traits={
            1 : MetadataViews.Trait(name: "head", value: "hat", displayType: "string", rarity: nil), 
            2 : MetadataViews.Trait(name: "shoulder", value: "shoulder pad", displayType: "string", rarity: MetadataViews.Rarity(score: nil, max: nil, description: "Common")), 
            3 : MetadataViews.Trait(name: "knees", value: "knee pad", displayType: "string", rarity: nil)
        }

        // Create a Collection resource and save it to storage
        let collection <- create Collection()
        self.account.save(<-collection, to: self.CollectionStoragePath)

        // create a public capability for the collection
        self.account.link<&ExampleNFT.Collection{NonFungibleToken.CollectionPublic, ExampleNFT.ExampleNFTCollectionPublic, MetadataViews.ResolverCollection}>(
            self.CollectionPublicPath,
            target: self.CollectionStoragePath
        )

        // create a private capability for the collection
        self.account.link<&ExampleNFT.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, ExampleNFT.ExampleNFTCollectionPublic, MetadataViews.ResolverCollection}>(
            self.CollectionPrivatePath,
            target: self.CollectionStoragePath
        )

		FindForge.addForgeType(<- create Forge())

		//TODO: Add the Forge resource aswell
		FindForge.addPublicForgeType(forgeType: Type<@Forge>())

        emit ContractInitialized()

        // Deposit exampleNFTs for testing
        let dapper = getAccount(ExampleNFT.account.address).getCapability<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)
        let minterCut = MetadataViews.Royalty(receiver:dapper , cut: 0.01, description: "creator")
        let royalties : [MetadataViews.Royalty] = []
        royalties.append(minterCut)
        let nft <- ExampleNFT.mintNFT(name: "DUCExampleNFT", description: "For testing listing in DUC", thumbnail: "https://images.ongaia.com/ipfs/QmZPxYTEx8E5cNy5SzXWDkJQg8j5C3bKV6v7csaowkovua/8a80d1575136ad37c85da5025a9fc3daaf960aeab44808cd3b00e430e0053463.jpg", soulBound: false,traits : [], royalties: MetadataViews.Royalties(royalties))
        let nft2 <- ExampleNFT.mintNFT(name: "SoulBoundNFT", description: "This is soulBound", thumbnail: "https://images.ongaia.com/ipfs/QmZPxYTEx8E5cNy5SzXWDkJQg8j5C3bKV6v7csaowkovua/8a80d1575136ad37c85da5025a9fc3daaf960aeab44808cd3b00e430e0053463.jpg", soulBound: true,traits : [1,2,3], royalties: MetadataViews.Royalties(royalties))

        ExampleNFT.account.borrow<&ExampleNFT.Collection>(from: self.CollectionStoragePath)!.deposit(token : <- nft)
        ExampleNFT.account.borrow<&ExampleNFT.Collection>(from: self.CollectionStoragePath)!.deposit(token : <- nft2)
    }
}
 
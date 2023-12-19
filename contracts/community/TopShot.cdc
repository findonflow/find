

import NonFungibleToken from "../standard/NonFungibleToken.cdc"
import MetadataViews from "../standard/MetadataViews.cdc"

pub contract TopShot: NonFungibleToken {

    // Emitted when the TopShot contract is created
    access(all) event ContractInitialized()
    //
    // Emitted when a moment is withdrawn from a Collection
    access(all) event Withdraw(id: UInt64, from: Address?)
    // Emitted when a moment is deposited into a Collection
    access(all) event Deposit(id: UInt64, to: Address?)
    access(all) var totalSupply: UInt64

    // The resource that represents the Moment NFTs
    //
    access(all) resource NFT: NonFungibleToken.INFT, ViewResolver.Resolver {

        // Global unique moment ID
        access(all) let id: UInt64

        init() {
            self.id = self.uuid
        }

        // All supported metadata views for the Moment including the Core NFT Views
        access(all) getViews(): [Type] {
            return [
                Type<MetadataViews.Display>(),
                Type<MetadataViews.Royalties>(),
                Type<MetadataViews.ExternalURL>(),
                Type<MetadataViews.NFTCollectionData>(),
                Type<MetadataViews.NFTCollectionDisplay>()
            ]
        }



        access(all) resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: "",
                        description: "",
                        thumbnail: MetadataViews.HTTPFile(url: "")
                    )
                case Type<MetadataViews.Royalties>():
                    return MetadataViews.Royalties(
                        royalties: [

                        ]
                    )
                case Type<MetadataViews.ExternalURL>():
                    return MetadataViews.ExternalURL("")
                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: /storage/MomentCollection,
                        access(all)licPath: /public/MomentCollection,
                        providerPath: /private/MomentCollection,
                        access(all)licCollection: Type<&TopShot.Collection{TopShot.MomentCollectionPublic}>(),
                        access(all)licLinkedType: Type<&TopShot.Collection{TopShot.MomentCollectionPublic,NonFungibleToken.Receiver,NonFungibleToken.Collection,ViewResolver.ResolverCollection}>(),
                        providerLinkedType: Type<&TopShot.Collection{NonFungibleToken.Provider,TopShot.MomentCollectionPublic,NonFungibleToken.Receiver,NonFungibleToken.Collection,ViewResolver.ResolverCollection}>(),
                        createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                            return <-TopShot.createEmptyCollection()
                        })
                    )
                case Type<MetadataViews.NFTCollectionDisplay>():
                    let bannerImage = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                            url: "https://nbatopshot.com/static/img/top-shot-logo-horizontal-white.svg"
                        ),
                        mediaType: "image/svg+xml"
                    )
                    let squareImage = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                            url: "https://nbatopshot.com/static/img/og/og.png"
                        ),
                        mediaType: "image/png"
                    )
                    return MetadataViews.NFTCollectionDisplay(
                        name: "NBA-Top-Shot",
                        description: "NBA Top Shot is your chance to own, sell, and trade official digital collectibles of the NBA and WNBA's greatest plays and players",
                        externalURL: MetadataViews.ExternalURL("https://nbatopshot.com"),
                        squareImage: squareImage,
                        bannerImage: bannerImage,
                        socials: {
                            "twitter": MetadataViews.ExternalURL("https://twitter.com/nbatopshot"),
                            "discord": MetadataViews.ExternalURL("https://discord.com/invite/nbatopshot"),
                            "instagram": MetadataViews.ExternalURL("https://www.instagram.com/nbatopshot")
                        }
                    )
            }

            return nil
        }
	}

    access(all) resource interface MomentCollectionPublic {
        access(all) deposit(token: @NonFungibleToken.NFT)
        access(all) getIDs(): [UInt64]
        access(all) borrowNFT(id: UInt64): &NonFungibleToken.NFT
        access(all) borrowMoment(id: UInt64): &TopShot.NFT? {
            // If the result isn't nil, the id of the returned reference
            // should be the same as the argument to the function
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow Moment reference: The ID of the returned reference is incorrect"
            }
        }
    }

    // Collection is a resource that every user who owns NFTs
    // will store in their account to manage their NFTS
    //
    access(all) resource Collection: MomentCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, ViewResolver.ResolverCollection {
        // Dictionary of Moment conforming tokens
        // NFT is a resource type with a UInt64 ID field
        access(all) var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        init() {
            self.ownedNFTs <- {}
        }

        // withdraw removes an Moment from the Collection and moves it to the caller
        //
        // Parameters: withdrawID: The ID of the NFT
        // that is to be removed from the Collection
        //
        // returns: @NonFungibleToken.NFT the token that was withdrawn
        access(all) withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {

            // Borrow nft and check if locked
            let nft = self.borrowNFT(id: withdrawID)

            // Remove the nft from the Collection
            let token <- self.ownedNFTs.remove(key: withdrawID)
                ?? panic("Cannot withdraw: Moment does not exist in the collection")

            emit Withdraw(id: token.id, from: self.owner?.address)

            // Return the withdrawn token
            return <-token
        }

        // deposit takes a Moment and adds it to the Collections dictionary
        //
        // Paramters: token: the NFT to be deposited in the collection
        //
        access(all) deposit(token: @NonFungibleToken.NFT) {

            // Cast the deposited token as a TopShot NFT to make sure
            // it is the correct type
            let token <- token as! @TopShot.NFT

            // Get the token's ID
            let id = token.id

            // Add the new token to the dictionary
            let oldToken <- self.ownedNFTs[id] <- token

            // Only emit a deposit event if the Collection
            // is in an account's storage
            if self.owner?.address != nil {
                emit Deposit(id: id, to: self.owner?.address)
            }

            // Destroy the empty old token that was "removed"
            destroy oldToken
        }

        // getIDs returns an array of the IDs that are in the Collection
        access(all) getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        // borrowNFT Returns a borrowed reference to a Moment in the Collection
        // so that the caller can read its ID
        //
        // Parameters: id: The ID of the NFT to get the reference for
        //
        // Returns: A reference to the NFT
        //
        // Note: This only allows the caller to read the ID of the NFT,
        // not any topshot specific data. Please use borrowMoment to
        // read Moment data.
        //
        access(all) borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }

        // borrowMoment returns a borrowed reference to a Moment
        // so that the caller can read data and call methods from it.
        // They can use this to read its setID, playID, serialNumber,
        // or any of the setData or Play data associated with it by
        // getting the setID or playID and reading those fields from
        // the smart contract.
        //
        // Parameters: id: The ID of the NFT to get the reference for
        //
        // Returns: A reference to the NFT
        access(all) borrowMoment(id: UInt64): &TopShot.NFT? {
            if self.ownedNFTs[id] != nil {
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &TopShot.NFT
            } else {
                return nil
            }
        }

        access(all) borrowViewResolver(id: UInt64): &AnyResource{ViewResolver.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let topShotNFT = nft as! &TopShot.NFT
            return topShotNFT as &AnyResource{ViewResolver.Resolver}
        }

        // If a transaction destroys the Collection object,
        // All the NFTs contained within are also destroyed!
        // Much like when Damian Lillard destroys the hopes and
        // dreams of the entire city of Houston.
        //
        destroy() {
            destroy self.ownedNFTs
        }
    }

	access(all) createEmptyCollection() : @NonFungibleToken.Collection {
		return <- create Collection()
	}

    init() {
        // Initialize contract fields
        self.totalSupply = 0

        // Put a new Collection in storage
        self.account.storage.save<@Collection>(<- create Collection(), to: /storage/MomentCollection)

        // Create a access(all)lic capability for the Collection
        self.account.link<&{MomentCollectionPublic}>(/public/MomentCollection, target: /storage/MomentCollection)

        emit ContractInitialized()
    }
}

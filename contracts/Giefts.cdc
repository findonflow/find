import "NonFungibleToken"
import "MetadataViews"
import "ViewResolver"

//                      ___  __
//        __          /'___\/\ \__
//    __ /\_\     __ /\ \__/\ \ ,_\   ____
//  /'_ `\/\ \  /'__`\ \ ,__\\ \ \/  /',__\
// /\ \L\ \ \ \/\  __/\ \ \_/ \ \ \_/\__, `\
// \ \____ \ \_\ \____\\ \_\   \ \__\/\____/
//  \/___L\ \/_/\/____/ \/_/    \/__/\/___/
//    /\____/
//    \_/__/
//
// Giefts - wrap NFT gifts in a box and send them to your friends.
// The gifts can be claimed by passing the correct password.
//
access(all)
contract Giefts{ 

    access(all) entitlement Owner
    /**/
    ///////////////////////////////////////////////////////////// 

    //							PATHS							//
    /////////////////////////////////////////////////////////////**/
    access(all)
    let GieftsStoragePath: StoragePath

    access(all)
    let GieftsPublicPath: PublicPath

    //							EVENTS						   //
    /////////////////////////////////////////////////////////////**/
    access(all)
    event Packed(gieft: UInt64, nfts: [UInt64])

    access(all)
    event Added(gieft: UInt64, nft: UInt64, type: String, name: String, thumbnail: String)

    access(all)
    event Removed(gieft: UInt64, nft: UInt64, type: String, name: String, thumbnail: String)

    access(all)
    event Claimed(
        gieft: UInt64,
        nft: UInt64,
        type: String,
        name: String,
        thumbnail: String,
        gifter: Address?,
        giftee: Address?
    ) /**/
    /////////////////////////////////////////////////////////////


    //						 INTERFACES						  //
    /////////////////////////////////////////////////////////////**/
    /// Gieft
    access(all)
    resource interface GieftPublic{ 
        access(all)
        let password: [UInt8]

        access(all)
        fun borrowClaimableNFT(): &{NonFungibleToken.NFT}?

        access(all)
        fun claimNft(
            password: String,
            collection: &{NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection}
        )

        access(all)
        fun getNftIDs(): [UInt64]
    }

    /// GieftCollection
    access(all)
    resource interface GieftCollectionPublic{ 
        access(all)
        fun borrowGieft(_ gieft: UInt64): &Giefts.Gieft?

        access(all)
        fun getGieftIDs(): [UInt64]
    }

    access(all)
    resource interface GieftCollectionPrivate{ 
        access(Owner)
        fun packGieft(
            name: String,
            password: [
            UInt8
            ],
            nfts: @{
                UInt64:{ NonFungibleToken.NFT}
            }
        ): Void

        access(Owner)
        fun addNftToGieft(gieft: UInt64, nft: @{NonFungibleToken.NFT})

        access(Owner)
        fun unpackGieft(gieft: UInt64): @{UInt64:{ NonFungibleToken.NFT}}
    } /**/
    /////////////////////////////////////////////////////////////


    //						 RESOURCES						   //
    /////////////////////////////////////////////////////////////**/
    /// Gieft
    /// A collection of NFTs that can be claimed by passing the correct password
    access(all)
    resource Gieft: GieftPublic{ 
        ///  The name of the gieft
        access(all)
        let name: String

        /// A collection of NFTs
        /// nfts are stored as a map of uuids to NFTs
        access(contract)
        var nfts: @{UInt64:{ NonFungibleToken.NFT}}

        /// The hashed password to claim an nft
        access(all)
        let password: [UInt8]

        /// add an NFT to the gieft
        access(contract)
        fun addNft(nft: @{NonFungibleToken.NFT}){ 
            pre{ 
                !self.nfts.keys.contains(nft.uuid):
                "NFT uuid already added"
            }
            let display: MetadataViews.Display = nft.resolveView(Type<MetadataViews.Display>())! as! MetadataViews.Display
            emit Added(gieft: self.uuid, nft: nft.uuid, type: nft.getType().identifier, name: display.name, thumbnail: display.thumbnail.uri())
            let oldNft <- self.nfts[nft.uuid] <- nft
            destroy oldNft
        }

        /// borrwClaimableNFT
        /// get a reference to the first NFT that can be claimed
        /// @returns the first NFT that can be claimed
        access(all)
        fun borrowClaimableNFT(): &{NonFungibleToken.NFT}?{ 
            if self.nfts.length > 0{ 
                return &self.nfts[self.nfts.keys[0]]
            } else{ 
                return nil
            }
        }

        /// claim an NFT from the gieft
        /// @params password: the password to claim the NFT
        access(all)
        fun claimNft(password: String, collection: &{NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection}){ 
            pre{ 
                self.password == HashAlgorithm.KECCAK_256.hash(password.utf8):
                "Incorrect password"
                self.nfts.length > 0:
                "No NFTs to claim"
            }
            let nft <- self.nfts.remove(key: self.nfts.keys[0])!
            let display: MetadataViews.Display = nft.resolveView(Type<MetadataViews.Display>())! as! MetadataViews.Display
            emit Claimed(gieft: self.uuid, nft: nft.uuid, type: nft.getType().identifier, name: display.name, thumbnail: display.thumbnail.uri(), gifter: self.owner?.address, giftee: collection.owner?.address)
            collection.deposit(token: <-nft)
        }

        /// unpack, a function to unpack an NFT from the gieft, this function is only callable by the owner
        /// @params nft: the uuid of the NFT to claim
        access(contract)
        fun unpack(nft: UInt64): @{NonFungibleToken.NFT}{ 
            pre{ 
                self.nfts.keys.contains(nft):
                "NFT does not exist"
            }
            let nft <- self.nfts.remove(key: nft)!
            let display: MetadataViews.Display = nft.resolveView(Type<MetadataViews.Display>())! as! MetadataViews.Display
            emit Removed(gieft: self.uuid, nft: nft.uuid, type: nft.getType().identifier, name: display.name, thumbnail: display.thumbnail.uri())
            return <-nft
        }

        /// get all NFT ids
        access(all)
        fun getNftIDs(): [UInt64]{ 
            return self.nfts.keys
        }

        init(name: String, password: [UInt8], nfts: @{UInt64:{ NonFungibleToken.NFT}}){ 
            self.name = name
            self.nfts <- nfts
            self.password = password
            emit Packed(gieft: self.uuid, nfts: self.nfts.keys)
        }
    }

    /// GieftCollection
    /// A collection of giefts
    access(all)
    resource GieftCollection: GieftCollectionPublic, GieftCollectionPrivate{ 
        /// a collection of giefts
        access(all)
        var giefts: @{UInt64: Gieft}

        /// create a new gieft
        /// @params password: the hashed password to claim an NFT from the Gieft
        /// @params nfts: the NFTs to add to the gieft
        access(Owner)
        fun packGieft(name: String, password: [UInt8], nfts: @{UInt64:{ NonFungibleToken.NFT}}){ 
            let gieft <- create Gieft(name: name, password: password, nfts: <-nfts)
            let oldGieft <- self.giefts[gieft.uuid] <- gieft
            destroy oldGieft
        }

        /// add an NFT to a gieft
        /// @params gieft: the uuid of the gieft to add the NFT to
        /// @params nft: the NFT to add to the gieft
        access(Owner)
        fun addNftToGieft(gieft: UInt64, nft: @{NonFungibleToken.NFT}){ 
            pre{ 
                self.giefts.keys.contains(gieft):
                "Gieft does not exist"
            }
            (self.borrowGieft(gieft)!).addNft(nft: <-nft)
        }

        /// unpack a gieft
        /// @params gieft: the uuid of the gieft to unpack
        access(Owner)
        fun unpackGieft(gieft: UInt64): @{UInt64:{ NonFungibleToken.NFT}}{ 
            pre{ 
                self.giefts.keys.contains(gieft):
                "Gieft does not exist"
            }
            var nfts: @{UInt64:{ NonFungibleToken.NFT}} <-{} 
            let gieft = self.borrowGieft(gieft)!
            let nftIDs = gieft.getNftIDs()
            for nftID in nftIDs{ 
                let nft <- gieft.unpack(nft: nftID)
                let oldNft <- nfts[nftID] <- nft
                destroy oldNft
            }
            return <-nfts
        }

        /// borrow a gieft reference
        /// @params gieft: the uuid of the gieft to borrow
        access(all)
        fun borrowGieft(_ gieft: UInt64): &Gieft?{ 
            return &self.giefts[gieft] 
        }

        /// get all gieft ids
        access(all)
        fun getGieftIDs(): [UInt64]{ 
            return self.giefts.keys
        }

        init(){ 
            self.giefts <-{} 
        }
    } /**/
    /////////////////////////////////////////////////////////////


    //						 FUNCTIONS						   //
    /////////////////////////////////////////////////////////////**/
    /// create a new gieft collection resource
    access(all)
    fun createGieftCollection(): @GieftCollection{ 
        return <-create GieftCollection()
    }

    init(){ 
        /// paths
        self.GieftsStoragePath = /storage/Giefts
        self.GieftsPublicPath = /public/Giefts
    }
}


Testing Names :
`bjartek`
`knowbean`
`werekitty`

`getNameSearchbar`
This is used for search bar

```json
arg :
"name" : String
```

```json
result:{
    "avatar": "https://flovatar.com/api/image/95",
    "cost": 5,
    "lockedUntil": 1710107414,
    "owner": "0x886f3aeaf848c535",
    "registeredTime": 1639259414,
    "status": "TAKEN",
    "validUntil": 1702331414
}
```

getStatus is split into 3 scripts.
The basic concept is that all these scripts combines to make getStatus.
But they are also showing in different tabs.
Therefore there is flexibility wherether or not fetching other 2 when you are on profile page.

getFindStatus fetches all information needed on Profile Page
`getFindStatus`
```json
arg :
"user" : String (find name or Address)
```

```json
result:{
    "accounts": [
        {
            "address": "0xab12a4d330af34e9",
            "name": "dapper",
            "network": "Flow",
            "node": "EmeraldID",
            "trusted": true
        }
    ],
    "activatedAccount": true,
    "hasLostAndFoundItem": false,
    "isDapper": false,
    "paths": [
        "findSender",
        "A_097bafa4e0b48eef_FindMarketDirectOfferEscrow_MarketBidCollection_find",
        "MatrixMarketOpenOffer",
        "caaPassCollection",
        "flowTokenHolder",
        "neoVoucherCollection",
        "FLOATCollectionStoragePath",
        "A_097bafa4e0b48eef_FindLeaseMarketDirectOfferSoft_SaleItemCollection_findLease",
        "NFTStorefront",
        "GeeftCollection",
        "USDCVault",
        "SolarpupsMarketStoreProd01",
        "motogpPackCollection",
        "CricketMomentsCollection",
        "starlyTokenVault",
        "CraveCollection001",
        "neoFounderCollection",
        "BeamCollection001",
        "FlowtyStorefront",
        "CNN_NFTCollection",
        "BitkuCollection",
        "stakedStarlyCardCollection",
        "ZeedzINOCollection",
        "flomiesNFT",
        "teleportedTetherTokenVault",
        "starlyTokenVestingCollection",
        "A_097bafa4e0b48eef_FindMarketAuctionEscrow_MarketBidCollection_find",
        "A_097bafa4e0b48eef_FindMarketAuctionSoft_MarketBidCollection_find",
        "FLOATEventsStoragePath",
        "FlowtyRentalsStorefront",
        "bloctoXtinglesCollectibleCollection",
        "GrantedAccountAccessInfo",
        "DayNFTCollection",
        "FlovatarMarketplace",
        "fusdVault",
        "PartyMansionDrinkCollection",
        "SoulMadeComponentCollection",
        "A_097bafa4e0b48eef_FindMarketAuctionEscrow_SaleItemCollection_find",
        "bloctoPassCollection",
        "KlktnNFTCollection",
        "FindThoughts",
        "EverbloomCollection",
        "MatrixMarketFlowverseSocksCollection",
        "VersusUserProfile",
        "geniVault",
        "MomentCollection",
        "NyatheesOVOCollection",
        "MynftCollection",
        "bloctoTokenVault",
        "BlindBoxRedeemVoucherCollection",
        "wearables",
        "SolarpupsNFTsProd01",
        "GoatCollection",
        "RCRDSHPNFTCollection",
        "BarterYardClubWerewolfCollection",
        "neoMemberCollection",
        "chainmonstersRewardsMarketCollection",
        "GooberzPartyFolksCollection",
        "A_097bafa4e0b48eef_FindLeaseMarketSale_SaleItemCollection_findLease",
        "FindPackCollection",
        "RareRooms_NFTCollection",
        "flowUsdtFspLpVault",
        "findLeases",
        "findProfile",
        "BarterYardPackNFTCollection",
        "stakingCollection",
        "neoStickerCollection",
        "nftCatalogProposalManager",
        "ChainmonstersRewardCollection",
        "starlyCardCollection",
        "neoAvatarCollection",
        "GoatTraitCollection",
        "GoatTraitsPackVoucherCollection",
        "A_097bafa4e0b48eef_FindLeaseMarketDirectOfferSoft_MarketBidCollection_findLease",
        "A_097bafa4e0b48eef_FindMarketDirectOfferEscrow_SaleItemCollection_find",
        "jambbLaunchVouchersCollection",
        "MomentablesCollection",
        "GoatedGoatsVoucherCollection",
        "FindCuratedCollections",
        "MatrixWorldFlowFestNFTCollection",
        "DOFCollectionStoragePath",
        "MatrixWorldVoucherCollection",
        "userCertificate_increment",
        "A_097bafa4e0b48eef_FindMarketDirectOfferSoft_SaleItemCollection_find",
        "Bl0xPackCollection",
        "NFTStorefrontV2",
        "somePlaceCollectibleCollection",
        "FlovatarCollection",
        "CryptoPiggoCollection",
        "motogpCardCollection",
        "SoulMadePackCollection",
        "FlobotCollection",
        "A_097bafa4e0b48eef_FindMarketSale_SaleItemCollection_find",
        "flowTokenVault",
        "A_097bafa4e0b48eef_FindMarketAuctionSoft_SaleItemCollection_find",
        "AshesCollection",
        "BlockleteGames_NFTCollection",
        "A_097bafa4e0b48eef_FindLeaseMarketAuctionSoft_SaleItemCollection_findLease",
        "starlyCardMarketCollection",
        "bl0xNFTs",
        "SoulMadeMainCollection",
        "FlovatarPackCollection",
        "findDandy",
        "SchmoesPreLaunchTokenCollection",
        "FabricantCollection001",
        "MintixCollection",
        "RaceDay_NFTCollection",
        "GoatTraitPackCollection",
        "NiftoryCollectibleCollection",
        "findCharityCollection",
        "nfgNFTCollection",
        "jambbMomentsCollection",
        "SolarpupsMarketAdminProd01",
        "revvVault",
        "A_097bafa4e0b48eef_FindMarketDirectOfferSoft_MarketBidCollection_find",
        "versusArtMarketplace",
        "GaiaCollection001",
        "TuneGOCollection",
        "MatrixMarketCollection",
        "FlovatarComponentCollection",
        "fnsDomainCollection",
        "increment_stakingUserCertificate",
        "FlowverseTreasuresCollection",
        "A_097bafa4e0b48eef_FindLeaseMarketAuctionSoft_MarketBidCollection_findLease",
        "MintStoreItemCollection",
        "GeniaceNFTCollection",
        "EternalShardCollection",
        "sportsIconCollectibleCollection",
        "PartyFavorzCollection",
        "increment_swap_lptoken_collection",
        "EmeraldBotVerifierCollection01",
        "versusArtCollection",
        "findBids",
        "ZayTraderCollectionV2",
        "FlowversePassCollection",
        "starlyTokenStakingCollection"
    ],
    "privateMode": false,
    "profile": {
        "address": "0x886f3aeaf848c535",
        "allowStoringFollowers": true,
        "avatar": "https://flovatar.com/api/image/95",
        "createdAt": "find",
        "description": "creator of .find, co-owner of versus. #SODA father. Co-author of metadata flow flip. OnFlow Community Rep. Service-Account signer.",
        "findName": "bjartek",
        "followers": [
            {
                "follower": "0xdec5369b36230285",
                "following": "0x886f3aeaf848c535"
            },
            {
                "follower": "0x904950755ad051aa",
                "following": "0x886f3aeaf848c535"
            },
            {
                "follower": "0x73e4a1094d0bcab6",
                "following": "0x886f3aeaf848c535"
            },
            {
                "follower": "0x607bc51c3827f4d1",
                "following": "0x886f3aeaf848c535"
            },
            {
                "follower": "0xcd642845e5f48fdd",
                "following": "0x886f3aeaf848c535"
            },
            {
                "follower": "0x256d1a77cb25675e",
                "following": "0x886f3aeaf848c535"
            },
            {
                "follower": "0x55ed5c8cd375bcae",
                "following": "0x886f3aeaf848c535"
            },
            {
                "follower": "0xf4c99941cd3ae3d5",
                "following": "0x886f3aeaf848c535"
            },
            {
                "follower": "0x41758a9bc5664169",
                "following": "0x886f3aeaf848c535"
            }
        ],
        "following": [
            {
                "follower": "0x886f3aeaf848c535",
                "following": "0xdec5369b36230285"
            }
        ],
        "links": {
            "Homepage": {
                "title": "Homepage",
                "type": "globe",
                "url": "https://bjartek.org"
            },
            "Twitter": {
                "title": "Twitter",
                "type": "twitter",
                "url": "https://twitter.com/0xBjartek"
            }
        },
        "name": "bjartek",
        "tags": [
            "find",
            "versus",
            "overflow",
            "flovatar-maxi",
            "neo-team-8"
        ],
        "wallets": [
            {
                "accept": "A.3c5959b568896393.FUSD.Vault",
                "balance": 52.0999999,
                "name": "FUSD",
                "tags": [
                    "fusd",
                    "stablecoin"
                ]
            },
            {
                "accept": "A.1654653399040a61.FlowToken.Vault",
                "balance": 381.76236318,
                "name": "Flow",
                "tags": [
                    "flow"
                ]
            },
            {
                "accept": "A.b19436aae4d94622.FiatToken.Vault",
                "balance": 0,
                "name": "USDC",
                "tags": [
                    "usdc",
                    "stablecoin"
                ]
            }
        ]
    },
    "readyForWearables": true
}
```


getFindMarket returns all find market listings / bids and all leases information.
It is necessary for "names" and "market" tab.
`getFindMarket`

```json
arg :
"user" : String (find name or Address)
```

```json
result:{
    "itemsForSale": {
        "FindMarketSale": {
            "items": [
                {
                    "amount": 42,
                    "ftAlias": "Flow",
                    "ftTypeIdentifier": "A.1654653399040a61.FlowToken.Vault",
                    "listingId": 208476070,
                    "listingStatus": "active",
                    "listingTypeIdentifier": "A.097bafa4e0b48eef.FindMarketSale.SaleItem",
                    "nft": {
                        "collectionDescription": "Minting a Bl0x triggers the catalyst moment of a big bang scenario. Generating a treasure that is designed to relate specifically to its holder.",
                        "collectionName": "bl0x",
                        "id": 208476070,
                        "name": "Bl0x Season1 #214",
                        "rarity": "Epic",
                        "scalars": {
                            "uuid": 208476070
                        },
                        "tags": {
                            "Artifact": "Empty",
                            "Artifact_rarity": "Common",
                            "Background": "Cubes Variant 2",
                            "Background_rarity": "Common",
                            "Border": "Star Glitter Purple",
                            "Border_rarity": "Uncommon",
                            "Cube Backing": "Cube Backing",
                            "Cube Backing_rarity": "Common",
                            "Cube Filling": "Pi Green",
                            "Cube Filling_rarity": "Uncommon",
                            "Edition Stamp": "Grand Architect",
                            "Edition Stamp_rarity": "Common",
                            "Grid": "Bit Grid Purple",
                            "Grid_rarity": "Uncommon",
                            "Sigil 1": "Empty",
                            "Sigil 1_rarity": "Common",
                            "Sigil 2": "Empty",
                            "Sigil 2_rarity": "Common",
                            "Sigil 3": "Abundant Resource",
                            "Sigil 3_rarity": "Epic",
                            "Sigil 4": "Etheric Communication",
                            "Sigil 4_rarity": "Rare",
                            "Sigil 5": "Empty",
                            "Sigil 5_rarity": "Common",
                            "Sigil 6": "Empty",
                            "Sigil 6_rarity": "Common",
                            "Sigil 7": "Empty",
                            "Sigil 7_rarity": "Common",
                            "Sigil 8": "Personal Transformations",
                            "Sigil 8_rarity": "Rare",
                            "Sigil 9": "Peaceful Surrender",
                            "Sigil 9_rarity": "Rare",
                            "Sphere": "Colored God Cube",
                            "Sphere Backing": "Sphere Backing",
                            "Sphere Backing_rarity": "Common",
                            "Sphere_rarity": "Rare",
                            "external_url": "https://find.xyz/0x886f3aeaf848c535/collection/bl0x/208476070"
                        },
                        "thumbnail": "ipfs://QmPsZPAkG8JtDHqvRHZNopRm13ucUEJUac1hggeM18GuuF/thumbnail/214.webp",
                        "type": "A.7620acf6d7f2468a.Bl0x.NFT"
                    },
                    "nftId": 208476070,
                    "nftIdentifier": "A.7620acf6d7f2468a.Bl0x.NFT",
                    "saleType": "active_listed",
                    "seller": "0x886f3aeaf848c535",
                    "sellerName": "bjartek"
                },
                {
                    "amount": 420,
                    "ftAlias": "Flow",
                    "ftTypeIdentifier": "A.1654653399040a61.FlowToken.Vault",
                    "listingId": 160579374,
                    "listingStatus": "active",
                    "listingTypeIdentifier": "A.097bafa4e0b48eef.FindMarketSale.SaleItem",
                    "nft": {
                        "collectionDescription": "Welcome to The Crypto Pharaohs World, a world of magic, wonder, and fantasy where you can collect artworks, comics, and digital collectables including Crytpo Pharaohs, Pharaoh Cats, Pharaoh Names, and much more. As your journey unfolds, you'll help shape the roadmap, unlock special perks, earn rewards, and make the world a better place.",
                        "collectionName": "Crypto Pharaohs",
                        "id": 108,
                        "name": "Masud",
                        "scalars": {
                            "serial_number": 108,
                            "uuid": 160579374
                        },
                        "tags": {
                            "external_url": "https://www.momentable.ai/108"
                        },
                        "thumbnail": "https://ik.imagekit.io/jxb3nwqfm/tr:w-600,h-600/QmP8fv8KXhvDCqTtpg6GcBCFYFgXn121HY2vkvLXBav5yE",
                        "type": "A.9d21537544d9123d.Momentables.NFT"
                    },
                    "nftId": 108,
                    "nftIdentifier": "A.9d21537544d9123d.Momentables.NFT",
                    "saleType": "active_listed",
                    "seller": "0x886f3aeaf848c535",
                    "sellerName": "bjartek"
                }
            ]
        }
    },
    "leases": [
        {
            "address": "0x886f3aeaf848c535",
            "cost": 5,
            "currentTime": 1679402553,
            "extensionOnLateBid": 300,
            "lockedUntil": 1714507819,
            "name": "benno",
            "status": "TAKEN",
            "validUntil": 1706731819
        }
    ]
}
```


getFindLeaseMarket fetches all the Lease listings / bids ONLY FOR DAPPER Wallets.
```json
arg :
"user"
```

(This is fetched from testnet user "bobs")
```json
result:{
    "leasesForSale": {
        "FindLeaseMarketSale": {
            "items": [
                {
                    "amount": 999,
                    "ftAlias": "DUC",
                    "ftTypeIdentifier": "A.82ec283f88a62e65.DapperUtilityCoin.Vault",
                    "lease": {
                        "address": "0x9e84378a8fca8999",
                        "cost": 100,
                        "lockedUntil": 1717411542,
                        "name": "l33t",
                        "status": "TAKEN",
                        "validUntil": 1709635542
                    },
                    "leaseIdentifier": "A.35717efbbce11c74.FIND.Lease",
                    "leaseName": "l33t",
                    "listingId": 137687750,
                    "listingStatus": "active",
                    "listingTypeIdentifier": "A.35717efbbce11c74.FindLeaseMarketSale.SaleItem",
                    "listingValidUntil": 1709635542,
                    "market": "FindLeaseMarket",
                    "saleType": "active_listed",
                    "seller": "0x9e84378a8fca8999",
                    "sellerName": "testerick"
                },
                {
                    "amount": 555,
                    "ftAlias": "DUC",
                    "ftTypeIdentifier": "A.82ec283f88a62e65.DapperUtilityCoin.Vault",
                    "lease": {
                        "address": "0x9e84378a8fca8999",
                        "cost": 100,
                        "lockedUntil": 1717151445,
                        "name": "bobs",
                        "status": "TAKEN",
                        "validUntil": 1709375445
                    },
                    "leaseIdentifier": "A.35717efbbce11c74.FIND.Lease",
                    "leaseName": "bobs",
                    "listingId": 137286811,
                    "listingStatus": "active",
                    "listingTypeIdentifier": "A.35717efbbce11c74.FindLeaseMarketSale.SaleItem",
                    "listingValidUntil": 1709375445,
                    "market": "FindLeaseMarket",
                    "saleType": "active_listed",
                    "seller": "0x9e84378a8fca8999",
                    "sellerName": "testerick"
                }
            ]
        }
    }
}
```


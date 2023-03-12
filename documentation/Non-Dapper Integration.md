# Introduction

FIND was built on Flow Blockchain that makes it easy for developers to interact with FIND services on Flow Blockchain.

These docs describe how to use the [FIND](https://find.xyz) Services as a cadence developer. We hope you enjoy these docs, and please don't hesitate to [file an issue](https://github.com/findonflow/find/issues) if you see anything missing.

# Use Cases
- Name Service
- Marketplace
- Profile
- Find Thoughts
- Assets Browsing

# Name Service

## Lookup Name

[resolve.cdc](scripts/resolve.cdc)
```cadence
pub fun main(name:String) : Address?
```

| Parameter | Type | Description |
| :--- | :--- | :--- |
| `name` | `string` | .find Name / string address to be resolved as address |

```javascript
{
  "0xAddress"
}
```

The `0xAddress` attribute would be the address to the .find name if it is owned, or an address if it is a valid string address.

## Lookup Address

[reverseLookup.cdc](scripts/reverseLookup.cdc)
```cadence
pub fun main(input: Address) : String?
```

| Parameter | Type | Description |
| :--- | :--- | :--- |
| `input` | `string` |  address to be resolved as .find name |

```javascript
{
  ".find name"
}
```

The `.find name` attribute would be the main .find name of the address to be looked-up.

## Register Name
[register.cdc](transactions/register.cdc)
```cadence
transaction(
	name: String,
	amount: UFix64
	)

```

| Parameter | Type | Description |
| :--- | :--- | :--- |
| `name` | `string` | .find name to be registered |
| `amount` | `ufix64` | amount paid by signer |
| remark |  | 3 characters : 500 FUSD |
|  |  | 4 characters : 100 FUSD |
|  |  | 5 characters or above : 5 FUSD |

## Renew / Extend Name
[renewName.cdc](transactions/renewName.cdc)
```cadence
transaction(
	name: String,
	amount: UFix64
	)

```

| Parameter | Type | Description |
| :--- | :--- | :--- |
| `name` | `string` | .find name to be registered |
| `amount` | `ufix64` | amount paid by signer |
| remark |  | 3 characters : 500 FUSD |
|  |  | 4 characters : 100 FUSD |
|  |  | 5 characters or above : 5 FUSD |

# NFT Marketplace

## Sale : List NFT - sign by Seller
[listNFTForSale.cdc](transactions/listNFTForSale.cdc)

```cadence
transaction(
	nftAliasOrIdentifier: String,
	// This is the ID of the NFT (NOT UUID)
	id: UInt64,
	ftAliasOrIdentifier: String,
	directSellPrice:UFix64,
	validUntil: UFix64?
	)

```

| Parameter | Type | Description |
| :--- | :--- | :--- |
| `nftAliasOrIdentifier` | `String` | NFT resource identifier to be listed e.g. `A.CONTRACT_ADDRESS.CONTRACT_NAME.NFT`|
| `id` | `UInt64` | The ID of the NFT (NOT UUID) |
| `ftAliasOrIdentifier` | `String` | Fungible Token Vault identifier to be listed in |
| `directSellPrice` | `UFix64` | Price to be listed |
| `validUntil` | `UFix64?` | Optional expiration time for the listing |

## Sale : Buy NFT - sign by Buyer
[buyNFTForSale.cdc](transactions/buyNFTForSale.cdc)

```cadence
transaction(
	user: String,
	// This is the UUID of the NFT
	// Because we do not send in types here, id has to be unique for the listing
	id: UInt64,
	amount: UFix64
	)

```

| Parameter | Type | Description |
| :--- | :--- | :--- |
| `user` | `String` | string address or .find name to the user |
| `id` | `UInt64` | The `UUID` of the NFT  |
| `amount` | `UFix64` | Amount to be paid (transaction will assert the amount paid, this is here to ensure user acknowledge the amount paying) |

## Sale : Cancel NFT Sale - sign by Seller
[delistNFTSale.cdc](transactions/delistNFTSale.cdc)

```cadence
transaction(
	ids: [UInt64],
	)

```

| Parameter | Type | Description |
| :--- | :--- | :--- |
| `ids` | `[UInt64]]` | The `UUID`s of the NFT to be delisted |

## Auction : List for Auction - sign by Seller
[listNFTForAuctionEscrow.cdc](transactions/listNFTForAuctionEscrow.cdc)

```cadence
transaction(
	nftAliasOrIdentifier:String,
	id: UInt64,
	ftAliasOrIdentifier:String,
	price:UFix64,
	auctionReservePrice: UFix64,
	auctionDuration: UFix64,
	auctionExtensionOnLateBid: UFix64,
	minimumBidIncrement: UFix64,
	auctionValidUntil: UFix64?
	)
```

| Parameter | Type | Description |
| :--- | :--- | :--- |
| `nftAliasOrIdentifier` | `String` | NFT resource identifier to be listed e.g. `A.CONTRACT_ADDRESS.CONTRACT_NAME.NFT`|
| `id` | `UInt64` | The ID of the NFT (NOT UUID) |
| `ftAliasOrIdentifier` | `String` | Fungible Token Vault identifier to be listed in |
| `price` | `UFix64` | Price to be listed at start of auction |
| `auctionReservePrice` | `UFix64` | Auction ends below this price would be regarded as not fulfilled auction |
| `auctionDuration` | `UFix64` | Duration of auction in unix timestamp |
| `auctionExtensionOnLateBid` | `UFix64` | Extension of duration of auction in unix timestamp for latest bid |
| `minimumBidIncrement` | `UFix64` | Minimum bid increment |
| `auctionValidUntil` | `UFix64?` | Optional expiration time for the listing |

## Auction : Bid for Auction - sign by Buyer
[bidMarketAuctionEscrowed.cdc](transactions/bidMarketAuctionEscrowed.cdc)

```cadence
transaction(
	user: String,
	id: UInt64,
	amount: UFix64
	)

```

| Parameter | Type | Description |
| :--- | :--- | :--- |
| `user` | `String` | string address or .find name to the user |
| `id` | `UInt64` | The `UUID` of the NFT  |
| `amount` | `UFix64` | Amount to be escrowed for bid |

## Auction : Increase Bid for Auction - sign by Buyer
[increaseBidMarketAuctionEscrowed.cdc](transactions/increaseBidMarketAuctionEscrowed.cdc)

```cadence
transaction(
	id: UInt64,
	amount: UFix64
	)

```

| Parameter | Type | Description |
| :--- | :--- | :--- |
| `id` | `UInt64` | The `UUID` of the NFT  |
| `amount` | `UFix64` | Increment amount to be added to bid |

## Auction : Fulfill Auction - sign by Buyer
[fulfillMarketAuctionEscrowed.cdc](transactions/fulfillMarketAuctionEscrowed.cdc)

```cadence
transaction(
	owner: String,
	id: UInt64
	)
```

| Parameter | Type | Description |
| :--- | :--- | :--- |
| `owner` | `String` | string address or .find name to the NFT owner |
| `id` | `UInt64` | The `UUID` of the NFT  |

## Auction : Cancel Auction - sign by Seller
[cancelMarketAuctionEscrowed.cdc](transactions/cancelMarketAuctionEscrowed.cdc)

```cadence
transaction(
	ids: [UInt64]
	)
```

| Parameter | Type | Description |
| :--- | :--- | :--- |
| `ids` | `[UInt64]` | The `UUID`s of the NFT to be delisted from Auction |

## Direct Offer : Offer - sign by Buyer
[bidMarketDirectOfferEscrowed.cdc](transactions/bidMarketDirectOfferEscrowed.cdc)

```cadence
transaction(
	user: String,
	nftAliasOrIdentifier: String,
	id: UInt64,
	ftAliasOrIdentifier:String,
	amount: UFix64,
	validUntil: UFix64?
	)

```

| Parameter | Type | Description |
| :--- | :--- | :--- |
| `user` | `String` | .find name or address of the NFT owner|
| `nftAliasOrIdentifier` | `String` | NFT resource identifier to be listed e.g. `A.CONTRACT_ADDRESS.CONTRACT_NAME.NFT`|
| `id` | `UInt64` | The ID of the NFT (NOT UUID) |
| `ftAliasOrIdentifier` | `String` | Fungible Token Vault identifier to be listed in |
| `amount` | `UFix64` | Price to be offered on the NFT |
| `validUntil` | `UFix64?` | Optional expiration time for the offer |

## Direct Offer : Accept Offer - sign by Seller
[fulfillMarketDirectOfferEscrowed.cdc](transactions/fulfillMarketDirectOfferEscrowed.cdc)

```cadence
transaction(
	id: UInt64
	)

```

| Parameter | Type | Description |
| :--- | :--- | :--- |
| `id` | `UInt64` | The `UUID` of the NFT |

## Direct Offer : Reject Offer - Sign by Seller
[cancelMarketDirectOfferEscrowed.cdc](transactions/cancelMarketDirectOfferEscrowed.cdc)

```cadence
transaction(
	ids: [UInt64]
	)
```

| Parameter | Type | Description |
| :--- | :--- | :--- |
| `ids` | `[UInt64]` | The `UUID`s of the NFT which offers to be rejected |


## Direct Offer : Retract Offer - Sign by Buyer
[retractOfferMarketDirectOfferEscrowed.cdc](transactions/retractOfferMarketDirectOfferEscrowed.cdc)

```cadence
transaction(
	ids: [UInt64]
	)
```

| Parameter | Type | Description |
| :--- | :--- | :--- |
| `id` | `UInt64` | The `UUID` of the NFT which offers to be retracted |


# Name Marketplace

## Sale : List Name - sign by Seller
[listLeaseForSale.cdc](transactions/listLeaseForSale.cdc)

```cadence
transaction(
	leaseName: String,
	ftAliasOrIdentifier: String,
	directSellPrice:UFix64,
	validUntil: UFix64?
	)

```

| Parameter | Type | Description |
| :--- | :--- | :--- |
| `leaseName` | `String` | Owned .find names to be listed for sale |
| `ftAliasOrIdentifier` | `String` | Fungible Token Vault identifier to be listed in |
| `directSellPrice` | `UFix64` | Price to be listed |
| `validUntil` | `UFix64?` | Optional expiration time for the listing |

## Sale : Buy Name - sign by Buyer
[buyLeaseForSale.cdc](transactions/buyLeaseForSale.cdc)

```cadence
transaction(
	leaseName: String,
	amount: UFix64
	)

```

| Parameter | Type | Description |
| :--- | :--- | :--- |
| `leaseName` | `String` | .find name to be bought |
| `amount` | `UFix64` | Amount to be paid (transaction will assert the amount paid, this is here to ensure user acknowledge the amount paying) |

## Sale : Cancel Name Sale - sign by Seller
[delistLeaseSale.cdc](transactions/delistLeaseSale.cdc)

```cadence
transaction(
	leases: [String],
	)

```

| Parameter | Type | Description |
| :--- | :--- | :--- |
| `leases` | `[String]]` | .find names to be delisted |

## Auction : List for Name Auction - sign by Seller
[listLeaseForAuctionEscrow.cdc](transactions/listLeaseForAuctionEscrow.cdc)

```cadence
transaction(
	leaseName: String,
	ftAliasOrIdentifier:String,
	price:UFix64,
	auctionReservePrice: UFix64,
	auctionDuration: UFix64,
	auctionExtensionOnLateBid: UFix64,
	minimumBidIncrement: UFix64,
	auctionValidUntil: UFix64?
	)
```

| Parameter | Type | Description |
| :--- | :--- | :--- |
| `leaseName` | `String` | Owned .find names to be listed for sale |
| `ftAliasOrIdentifier` | `String` | Fungible Token Vault identifier to be listed in |
| `price` | `UFix64` | Price to be listed at start of auction |
| `auctionReservePrice` | `UFix64` | Auction ends below this price would be regarded as not fulfilled auction |
| `auctionDuration` | `UFix64` | Duration of auction in unix timestamp |
| `auctionExtensionOnLateBid` | `UFix64` | Extension of duration of auction in unix timestamp for latest bid |
| `minimumBidIncrement` | `UFix64` | Minimum bid increment |
| `auctionValidUntil` | `UFix64?` | Optional expiration time for the listing |

## Auction : Bid for Name Auction - sign by Buyer
[bidLeaseMarketAuctionEscrow.cdc](transactions/bidLeaseMarketAuctionEscrow.cdc)

```cadence
transaction(
	leaseName: String,
	amount: UFix64
	)

```

| Parameter | Type | Description |
| :--- | :--- | :--- |
| `leaseName` | `String` | .find name to place bid on |
| `amount` | `UFix64` | Amount to be escrowed for bid |

## Auction : Increase Name Bid for Auction - sign by Buyer
[increaseBidLeaseMarketAuctionEscrow.cdc](transactions/increaseBidLeaseMarketAuctionEscrow.cdc)

```cadence
transaction(
	leaseName: String,
	amount: UFix64
	)

```

| Parameter | Type | Description |
| :--- | :--- | :--- |
| `leaseName` | `String` | .find name to place bid on |
| `amount` | `UFix64` | Increment amount to be added to bid |

## Auction : Fulfill Name Auction - sign by Buyer
[fulfillLeaseMarketAuctionEscrow.cdc](transactions/fulfillLeaseMarketAuctionEscrow.cdc)

```cadence
transaction(
	leaseName: String,
	)
```

| Parameter | Type | Description |
| :--- | :--- | :--- |
| `leaseName` | `String` | .find name to place bid on |

## Auction : Cancel Name Auction - sign by Seller
[cancelLeaseMarketAuctionEscrow.cdc](transactions/cancelLeaseMarketAuctionEscrow.cdc)

```cadence
transaction(
	leaseNames: [String]
	)
```

| Parameter | Type | Description |
| :--- | :--- | :--- |
| `leaseNames` | `[String]` | .find name to be delisted from auction |

## Direct Offer : Offer Name - sign by Buyer
[bidLeaseMarketDirectOfferEscrow.cdc](transactions/bidLeaseMarketDirectOfferEscrow.cdc)

```cadence
transaction(
	leaseName: String,
	ftAliasOrIdentifier:String,
	amount: UFix64,
	validUntil: UFix64?
	)

```

| Parameter | Type | Description |
| :--- | :--- | :--- |
| `leaseName` | `String` | .find name to place offer on |
| `ftAliasOrIdentifier` | `String` | Fungible Token Vault identifier to be listed in |
| `amount` | `UFix64` | Price to be offered on the NFT |
| `validUntil` | `UFix64?` | Optional expiration time for the offer |

## Direct Offer : Accept Name Offer - sign by Seller
[fulfillLeaseMarketDirectOfferEscrow.cdc](transactions/fulfillLeaseMarketDirectOfferEscrow.cdc)

```cadence
transaction(
	leaseName: String
	)

```

| Parameter | Type | Description |
| :--- | :--- | :--- |
| `leaseName` | `String` | .find name to fulfill offer |

## Direct Offer : Reject Name Offer - Sign by Seller
[cancelLeaseMarketDirectOfferEscrow.cdc](transactions/cancelLeaseMarketDirectOfferEscrow.cdc)

```cadence
transaction(
	leaseNames: [String]
	)
```

| Parameter | Type | Description |
| :--- | :--- | :--- |
| `leaseNames` | `[String]` | The .find names which offers to be rejected |


## Direct Offer : Retract Name Offer - Sign by Buyer
[retractOfferLeaseMarketDirectOfferEscrow.cdc](transactions/retractOfferLeaseMarketDirectOfferEscrow.cdc)

```cadence
transaction(
	leaseNames: [String]
	)
```

| Parameter | Type | Description |
| :--- | :--- | :--- |
| `leaseNames` | `[String]` | The .find names which offers to be retracted |


<!--
## To be implemented
## Status Codes

FIND returns the following status codes in scripts:

| Status Code | Description |
| :--- | :--- |
 -->

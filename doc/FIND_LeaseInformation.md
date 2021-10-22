# Struct `LeaseInformation`

```cadence
struct LeaseInformation {

    name:  String

    address:  Address

    cost:  UFix64

    status:  String

    validUntil:  UFix64

    lockedUntil:  UFix64

    latestBid:  UFix64?

    auctionEnds:  UFix64?

    salePrice:  UFix64?

    latestBidBy:  Address?

    currentTime:  UFix64

    auctionStartPrice:  UFix64?

    auctionReservePrice:  UFix64?

    extensionOnLateBid:  UFix64?
}
```


### Initializer

```cadence
func init(name String, status LeaseStatus, validUntil UFix64, lockedUntil UFix64, latestBid UFix64?, auctionEnds UFix64?, salePrice UFix64?, latestBidBy Address?, auctionStartPrice UFix64?, auctionReservePrice UFix64?, extensionOnLateBid UFix64?, address Address)
```



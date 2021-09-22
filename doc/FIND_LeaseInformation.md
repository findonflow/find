# Struct `LeaseInformation`

```cadence
struct LeaseInformation {

    name:  String

    status:  LeaseStatus

    expireTime:  UFix64

    latestBid:  UFix64?

    auctionEnds:  UFix64?

    salePrice:  UFix64?

    latestBidBy:  Address?

    currentTime:  UFix64
}
```


### Initializer

```cadence
func init(name String, status LeaseStatus, expireTime UFix64, latestBid UFix64?, auctionEnds UFix64?, salePrice UFix64?, latestBidBy Address?)
```



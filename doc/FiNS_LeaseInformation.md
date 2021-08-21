# Struct `LeaseInformation`

```cadence
struct LeaseInformation {

    tag:  String

    status:  LeaseStatus

    expireTime:  UFix64

    latestBid:  UFix64?

    auctionEnds:  UFix64?

    salePrice:  UFix64?

    latestBidBy:  Address?
}
```


### Initializer

```cadence
func init(tag String, status LeaseStatus, expireTime UFix64, latestBid UFix64?, auctionEnds UFix64?, salePrice UFix64?, latestBidBy Address?)
```



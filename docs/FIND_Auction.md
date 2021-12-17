# Resource `Auction`

```cadence
resource Auction {

    endsAt:  UFix64

    startedAt:  UFix64

    extendOnLateBid:  UFix64

    latestBidCallback:  Capability<&BidCollection{BidCollectionPublic}>

    name:  String
}
```


### Initializer

```cadence
func init(endsAt UFix64, startedAt UFix64, extendOnLateBid UFix64, latestBidCallback Capability<&BidCollection{BidCollectionPublic}>, name String)
```


## Functions

### fun `getBalance()`

```cadence
func getBalance(): UFix64
```

---

### fun `addBid()`

```cadence
func addBid(callback Capability<&BidCollection{BidCollectionPublic}>, timestamp UFix64, lease &Lease)
```

---

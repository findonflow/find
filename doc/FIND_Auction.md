# Resource `Auction`

```cadence
resource Auction {

    endsAt:  UFix64

    startedAt:  UFix64

    extendOnLateBid:  UFix64

    callback:  Capability<&{BidCollectionPublic}>

    name:  String
}
```


### Initializer

```cadence
func init(endsAt UFix64, startedAt UFix64, extendOnLateBid UFix64, callback Capability<&{BidCollectionPublic}>, name String)
```


## Functions

### fun `getBalance()`

```cadence
func getBalance(): UFix64
```

---

### fun `addBid()`

```cadence
func addBid(callback Capability<&{BidCollectionPublic}>, timestamp UFix64)
```

---

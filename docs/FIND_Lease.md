# Resource `Lease`

```cadence
resource Lease {

    name:  String

    networkCap:  Capability<&Network>

    salePrice:  UFix64?

    auctionStartPrice:  UFix64?

    auctionReservePrice:  UFix64?

    auctionDuration:  UFix64

    auctionMinBidIncrement:  UFix64

    auctionExtensionOnLateBid:  UFix64

    offerCallback:  Capability<&BidCollection{BidCollectionPublic}>?

    addons:  {String: Bool}
}
```


### Initializer

```cadence
func init(name String, networkCap Capability<&Network>)
```


## Functions

### fun `addAddon()`

```cadence
func addAddon(_ String)
```

---

### fun `setExtentionOnLateBid()`

```cadence
func setExtentionOnLateBid(_ UFix64)
```

---

### fun `setAuctionDuration()`

```cadence
func setAuctionDuration(_ UFix64)
```

---

### fun `setSalePrice()`

```cadence
func setSalePrice(_ UFix64?)
```

---

### fun `setReservePrice()`

```cadence
func setReservePrice(_ UFix64?)
```

---

### fun `setMinBidIncrement()`

```cadence
func setMinBidIncrement(_ UFix64)
```

---

### fun `setStartAuctionPrice()`

```cadence
func setStartAuctionPrice(_ UFix64?)
```

---

### fun `setCallback()`

```cadence
func setCallback(_ Capability<&BidCollection{BidCollectionPublic}>?)
```

---

### fun `extendLease()`

```cadence
func extendLease(_ FUSD.Vault)
```

---

### fun `move()`

```cadence
func move(profile Capability<&{Profile.Public}>)
```

---

### fun `getLeaseExpireTime()`

```cadence
func getLeaseExpireTime(): UFix64
```

---

### fun `getLeaseLockedUntil()`

```cadence
func getLeaseLockedUntil(): UFix64
```

---

### fun `getProfile()`

```cadence
func getProfile(): &{Profile.Public}?
```

---

### fun `getLeaseStatus()`

```cadence
func getLeaseStatus(): LeaseStatus
```

---

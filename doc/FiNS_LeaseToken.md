# Resource `LeaseToken`

```cadence
resource LeaseToken {

    tag:  String

    networkCap:  Capability<&Network>

    salePrice:  UFix64?

    callback:  Capability<&{BidCollectionPublic}>?
}
```


### Initializer

```cadence
func init(tag String, networkCap Capability<&Network>)
```


## Functions

### fun `setSalePrice()`

```cadence
func setSalePrice(_ UFix64?)
```

---

### fun `setCallback()`

```cadence
func setCallback(_ Capability<&{BidCollectionPublic}>?)
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

### fun `getLeaseStatus()`

```cadence
func getLeaseStatus(): LeaseStatus
```

---

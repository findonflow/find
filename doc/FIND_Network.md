# Resource `Network`

```cadence
resource Network {

    wallet:  Capability<&{FungibleToken.Receiver}>

    leasePeriod:  UFix64

    lockPeriod:  UFix64

    defaultPrice:  UFix64

    secondaryCut:  UFix64

    lengthPrices:  {Int: UFix64}

    profiles:  {String: NetworkLease}
}
```


### Initializer

```cadence
func init(leasePeriod UFix64, lockPeriod UFix64, secondaryCut UFix64, defaultPrice UFix64, lengthPrices {Int: UFix64}, wallet Capability<&{FungibleToken.Receiver}>)
```


## Functions

### fun `renew()`

```cadence
func renew(name String, vault FUSD.Vault)
```

---

### fun `getLeaseExpireTime()`

```cadence
func getLeaseExpireTime(_ String): UFix64
```

---

### fun `move()`

```cadence
func move(name String, profile Capability<&{Profile.Public}>)
```

---

### fun `register()`

```cadence
func register(name String, vault FUSD.Vault, profile Capability<&{Profile.Public}>, leases Capability<&{LeaseCollectionPublic}>)
```

---

### fun `readStatus()`

```cadence
func readStatus(_ String): NameStatus
```

---

### fun `outdated()`

```cadence
func outdated(): [String]
```

---

### fun `status()`

```cadence
func status(_ String): NameStatus
```
This method is almost like readStatus except that it will mutate state and fix the name it looks up if it is invalid.  Events are emitted when this is done.

---

### fun `lookup()`

```cadence
func lookup(_ String): &{Profile.Public}?
```

---

### fun `calculateCost()`

```cadence
func calculateCost(_ String): UFix64
```

---

### fun `setWallet()`

```cadence
func setWallet(_ Capability<&{FungibleToken.Receiver}>)
```

---

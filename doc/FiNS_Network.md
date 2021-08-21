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
func renew(tag String, vault FUSD.Vault)
```

---

### fun `getLeaseExpireTime()`

```cadence
func getLeaseExpireTime(_ String): UFix64
```

---

### fun `getLeaseStatus()`

```cadence
func getLeaseStatus(_ String): LeaseStatus
```

---

### fun `move()`

```cadence
func move(tag String, profile Capability<&{Profile.Public}>)
```

---

### fun `register()`

```cadence
func register(tag String, vault FUSD.Vault, profile Capability<&{Profile.Public}>, leases Capability<&{LeaseCollectionPublic}>)
```

---

### fun `status()`

```cadence
func status(_ String): LeaseStatus
```

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

### fun `setLengthPrices()`

```cadence
func setLengthPrices(_ {Int: UFix64})
```

---

### fun `setDefaultPrice()`

```cadence
func setDefaultPrice(_ UFix64)
```

---

### fun `setLeasePeriod()`

```cadence
func setLeasePeriod(_ UFix64)
```

---

### fun `setLockPeriod()`

```cadence
func setLockPeriod(_ UFix64)
```

---

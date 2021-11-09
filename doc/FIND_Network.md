# Resource `Network`

```cadence
resource Network {

    wallet:  Capability<&{FungibleToken.Receiver}>

    leasePeriod:  UFix64

    lockPeriod:  UFix64

    defaultPrice:  UFix64

    secondaryCut:  UFix64

    lengthPrices:  {Int: UFix64}

    addonPrices:  {String: UFix64}

    publicEnabled:  Bool

    profiles:  {String: NetworkLease}
}
```


### Initializer

```cadence
func init(leasePeriod UFix64, lockPeriod UFix64, secondaryCut UFix64, defaultPrice UFix64, lengthPrices {Int: UFix64}, wallet Capability<&{FungibleToken.Receiver}>, publicEnabled Bool)
```


## Functions

### fun `setAddonPrice()`

```cadence
func setAddonPrice(name String, price UFix64)
```

---

### fun `setPrice()`

```cadence
func setPrice(default UFix64, additionalPrices {Int: UFix64})
```

---

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

### fun `getLeaseLocedUntil()`

```cadence
func getLeaseLocedUntil(_ String): UFix64
```

---

### fun `move()`

```cadence
func move(name String, profile Capability<&{Profile.Public}>)
```

---

### fun `register()`

```cadence
func register(name String, vault FUSD.Vault, profile Capability<&{Profile.Public}>, leases Capability<&LeaseCollection{LeaseCollectionPublic}>)
```

---

### fun `readStatus()`

```cadence
func readStatus(_ String): NameStatus
```

---

### fun `profile()`

```cadence
func profile(_ String): &{Profile.Public}?
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

### fun `setWallet()`

```cadence
func setWallet(_ Capability<&{FungibleToken.Receiver}>)
```

---

### fun `setPublicEnabled()`

```cadence
func setPublicEnabled(_ Bool)
```

---

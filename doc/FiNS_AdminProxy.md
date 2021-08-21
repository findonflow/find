# Resource `AdminProxy`

```cadence
resource AdminProxy {

    capability:  Capability<&Administrator>?
}
```


Implemented Interfaces:
  - `AdminProxyClient`


### Initializer

```cadence
func init()
```


## Functions

### fun `addCapability()`

```cadence
func addCapability(_ Capability<&Administrator>)
```

---

### fun `register()`

```cadence
func register(tag String, vault FUSD.Vault, profile Capability<&{Profile.Public}>, leases Capability<&{LeaseCollectionPublic}>)
```

---

### fun `advanceClock()`

```cadence
func advanceClock(_ UFix64)
```

---

### fun `createNetwork()`

```cadence
func createNetwork(admin AuthAccount, leasePeriod UFix64, lockPeriod UFix64, secondaryCut UFix64, defaultPrice UFix64, lengthPrices {Int: UFix64}, wallet Capability<&{FungibleToken.Receiver}>)
```

---

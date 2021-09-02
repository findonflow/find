# Resource `AdminProxy`

```cadence
resource AdminProxy {

    capability:  Capability<&Network>?
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
func addCapability(_ Capability<&Network>)
```

---

### fun `setWallet()`

```cadence
func setWallet(_ Capability<&{FungibleToken.Receiver}>)
```
Set the wallet used for the network
@param _ The FT receiver to send the money to

---

### fun `register()`

```cadence
func register(name String, vault FUSD.Vault, profile Capability<&{Profile.Public}>, leases Capability<&{LeaseCollectionPublic}>)
```

---

### fun `advanceClock()`

```cadence
func advanceClock(_ UFix64)
```

---

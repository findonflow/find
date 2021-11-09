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

### fun `setArtifactTypeConverter()`

```cadence
func setArtifactTypeConverter(from Type, converters [Capability<&{TypedMetadata.TypeConverter}>])
```

---

### fun `setWallet()`

```cadence
func setWallet(_ Capability<&{FungibleToken.Receiver}>)
```
Set the wallet used for the network
@param _ The FT receiver to send the money to

---

### fun `setPublicEnabled()`

```cadence
func setPublicEnabled(_ Bool)
```
Enable or disable public registration

---

### fun `setAddonPrice()`

```cadence
func setAddonPrice(name String, price UFix64)
```

---

### fun `setPrice()`

```cadence
func setPrice(default UFix64, additional {Int: UFix64})
```

---

### fun `register()`

```cadence
func register(name String, vault FUSD.Vault, profile Capability<&{Profile.Public}>, leases Capability<&LeaseCollection{LeaseCollectionPublic}>)
```

---

### fun `createForge()`

```cadence
func createForge(platform Artifact.MinterPlatform): Artifact.Forge
```

---

### fun `advanceClock()`

```cadence
func advanceClock(_ UFix64)
```

---

### fun `debug()`

```cadence
func debug(_ Bool)
```

---

# Resource `Bid`

```cadence
resource Bid {

    from:  Capability<&LeaseCollection{LeaseCollectionPublic}>

    name:  String

    type:  String

    vault:  FUSD.Vault

    bidAt:  UFix64
}
```


### Initializer

```cadence
func init(from Capability<&LeaseCollection{LeaseCollectionPublic}>, name String, vault FUSD.Vault)
```


## Functions

### fun `setType()`

```cadence
func setType(_ String)
```

---

### fun `setBidAt()`

```cadence
func setBidAt(_ UFix64)
```

---

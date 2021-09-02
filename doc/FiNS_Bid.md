# Resource `Bid`

```cadence
resource Bid {

    from:  Capability<&{FIND.LeaseCollectionPublic}>

    tag:  String

    vault:  FUSD.Vault

    bidAt:  UFix64
}
```


### Initializer

```cadence
func init(from Capability<&{FIND.LeaseCollectionPublic}>, tag String, vault FUSD.Vault)
```


## Functions

### fun `setBidAt()`

```cadence
func setBidAt(_ UFix64)
```

---

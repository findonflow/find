# Struct `NetworkLease`

```cadence
struct NetworkLease {

    registeredTime:  UFix64

    validUntil:  UFix64

    lockedUntil:  UFix64

    profile:  Capability<&{Profile.Public}>

    address:  Address

    name:  String
}
```


### Initializer

```cadence
func init(validUntil UFix64, lockedUntil UFix64, profile Capability<&{Profile.Public}>, name String)
```


## Functions

### fun `setValidUntil()`

```cadence
func setValidUntil(_ UFix64)
```

---

### fun `setLockedUntil()`

```cadence
func setLockedUntil(_ UFix64)
```

---

### fun `status()`

```cadence
func status(): LeaseStatus
```

---

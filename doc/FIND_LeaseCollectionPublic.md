# Resource Interface `LeaseCollectionPublic`

```cadence
resource interface LeaseCollectionPublic {
}
```

## Functions

### fun `getLeases()`

```cadence
func getLeases(): [String]
```

---

### fun `getLeaseInformation()`

```cadence
func getLeaseInformation(): [LeaseInformation]
```

---

### fun `getLease()`

```cadence
func getLease(_ String): LeaseInformation?
```

---

### fun `deposit()`

```cadence
func deposit(token FIND.Lease)
```

---

### fun `cancelBid()`

```cadence
func cancelBid(_ String)
```

---

### fun `increaseBid()`

```cadence
func increaseBid(_ String)
```

---

### fun `bid()`

```cadence
func bid(name String, callback Capability<&BidCollection{BidCollectionPublic}>)
```

---

### fun `fulfillAuction()`

```cadence
func fulfillAuction(_ String)
```

---

### fun `buyAddon()`

```cadence
func buyAddon(name String, addon String, vault FUSD.Vault)
```

---

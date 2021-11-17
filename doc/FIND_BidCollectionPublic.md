# Resource Interface `BidCollectionPublic`

```cadence
resource interface BidCollectionPublic {
}
```

## Functions

### fun `getBids()`

```cadence
func getBids(): [BidInfo]
```

---

### fun `getBalance()`

```cadence
func getBalance(_ String): UFix64
```

---

### fun `fulfill()`

```cadence
func fulfill(_ FIND.Lease): FungibleToken.Vault
```

---

### fun `cancel()`

```cadence
func cancel(_ String)
```

---

### fun `setBidType()`

```cadence
func setBidType(name String, type String)
```

---

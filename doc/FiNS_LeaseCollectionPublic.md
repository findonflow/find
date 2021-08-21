# Resource Interface `LeaseCollectionPublic`

```cadence
resource interface LeaseCollectionPublic {
}
```

## Functions

### fun `getTokens()`

```cadence
func getTokens(): [String]
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
func deposit(token FiNS.LeaseToken)
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
func bid(tag String, callback Capability<&{BidCollectionPublic}>)
```

---

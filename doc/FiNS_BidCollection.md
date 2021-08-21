# Resource `BidCollection`

```cadence
resource BidCollection {

    bids:  {String: Bid}

    receiver:  Capability<&{FungibleToken.Receiver}>

    leases:  Capability<&{FiNS.LeaseCollectionPublic}>
}
```


Implemented Interfaces:
  - `BidCollectionPublic`


### Initializer

```cadence
func init(receiver Capability<&{FungibleToken.Receiver}>, leases Capability<&{FiNS.LeaseCollectionPublic}>)
```


## Functions

### fun `fullfill()`

```cadence
func fullfill(_ FiNS.LeaseToken): FungibleToken.Vault
```

---

### fun `cancel()`

```cadence
func cancel(_ String)
```

---

### fun `getBids()`

```cadence
func getBids(): [BidInfo]
```

---

### fun `bid()`

```cadence
func bid(tag String, vault FUSD.Vault)
```

---

### fun `increaseBid()`

```cadence
func increaseBid(tag String, vault FungibleToken.Vault)
```

---

### fun `cancelBid()`

```cadence
func cancelBid(_ String)
```

---

### fun `borrowBid()`

```cadence
func borrowBid(_ String): &Bid
```

---

### fun `getBalance()`

```cadence
func getBalance(_ String): UFix64
```

---

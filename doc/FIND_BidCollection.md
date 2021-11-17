# Resource `BidCollection`

```cadence
resource BidCollection {

    bids:  {String: Bid}

    receiver:  Capability<&{FungibleToken.Receiver}>

    leases:  Capability<&LeaseCollection{LeaseCollectionPublic}>
}
```


Implemented Interfaces:
  - `BidCollectionPublic`


### Initializer

```cadence
func init(receiver Capability<&{FungibleToken.Receiver}>, leases Capability<&LeaseCollection{LeaseCollectionPublic}>)
```


## Functions

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

### fun `getBids()`

```cadence
func getBids(): [BidInfo]
```

---

### fun `bid()`

```cadence
func bid(name String, vault FUSD.Vault)
```

---

### fun `increaseBid()`

```cadence
func increaseBid(name String, vault FungibleToken.Vault)
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

### fun `setBidType()`

```cadence
func setBidType(name String, type String)
```

---

### fun `getBalance()`

```cadence
func getBalance(_ String): UFix64
```

---

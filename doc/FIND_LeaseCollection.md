# Resource `LeaseCollection`

```cadence
resource LeaseCollection {

    leases:  {String: FIND.Lease}

    auctions:  {String: Auction}

    networkCut:  UFix64

    networkWallet:  Capability<&{FungibleToken.Receiver}>
}
```


Implemented Interfaces:
  - `LeaseCollectionPublic`


### Initializer

```cadence
func init(networkCut UFix64, networkWallet Capability<&{FungibleToken.Receiver}>)
```


## Functions

### fun `getLease()`

```cadence
func getLease(_ String): LeaseInformation?
```

---

### fun `getLeaseInformation()`

```cadence
func getLeaseInformation(): [LeaseInformation]
```

---

### fun `startAuction()`

```cadence
func startAuction(_ String)
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
func bid(name String, callback Capability<&{BidCollectionPublic}>)
```

---

### fun `cancel()`

```cadence
func cancel(_ String)
```

---

### fun `fullfillAuction()`

```cadence
func fullfillAuction(_ String)
```
fullfillAuction wraps the fullfill method and ensure that only a finished auction can be fullfilled by anybody

---

### fun `fullfill()`

```cadence
func fullfill(_ String)
```

---

### fun `listForSale()`

```cadence
func listForSale(name String, amount UFix64)
```

---

### fun `delistSale()`

```cadence
func delistSale(_ String)
```

---

### fun `move()`

```cadence
func move(name String, profile Capability<&{Profile.Public}>, to Capability<&{LeaseCollectionPublic}>)
```

---

### fun `remove()`

```cadence
func remove(_ String)
```

---

### fun `deposit()`

```cadence
func deposit(token FIND.Lease)
```

---

### fun `getLeases()`

```cadence
func getLeases(): [String]
```

---

### fun `borrow()`

```cadence
func borrow(_ String): &FIND.Lease
```

---

### fun `borrowAuction()`

```cadence
func borrowAuction(_ String): &FIND.Auction
```

---

### fun `register()`

```cadence
func register(name String, vault FUSD.Vault)
```

---

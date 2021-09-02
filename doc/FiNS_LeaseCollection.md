# Resource `LeaseCollection`

```cadence
resource LeaseCollection {

    tokens:  {String: FIND.LeaseToken}

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
func bid(tag String, callback Capability<&{BidCollectionPublic}>)
```

---

### fun `fullfill()`

```cadence
func fullfill(tag String)
```

---

### fun `listForSale()`

```cadence
func listForSale(tag String, amount UFix64)
```

---

### fun `delistSale()`

```cadence
func delistSale(_ String)
```

---

### fun `move()`

```cadence
func move(tag String, profile Capability<&{Profile.Public}>, to Capability<&{LeaseCollectionPublic}>)
```

---

### fun `deposit()`

```cadence
func deposit(token FIND.LeaseToken)
```

---

### fun `getTokens()`

```cadence
func getTokens(): [String]
```

---

### fun `borrow()`

```cadence
func borrow(_ String): &FIND.LeaseToken
```

---

### fun `borrowAuction()`

```cadence
func borrowAuction(_ String): &FIND.Auction
```

---

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

### fun `createPlatform()`

```cadence
func createPlatform(_ String): Artifact.MinterPlatform
```

---

### fun `mintArtifact()`

```cadence
func mintArtifact(name String, nftName String, schemas [AnyStruct]): Artifact.NFT
```

---

### fun `mintNFTWithSharedData()`

```cadence
func mintNFTWithSharedData(name String, nftName String, schemas [AnyStruct], sharedPointer Artifact.Pointer): Artifact.NFT
```

---

### fun `buyAddon()`

```cadence
func buyAddon(name String, addon String, vault FUSD.Vault)
```

---

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
func bid(name String, callback Capability<&BidCollection{BidCollectionPublic}>)
```

---

### fun `cancel()`

```cadence
func cancel(_ String)
```

---

### fun `fulfillAuction()`

```cadence
func fulfillAuction(_ String)
```
fulfillAuction wraps the fulfill method and ensure that only a finished auction can be fulfilled by anybody

---

### fun `fulfill()`

```cadence
func fulfill(_ String)
```

---

### fun `listForAuction()`

```cadence
func listForAuction(name String, auctionStartPrice UFix64, auctionReservePrice UFix64, auctionDuration UFix64, auctionExtensionOnLateBid UFix64)
```

---

### fun `listForSale()`

```cadence
func listForSale(name String, directSellPrice UFix64)
```

---

### fun `delistAuction()`

```cadence
func delistAuction(_ String)
```

---

### fun `delistSale()`

```cadence
func delistSale(_ String)
```

---

### fun `move()`

```cadence
func move(name String, profile Capability<&{Profile.Public}>, to Capability<&LeaseCollection{LeaseCollectionPublic}>)
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

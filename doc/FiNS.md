# Contract `FIND`

```cadence
contract FIND {

    BidPublicPath:  PublicPath

    BidStoragePath:  StoragePath

    NetworkStoragePath:  StoragePath

    NetworkPrivatePath:  PrivatePath

    AdministratorPrivatePath:  PrivatePath

    AdministratorStoragePath:  StoragePath

    AdminProxyPublicPath:  PublicPath

    AdminProxyStoragePath:  StoragePath

    LeaseStoragePath:  StoragePath

    LeasePublicPath:  PublicPath

    fakeClock:  UFix64?

    networkCap:  Capability<&Network>?
}
```

## Interfaces
    
### resource interface `LeaseCollectionPublic`

```cadence
resource interface LeaseCollectionPublic {
}
```

[More...](FIND_LeaseCollectionPublic.md)

---
    
### resource interface `AdminProxyClient`

```cadence
resource interface AdminProxyClient {
}
```

[More...](FIND_AdminProxyClient.md)

---
    
### resource interface `BidCollectionPublic`

```cadence
resource interface BidCollectionPublic {
}
```

[More...](FIND_BidCollectionPublic.md)

---
## Structs & Resources

### resource `LeaseToken`

```cadence
resource LeaseToken {

    tag:  String

    networkCap:  Capability<&Network>

    salePrice:  UFix64?

    callback:  Capability<&{BidCollectionPublic}>?
}
```

[More...](FIND_LeaseToken.md)

---

### resource `Auction`

```cadence
resource Auction {

    endsAt:  UFix64

    startedAt:  UFix64

    extendOnLateBid:  UFix64

    callback:  Capability<&{BidCollectionPublic}>

    tag:  String
}
```

[More...](FIND_Auction.md)

---

### struct `LeaseInformation`

```cadence
struct LeaseInformation {

    tag:  String

    status:  LeaseStatus

    expireTime:  UFix64

    latestBid:  UFix64?

    auctionEnds:  UFix64?

    salePrice:  UFix64?

    latestBidBy:  Address?
}
```

[More...](FIND_LeaseInformation.md)

---

### resource `LeaseCollection`

```cadence
resource LeaseCollection {

    tokens:  {String: FIND.LeaseToken}

    auctions:  {String: Auction}

    networkCut:  UFix64

    networkWallet:  Capability<&{FungibleToken.Receiver}>
}
```

[More...](FIND_LeaseCollection.md)

---

### struct `NetworkLease`

```cadence
struct NetworkLease {

    status:  LeaseStatus

    time:  UFix64

    profile:  Capability<&{Profile.Public}>

    address:  Address

    tag:  String
}
```

[More...](FIND_NetworkLease.md)

---

### resource `Network`

```cadence
resource Network {

    wallet:  Capability<&{FungibleToken.Receiver}>

    leasePeriod:  UFix64

    lockPeriod:  UFix64

    defaultPrice:  UFix64

    secondaryCut:  UFix64

    lengthPrices:  {Int: UFix64}

    profiles:  {String: NetworkLease}
}
```

[More...](FIND_Network.md)

---

### resource `Administrator`

```cadence
resource Administrator {
}
```

[More...](FIND_Administrator.md)

---

### resource `AdminProxy`

```cadence
resource AdminProxy {

    capability:  Capability<&Administrator>?
}
```

[More...](FIND_AdminProxy.md)

---

### struct `BidInfo`

```cadence
struct BidInfo {

    tag:  String

    amount:  UFix64

    timestamp:  UFix64
}
```

[More...](FIND_BidInfo.md)

---

### resource `Bid`

```cadence
resource Bid {

    from:  Capability<&{FIND.LeaseCollectionPublic}>

    tag:  String

    vault:  FUSD.Vault

    bidAt:  UFix64
}
```

[More...](FIND_Bid.md)

---

### resource `BidCollection`

```cadence
resource BidCollection {

    bids:  {String: Bid}

    receiver:  Capability<&{FungibleToken.Receiver}>

    leases:  Capability<&{FIND.LeaseCollectionPublic}>
}
```

[More...](FIND_BidCollection.md)

---
## Enums

### enum `LeaseStatus`

```cadence
enum LeaseStatus: UInt8 {
    case FREE
    case TAKEN
    case LOCKED
}
```

---
## Functions

### fun `calculateCost()`

```cadence
func calculateCost(_ String): UFix64
```

---

### fun `lookup()`

```cadence
func lookup(_ String): &{Profile.Public}?
```

---

### fun `deposit()`

```cadence
func deposit(to String, from FungibleToken.Vault)
```

---

### fun `status()`

```cadence
func status(_ String): LeaseStatus
```

---

### fun `register()`

```cadence
func register(tag String, vault FUSD.Vault, profile Capability<&{Profile.Public}>, leases Capability<&{LeaseCollectionPublic}>)
```

---

### fun `createEmptyLeaseCollection()`

```cadence
func createEmptyLeaseCollection(): FIND.LeaseCollection
```

---

### fun `createAdminProxyClient()`

```cadence
func createAdminProxyClient(): AdminProxy
```

---

### fun `createEmptyBidCollection()`

```cadence
func createEmptyBidCollection(receiver Capability<&{FungibleToken.Receiver}>, leases Capability<&{FIND.LeaseCollectionPublic}>): BidCollection
```

---

### fun `time()`

```cadence
func time(): UFix64
```

---
## Events

### event `Register`

```cadence
event Register(tag String, owner Address, expireAt UFix64)
```

---

### event `Moved`

```cadence
event Moved(tag String, previousOwner Address, newOwner Address, expireAt UFix64)
```

---

### event `Sold`

```cadence
event Sold(tag String, previousOwner Address, newOwner Address, expireAt UFix64, amount UFix64)
```

---

### event `ForSale`

```cadence
event ForSale(tag String, owner Address, expireAt UFix64, amount UFix64, active Bool)
```

---

### event `BlindBid`

```cadence
event BlindBid(tag String, bidder Address, amount UFix64)
```

---

### event `BlindBidCanceled`

```cadence
event BlindBidCanceled(tag String, bidder Address)
```

---

### event `AuctionStarted`

```cadence
event AuctionStarted(tag String, bidder Address, amount UFix64, auctionEndAt UFix64)
```

---

### event `AuctionBid`

```cadence
event AuctionBid(tag String, bidder Address, amount UFix64, auctionEndAt UFix64)
```

---

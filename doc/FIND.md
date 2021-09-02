# Contract `FIND`

```cadence
contract FIND {

    BidPublicPath:  PublicPath

    BidStoragePath:  StoragePath

    NetworkStoragePath:  StoragePath

    NetworkPrivatePath:  PrivatePath

    AdminProxyPublicPath:  PublicPath

    AdminProxyStoragePath:  StoragePath

    LeaseStoragePath:  StoragePath

    LeasePublicPath:  PublicPath
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

### struct `NameStatus`

```cadence
struct NameStatus {

    status:  LeaseStatus

    owner:  Address?

    persisted:  Bool
}
```

[More...](FIND_NameStatus.md)

---

### resource `LeaseToken`

```cadence
resource LeaseToken {

    name:  String

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

    name:  String
}
```

[More...](FIND_Auction.md)

---

### struct `LeaseInformation`

```cadence
struct LeaseInformation {

    name:  String

    status:  LeaseStatus

    expireTime:  UFix64

    latestBid:  UFix64?

    auctionEnds:  UFix64?

    salePrice:  UFix64?

    latestBidBy:  Address?

    currentTime:  UFix64
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

    name:  String
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

### resource `AdminProxy`

```cadence
resource AdminProxy {

    capability:  Capability<&Network>?
}
```

[More...](FIND_AdminProxy.md)

---

### struct `BidInfo`

```cadence
struct BidInfo {

    name:  String

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

    name:  String

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

### fun `lookupAddress()`

```cadence
func lookupAddress(_ String): Address?
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

### fun `outdated()`

```cadence
func outdated(): [String]
```

---

### fun `janitor()`

```cadence
func janitor(_ String): NameStatus
```
this needs to be called from a transaction

---

### fun `status()`

```cadence
func status(_ String): NameStatus
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
## Events

### event `JanitorLock`

```cadence
event JanitorLock(name String, lockedUntil UFix64)
```

---

### event `JanitorFree`

```cadence
event JanitorFree(name String)
```

---

### event `Register`

```cadence
event Register(name String, owner Address, expireAt UFix64)
```

---

### event `Moved`

```cadence
event Moved(name String, previousOwner Address, newOwner Address, expireAt UFix64)
```

---

### event `Freed`

```cadence
event Freed(name String, previousOwner Address)
```

---

### event `Sold`

```cadence
event Sold(name String, previousOwner Address, newOwner Address, expireAt UFix64, amount UFix64)
```

---

### event `ForSale`

```cadence
event ForSale(name String, owner Address, expireAt UFix64, amount UFix64, active Bool)
```

---

### event `BlindBid`

```cadence
event BlindBid(name String, bidder Address, amount UFix64)
```

---

### event `BlindBidCanceled`

```cadence
event BlindBidCanceled(name String, bidder Address)
```

---

### event `BlindBidRejected`

```cadence
event BlindBidRejected(name String, bidder Address, amount UFix64)
```

---

### event `AuctionCancelled`

```cadence
event AuctionCancelled(name String, bidder Address, amount UFix64)
```

---

### event `AuctionStarted`

```cadence
event AuctionStarted(name String, bidder Address, amount UFix64, auctionEndAt UFix64)
```

---

### event `AuctionBid`

```cadence
event AuctionBid(name String, bidder Address, amount UFix64, auctionEndAt UFix64)
```

---

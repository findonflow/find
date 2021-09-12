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
    
### resource interface `BidCollectionPublic`

```cadence
resource interface BidCollectionPublic {
}
```

[More...](FIND_BidCollectionPublic.md)

---
    
### resource interface `AdminProxyClient`

```cadence
resource interface AdminProxyClient {
}
```

[More...](FIND_AdminProxyClient.md)

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
Struct holding information about a lease. Contains both the internal status the owner of the lease and if the state is persisted or not.

[More...](FIND_NameStatus.md)

---

### resource `Lease`

```cadence
resource Lease {

    name:  String

    networkCap:  Capability<&Network>

    salePrice:  UFix64?

    offerCallback:  Capability<&{BidCollectionPublic}>?
}
```

[More...](FIND_Lease.md)

---

### resource `Auction`

```cadence
resource Auction {

    endsAt:  UFix64

    startedAt:  UFix64

    extendOnLateBid:  UFix64

    latestBidCallback:  Capability<&{BidCollectionPublic}>

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

    leases:  {String: FIND.Lease}

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

    publicEnabled:  Bool

    profiles:  {String: NetworkLease}
}
```

[More...](FIND_Network.md)

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

### resource `AdminProxy`

```cadence
resource AdminProxy {

    capability:  Capability<&Network>?
}
```

[More...](FIND_AdminProxy.md)

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
Calculate the cost of an name
@param _ the name to calculate the cost for

---

### fun `lookupAddress()`

```cadence
func lookupAddress(_ String): Address?
```
Lookup the address registered for a name

---

### fun `lookup()`

```cadence
func lookup(_ String): &{Profile.Public}?
```
Lookup the profile registered for a name

---

### fun `deposit()`

```cadence
func deposit(to String, from FungibleToken.Vault)
```
Deposit FT to name

Parameters:
  - to : _The name to send money too_
  - from : _The vault to send too_

---

### fun `outdated()`

```cadence
func outdated(): [String]
```
Used in script to return a list of names that are outdated

---

### fun `janitor()`

```cadence
func janitor(_ String): NameStatus
```
Task to janitor a name and lock/free it if appropriate

---

### fun `status()`

```cadence
func status(_ String): NameStatus
```
Return the status for a given name

Returns: The Name status of a name

---

### fun `createEmptyLeaseCollection()`

```cadence
func createEmptyLeaseCollection(): FIND.LeaseCollection
```

---

### fun `createEmptyBidCollection()`

```cadence
func createEmptyBidCollection(receiver Capability<&{FungibleToken.Receiver}>, leases Capability<&{FIND.LeaseCollectionPublic}>): BidCollection
```

---

### fun `createAdminProxyClient()`

```cadence
func createAdminProxyClient(): AdminProxy
```

---
## Events

### event `Locked`

```cadence
event Locked(name String, lockedUntil UFix64)
```
Emitted when a transaction involving a lease calculates that this lease is now locked

---

### event `Register`

```cadence
event Register(name String, owner Address, expireAt UFix64)
```
Emitted when a name is registred in FIND

---

### event `Moved`

```cadence
event Moved(name String, previousOwner Address, newOwner Address, expireAt UFix64)
```
Emitted when a name is moved to a new owner

---

### event `Freed`

```cadence
event Freed(name String, previousOwner Address)
```
Emitted when a name is freed

---

### event `Sold`

```cadence
event Sold(name String, previousOwner Address, newOwner Address, expireAt UFix64, amount UFix64)
```
Emitted when a name is sold to a new owner

---

### event `ForSale`

```cadence
event ForSale(name String, owner Address, expireAt UFix64, amount UFix64, active Bool)
```
Emitted when a name is explicistly put up for sale

---

### event `BlindBid`

```cadence
event BlindBid(name String, bidder Address, amount UFix64)
```
Emitted if a bid occurs at a name that is too low or not for sale

---

### event `BlindBidCanceled`

```cadence
event BlindBidCanceled(name String, bidder Address)
```
Emitted if a blind bid is canceled

---

### event `BlindBidRejected`

```cadence
event BlindBidRejected(name String, bidder Address, amount UFix64)
```
Emitted if a blind bid is rejected

---

### event `AuctionCancelled`

```cadence
event AuctionCancelled(name String, bidder Address, amount UFix64)
```
Emitted if an auction is canceled

---

### event `AuctionStarted`

```cadence
event AuctionStarted(name String, bidder Address, amount UFix64, auctionEndAt UFix64)
```
Emitted when an auction starts.

---

### event `AuctionBid`

```cadence
event AuctionBid(name String, bidder Address, amount UFix64, auctionEndAt UFix64)
```
Emitted when there is a new bid in an auction

---

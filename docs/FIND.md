# Contract `FIND`

```cadence
contract FIND {

    BidPublicPath:  PublicPath

    BidStoragePath:  StoragePath

    NetworkStoragePath:  StoragePath

    NetworkPrivatePath:  PrivatePath

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
## Structs & Resources

### struct `NameStatus`

```cadence
struct NameStatus {

    status:  LeaseStatus

    owner:  Address?
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

    auctionStartPrice:  UFix64?

    auctionReservePrice:  UFix64?

    auctionDuration:  UFix64

    auctionMinBidIncrement:  UFix64

    auctionExtensionOnLateBid:  UFix64

    offerCallback:  Capability<&BidCollection{BidCollectionPublic}>?

    addons:  {String: Bool}
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

    latestBidCallback:  Capability<&BidCollection{BidCollectionPublic}>

    name:  String
}
```

[More...](FIND_Auction.md)

---

### struct `LeaseInformation`

```cadence
struct LeaseInformation {

    name:  String

    address:  Address

    cost:  UFix64

    status:  String

    validUntil:  UFix64

    lockedUntil:  UFix64

    latestBid:  UFix64?

    auctionEnds:  UFix64?

    salePrice:  UFix64?

    latestBidBy:  Address?

    currentTime:  UFix64

    auctionStartPrice:  UFix64?

    auctionReservePrice:  UFix64?

    extensionOnLateBid:  UFix64?

    addons:  [String]
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

    registeredTime:  UFix64

    validUntil:  UFix64

    lockedUntil:  UFix64

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

    pricesChangedAt:  UFix64

    lengthPrices:  {Int: UFix64}

    addonPrices:  {String: UFix64}

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

    type:  String

    amount:  UFix64

    timestamp:  UFix64

    lease:  LeaseInformation?
}
```

[More...](FIND_BidInfo.md)

---

### resource `Bid`

```cadence
resource Bid {

    from:  Capability<&LeaseCollection{LeaseCollectionPublic}>

    name:  String

    type:  String

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

    leases:  Capability<&LeaseCollection{LeaseCollectionPublic}>
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
func createEmptyBidCollection(receiver Capability<&{FungibleToken.Receiver}>, leases Capability<&LeaseCollection{LeaseCollectionPublic}>): BidCollection
```

---

### fun `validateFindName()`

```cadence
func validateFindName(_ String): Bool
```

---

### fun `validateAlphanumericLowerDash()`

```cadence
func validateAlphanumericLowerDash(_ String): Bool
```

---

### fun `validateHex()`

```cadence
func validateHex(_ String): Bool
```

---
## Events

### event `Name`

```cadence
event Name(name String)
```
An event to singla that there is a name in the network

---

### event `AddonActivated`

```cadence
event AddonActivated(name String, addon String)
```

---

### event `Register`

```cadence
event Register(name String, owner Address, validUntil UFix64, lockedUntil UFix64)
```
Emitted when a name is registred in FIND

---

### event `Moved`

```cadence
event Moved(name String, previousOwner Address, newOwner Address, validUntil UFix64, lockedUntil UFix64)
```
Emitted when a name is moved to a new owner

---

### event `Sold`

```cadence
event Sold(name String, previousOwner Address, newOwner Address, validUntil UFix64, lockedUntil UFix64, amount UFix64)
```
Emitted when a name is sold to a new owner

---

### event `SoldAuction`

```cadence
event SoldAuction(name String, previousOwner Address, newOwner Address, validUntil UFix64, lockedUntil UFix64, amount UFix64)
```

---

### event `ForSale`

```cadence
event ForSale(name String, owner Address, validUntil UFix64, lockedUntil UFix64, directSellPrice UFix64, active Bool)
```
Emitted when a name is explicistly put up for sale

---

### event `ForAuction`

```cadence
event ForAuction(name String, owner Address, validUntil UFix64, lockedUntil UFix64, auctionStartPrice UFix64, auctionReservePrice UFix64, active Bool)
```
Emitted when an name is put up for on-demand auction

---

### event `DirectOffer`

```cadence
event DirectOffer(name String, bidder Address, bidderName String?, owner Address, ownerName String, amount UFix64)
```
Emitted if a bid occurs at a name that is too low or not for sale

---

### event `DirectOfferCanceled`

```cadence
event DirectOfferCanceled(name String, bidder Address, bidderName String?, owner Address, ownerName String)
```
Emitted if a blind bid is canceled

---

### event `DirectOfferRejected`

```cadence
event DirectOfferRejected(name String, bidder Address, bidderName String?, owner Address, ownerName String, amount UFix64)
```
Emitted if a blind bid is rejected

---

### event `AuctionCanceled`

```cadence
event AuctionCanceled(name String, bidder Address, bidderName String?, owner Address, ownerName String, amount UFix64)
```
Emitted if an auction is canceled

---

### event `AuctionCanceledReservePrice`

```cadence
event AuctionCanceledReservePrice(name String, bidder Address, bidderName String?, owner Address, ownerName String, amount UFix64)
```
Emitted if an auction is canceled because it did not reach the reserved price

---

### event `AuctionStarted`

```cadence
event AuctionStarted(name String, bidder Address, bidderName String?, owner Address, ownerName String, amount UFix64, auctionEndAt UFix64)
```
Emitted when an auction starts.

---

### event `AuctionBid`

```cadence
event AuctionBid(name String, bidder Address, bidderName String?, owner Address, ownerName String, amount UFix64, auctionEndAt UFix64)
```
Emitted when there is a new bid in an auction

---

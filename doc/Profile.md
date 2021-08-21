# Contract `Profile`

```cadence
contract Profile {

    publicPath:  PublicPath

    storagePath:  StoragePath
}
```

## Interfaces
    
### resource interface `Public`

```cadence
resource interface Public {
}
```

[More...](Profile_Public.md)

---
    
### resource interface `Owner`

```cadence
resource interface Owner {
}
```

[More...](Profile_Owner.md)

---
## Structs & Resources

### struct `Wallet`

```cadence
struct Wallet {

    name:  String

    receiver:  Capability<&{FungibleToken.Receiver}>

    balance:  Capability<&{FungibleToken.Balance}>

    accept:  Type

    tags:  [String]
}
```

[More...](Profile_Wallet.md)

---

### struct `ResourceCollection`

```cadence
struct ResourceCollection {

    collection:  Capability

    tags:  [String]

    type:  Type

    name:  String
}
```

[More...](Profile_ResourceCollection.md)

---

### struct `CollectionProfile`

```cadence
struct CollectionProfile {

    tags:  [String]

    type:  String

    name:  String
}
```

[More...](Profile_CollectionProfile.md)

---

### struct `Link`

```cadence
struct Link {

    url:  String

    title:  String

    type:  String
}
```

[More...](Profile_Link.md)

---

### struct `FriendStatus`

```cadence
struct FriendStatus {

    follower:  Address

    following:  Address

    tags:  [String]
}
```

[More...](Profile_FriendStatus.md)

---

### struct `WalletProfile`

```cadence
struct WalletProfile {

    name:  String

    balance:  UFix64

    accept:  String

    tags:  [String]
}
```

[More...](Profile_WalletProfile.md)

---

### struct `UserProfile`

```cadence
struct UserProfile {

    address:  Address

    name:  String

    description:  String

    tags:  [String]

    avatar:  String

    links:  [Link]

    wallets:  [WalletProfile]

    collections:  [CollectionProfile]

    following:  [FriendStatus]

    followers:  [FriendStatus]

    allowStoringFollowers:  Bool
}
```

[More...](Profile_UserProfile.md)

---

### resource `User`

```cadence
resource User {

    name:  String

    description:  String

    avatar:  String

    tags:  [String]

    followers:  {Address: FriendStatus}

    bans:  {Address: Bool}

    following:  {Address: FriendStatus}

    collections:  {String: ResourceCollection}

    wallets:  [Wallet]

    links:  {String: Link}

    allowStoringFollowers:  Bool
}
```

[More...](Profile_User.md)

---
## Functions

### fun `find()`

```cadence
func find(_ Address): &{Profile.Public}
```

---

### fun `createUser()`

```cadence
func createUser(name String, description String, allowStoringFollowers Bool, tags [String]): Profile.User
```

---

### fun `verifyTags()`

```cadence
func verifyTags(tags [String], tagLength Int, tagSize Int): Bool
```

---
## Events

### event `Follow`

```cadence
event Follow(follower Address, following Address, tags [String])
```

---

### event `Unfollow`

```cadence
event Unfollow(follower Address, unfollowing Address)
```

---

### event `Verification`

```cadence
event Verification(account Address, message String)
```

---

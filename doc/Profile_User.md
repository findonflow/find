# Resource `User`

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


Implemented Interfaces:
  - `Public`
  - `Owner`
  - `FungibleToken.Receiver`


### Initializer

```cadence
func init(name String, description String, allowStoringFollowers Bool, tags [String])
```


## Functions

### fun `addBan()`

```cadence
func addBan(_ Address)
```

---

### fun `removeBan()`

```cadence
func removeBan(_ Address)
```

---

### fun `getBans()`

```cadence
func getBans(): [Address]
```

---

### fun `isBanned()`

```cadence
func isBanned(_ Address): Bool
```

---

### fun `setAllowStoringFollowers()`

```cadence
func setAllowStoringFollowers(_ Bool)
```

---

### fun `verify()`

```cadence
func verify(_ String)
```

---

### fun `asProfile()`

```cadence
func asProfile(): UserProfile
```

---

### fun `getLinks()`

```cadence
func getLinks(): [Link]
```

---

### fun `addLink()`

```cadence
func addLink(_ Link)
```

---

### fun `removeLink()`

```cadence
func removeLink(_ String)
```

---

### fun `supportedFungigleTokenTypes()`

```cadence
func supportedFungigleTokenTypes(): [Type]
```

---

### fun `deposit()`

```cadence
func deposit(from FungibleToken.Vault)
```

---

### fun `getWallets()`

```cadence
func getWallets(): [Wallet]
```

---

### fun `addWallet()`

```cadence
func addWallet(_ Wallet)
```

---

### fun `removeWallet()`

```cadence
func removeWallet(_ String)
```

---

### fun `setWallets()`

```cadence
func setWallets(_ [Wallet])
```

---

### fun `removeFollower()`

```cadence
func removeFollower(_ Address)
```

---

### fun `follows()`

```cadence
func follows(_ Address): Bool
```

---

### fun `getName()`

```cadence
func getName(): String
```

---

### fun `getDescription()`

```cadence
func getDescription(): String
```

---

### fun `getTags()`

```cadence
func getTags(): [String]
```

---

### fun `getAvatar()`

```cadence
func getAvatar(): String
```

---

### fun `getFollowers()`

```cadence
func getFollowers(): [FriendStatus]
```

---

### fun `getFollowing()`

```cadence
func getFollowing(): [FriendStatus]
```

---

### fun `setName()`

```cadence
func setName(_ String)
```

---

### fun `setAvatar()`

```cadence
func setAvatar(_ String)
```

---

### fun `setDescription()`

```cadence
func setDescription(_ String)
```

---

### fun `setTags()`

```cadence
func setTags(_ [String])
```

---

### fun `removeCollection()`

```cadence
func removeCollection(_ String)
```

---

### fun `addCollection()`

```cadence
func addCollection(_ ResourceCollection)
```

---

### fun `getCollections()`

```cadence
func getCollections(): [ResourceCollection]
```

---

### fun `follow()`

```cadence
func follow(_ Address, tags [String])
```

---

### fun `unfollow()`

```cadence
func unfollow(_ Address)
```

---

### fun `internal_addFollower()`

```cadence
func internal_addFollower(_ FriendStatus)
```

---

### fun `internal_removeFollower()`

```cadence
func internal_removeFollower(_ Address)
```

---

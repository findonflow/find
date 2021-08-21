# Resource Interface `Public`

```cadence
resource interface Public {
}
```

## Functions

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

### fun `getCollections()`

```cadence
func getCollections(): [ResourceCollection]
```

---

### fun `follows()`

```cadence
func follows(_ Address): Bool
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

### fun `getWallets()`

```cadence
func getWallets(): [Wallet]
```

---

### fun `getLinks()`

```cadence
func getLinks(): [Link]
```

---

### fun `deposit()`

```cadence
func deposit(from FungibleToken.Vault)
```

---

### fun `supportedFungigleTokenTypes()`

```cadence
func supportedFungigleTokenTypes(): [Type]
```

---

### fun `asProfile()`

```cadence
func asProfile(): UserProfile
```

---

### fun `isBanned()`

```cadence
func isBanned(_ Address): Bool
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

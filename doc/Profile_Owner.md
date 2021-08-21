# Resource Interface `Owner`

```cadence
resource interface Owner {
}
```

## Functions

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

### fun `setTags()`

```cadence
func setTags(_ [String])
```

---

### fun `setDescription()`

```cadence
func setDescription(_ String)
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

### fun `verify()`

```cadence
func verify(_ String)
```

---

### fun `removeFollower()`

```cadence
func removeFollower(_ Address)
```

---

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

### fun `setAllowStoringFollowers()`

```cadence
func setAllowStoringFollowers(_ Bool)
```

---

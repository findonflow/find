# Resource Interface `CollectionPublic`

```cadence
resource interface CollectionPublic {
}
```

## Functions

### fun `deposit()`

```cadence
func deposit(token NonFungibleToken.NFT)
```

---

### fun `getIDs()`

```cadence
func getIDs(): [UInt64]
```

---

### fun `borrowNFT()`

```cadence
func borrowNFT(id UInt64): &NonFungibleToken.NFT
```

---

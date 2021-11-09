# Resource Interface `ViewResolverCollection`

```cadence
resource interface ViewResolverCollection {
}
```

## Functions

### fun `borrowViewResolver()`

```cadence
func borrowViewResolver(id UInt64): &{ViewResolver}
```

---

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

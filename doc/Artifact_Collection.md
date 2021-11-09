# Resource `Collection`

```cadence
resource Collection {

    ownedNFTs:  {UInt64: NonFungibleToken.NFT}
}
```


Implemented Interfaces:
  - `NonFungibleToken.Provider`
  - `NonFungibleToken.Receiver`
  - `NonFungibleToken.CollectionPublic`
  - `CollectionPublic`
  - `TypedMetadata.ViewResolverCollection`


### Initializer

```cadence
func init()
```


## Functions

### fun `withdraw()`

```cadence
func withdraw(withdrawID UInt64): NonFungibleToken.NFT
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

### fun `borrowViewResolver()`

```cadence
func borrowViewResolver(id UInt64): &{TypedMetadata.ViewResolver}
```

---

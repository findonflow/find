# Resource `NFT`

```cadence
resource NFT {

    id:  UInt64

    schemas:  {String: ViewInfo}

    name:  String

    sharedPointer:  Pointer?

    minterPlatform:  MinterPlatform
}
```


Implemented Interfaces:
  - `NonFungibleToken.INFT`
  - `TypedMetadata.ViewResolver`


### Initializer

```cadence
func init(initID UInt64, name String, schemas {String: ViewInfo}, sharedPointer Pointer?, minterPlatform MinterPlatform)
```


## Functions

### fun `getViews()`

```cadence
func getViews(): [Type]
```

---

### fun `resolveRoyalties()`

```cadence
func resolveRoyalties(): TypedMetadata.Royalties
```

---

### fun `resolveView()`

```cadence
func resolveView(_ Type): AnyStruct
```

---

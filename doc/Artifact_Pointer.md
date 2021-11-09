# Struct `Pointer`

```cadence
struct Pointer {

    collection:  Capability<&{TypedMetadata.ViewResolverCollection}>

    id:  UInt64

    views:  [Type]
}
```


### Initializer

```cadence
func init(collection Capability<&{TypedMetadata.ViewResolverCollection}>, id UInt64, views [Type])
```


## Functions

### fun `resolveView()`

```cadence
func resolveView(_ Type): AnyStruct
```

---

### fun `getViews()`

```cadence
func getViews(): [Type]
```

---

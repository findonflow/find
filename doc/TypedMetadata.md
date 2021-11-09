# Contract `TypedMetadata`

```cadence
contract TypedMetadata {
}
```

## Interfaces
    
### resource interface `TypeConverter`

```cadence
resource interface TypeConverter {
}
```

[More...](TypedMetadata_TypeConverter.md)

---
    
### resource interface `ViewResolverCollection`

```cadence
resource interface ViewResolverCollection {
}
```

[More...](TypedMetadata_ViewResolverCollection.md)

---
    
### resource interface `ViewResolver`

```cadence
resource interface ViewResolver {
}
```

[More...](TypedMetadata_ViewResolver.md)

---
## Structs & Resources

### struct `Royalties`

```cadence
struct Royalties {

    royalty:  {String: Royalty}
}
```

[More...](TypedMetadata_Royalties.md)

---

### struct `Royalty`

```cadence
struct Royalty {

    wallets:  {String: Capability<&{FungibleToken.Receiver}>}

    cut:  UFix64

    percentage:  Bool

    owner:  Address
}
```

[More...](TypedMetadata_Royalty.md)

---

### struct `Medias`

```cadence
struct Medias {

    media:  {String: Media}
}
```

[More...](TypedMetadata_Medias.md)

---

### struct `Media`

```cadence
struct Media {

    data:  String

    contentType:  String

    protocol:  String
}
```

[More...](TypedMetadata_Media.md)

---

### struct `CreativeWork`

```cadence
struct CreativeWork {

    artist:  String

    name:  String

    description:  String

    type:  String
}
```

[More...](TypedMetadata_CreativeWork.md)

---

### struct `Editioned`

```cadence
struct Editioned {

    edition:  UInt64

    maxEdition:  UInt64
}
```

[More...](TypedMetadata_Editioned.md)

---
## Functions

### fun `createPercentageRoyalty()`

```cadence
func createPercentageRoyalty(user Address, cut UFix64): Royalty
```

---

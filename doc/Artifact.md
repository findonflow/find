# Contract `Artifact`

```cadence
contract Artifact {

    ArtifactStoragePath:  StoragePath

    ArtifactPublicPath:  PublicPath

    totalSupply:  UInt64

    typeConverters:  {String: [Capability<&{TypedMetadata.TypeConverter}>]}
}
```


Implemented Interfaces:
  - `NonFungibleToken`

## Interfaces
    
### resource interface `CollectionPublic`

```cadence
resource interface CollectionPublic {
}
```

[More...](Artifact_CollectionPublic.md)

---
## Structs & Resources

### struct `ViewInfo`

```cadence
struct ViewInfo {

    typ:  Type

    result:  AnyStruct
}
```

[More...](Artifact_ViewInfo.md)

---

### resource `NFT`

```cadence
resource NFT {

    id:  UInt64

    schemas:  {String: ViewInfo}

    name:  String

    sharedPointer:  Pointer?

    minterPlatform:  MinterPlatform
}
```

[More...](Artifact_NFT.md)

---

### resource `Collection`

```cadence
resource Collection {

    ownedNFTs:  {UInt64: NonFungibleToken.NFT}
}
```

[More...](Artifact_Collection.md)

---

### struct `MinterPlatform`

```cadence
struct MinterPlatform {

    platform:  Capability<&{Profile.Public}>

    minter:  Capability<&{Profile.Public}>

    platformPercentCut:  UFix64

    name:  String
}
```

[More...](Artifact_MinterPlatform.md)

---

### resource `Forge`

```cadence
resource Forge {

    platform:  MinterPlatform
}
```

[More...](Artifact_Forge.md)

---

### struct `Profiles`

```cadence
struct Profiles {

    profiles:  {String: Profile.UserProfile}
}
```

[More...](Artifact_Profiles.md)

---

### struct `Pointer`

```cadence
struct Pointer {

    collection:  Capability<&{TypedMetadata.ViewResolverCollection}>

    id:  UInt64

    views:  [Type]
}
```

[More...](Artifact_Pointer.md)

---

### struct `Minter`

```cadence
struct Minter {

    name:  String
}
```

[More...](Artifact_Minter.md)

---

### resource `MinterTypeConverter`

```cadence
resource MinterTypeConverter {
}
```

[More...](Artifact_MinterTypeConverter.md)

---
## Functions

### fun `createForge()`

```cadence
func createForge(platform MinterPlatform): Forge
```

---

### fun `mintNFT()`

```cadence
func mintNFT(platform MinterPlatform, name String, schemas [AnyStruct]): NFT
```

---

### fun `mintNFTWithSharedData()`

```cadence
func mintNFTWithSharedData(platform MinterPlatform, name String, schemas [AnyStruct], sharedPointer Pointer): NFT
```

---

### fun `setTypeConverter()`

```cadence
func setTypeConverter(from Type, converters [Capability<&{TypedMetadata.TypeConverter}>])
```

---

### fun `createEmptyCollection()`

```cadence
func createEmptyCollection(): NonFungibleToken.Collection
```

---

### fun `createNewMinterTypeConverter()`

```cadence
func createNewMinterTypeConverter(): MinterTypeConverter
```

---
## Events

### event `ContractInitialized`

```cadence
event ContractInitialized()
```

---

### event `Withdraw`

```cadence
event Withdraw(id UInt64, from Address?)
```

---

### event `Deposit`

```cadence
event Deposit(id UInt64, to Address?)
```

---

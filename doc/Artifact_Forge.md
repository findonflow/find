# Resource `Forge`

```cadence
resource Forge {

    platform:  MinterPlatform
}
```


### Initializer

```cadence
func init(platform MinterPlatform)
```


## Functions

### fun `mintNFT()`

```cadence
func mintNFT(name String, schemas [AnyStruct]): NFT
```

---

### fun `mintNFTWithSharedData()`

```cadence
func mintNFTWithSharedData(name String, schemas [AnyStruct], sharedPointer Pointer): NFT
```

---

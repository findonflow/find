# Struct `MinterPlatform`

```cadence
struct MinterPlatform {

    platform:  Capability<&{Profile.Public}>

    minter:  Capability<&{Profile.Public}>

    platformPercentCut:  UFix64

    name:  String
}
```


### Initializer

```cadence
func init(name String, platform Capability<&{Profile.Public}>, minter Capability<&{Profile.Public}>, platformPercentCut UFix64)
```



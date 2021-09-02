# Struct `TagStatus`

```cadence
struct TagStatus {

    status:  LeaseStatus

    owner:  Address?

    persisted:  Bool
}
```


### Initializer

```cadence
func init(status LeaseStatus, owner Address?, persisted Bool)
```



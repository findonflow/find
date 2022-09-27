package utils

import (
	"fmt"
	"math/rand"
	"unsafe"

	"golang.org/x/crypto/sha3"
)

// Create a hash from the given ids and salt using '-' as the placeholder between salt an ids and , as the separator between ids
func CreateSha3Hash(input []uint64, types []string, salt string) string {

	joined := salt
	for i, id := range input {
		typ := types[i]
		joined = fmt.Sprintf("%s,%s-%d", joined, typ, id)
	}

	hash := sha3.Sum384([]byte(joined))
	packHash := fmt.Sprintf("%x", hash)

	return packHash

}

var alphabet = []byte("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")

func RandomSalt() string {
	size := 8
	b := make([]byte, size)
	rand.Read(b)
	for i := 0; i < size; i++ {
		b[i] = alphabet[b[i]/5]
	}
	return *(*string)(unsafe.Pointer(&b))
}

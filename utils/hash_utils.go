package utils

import (
	"fmt"
	"math/rand"
	"sort"
	"strings"
	"unsafe"

	"golang.org/x/crypto/sha3"
)

// Create a hash from the given ids and salt using '-' as the placeholder between salt an ids and , as the separator between ids
func CreateSha3Hash(input []uint64, salt string) string {
	sort.Slice(input, func(i, j int) bool { return input[i] < input[j] })
	joined := strings.Trim(strings.Replace(fmt.Sprint(input), " ", ",", -1), "[]")

	data := fmt.Sprintf("%s-%s", salt, joined)
	hash := sha3.Sum384([]byte(data))
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

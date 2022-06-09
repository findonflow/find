package main

import (
	"fmt"

	"github.com/bjartek/overflow/overflow"
)

func main() {

	// o := overflow.NewOverflowMainnet().Start()

	// user := "bjarte"

	// res := o.ScriptFromFile("testFacotryCollectionMainnet").Args(o.Arguments().String(user)).RunReturnsJsonString()
	// fmt.Println(res)

	o2 := overflow.NewOverflowTestnet().Start()

	user2 := "0xde5b0e922aeb76f5"

	res2 := o2.ScriptFromFile("testFacotryCollectionTestnet").Args(o2.Arguments().String(user2)).RunReturnsJsonString()
	fmt.Println(res2)

}

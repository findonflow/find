package main

import (
	"fmt"

	"github.com/bjartek/overflow/overflow"
)

func main() {

	// o := overflow.NewOverflowMainnet().Start()

	// user := "bjartek"

	// res := o.ScriptFromFile("testFactoryCollectionMainnet").Args(o.Arguments().String(user)).RunReturnsJsonString()
	// fmt.Println(res)

	o2 := overflow.NewOverflowTestnet().Start()

	user2 := "0x5a41930b8b435bdf"

	res2 := o2.ScriptFromFile("testFactoryCollectionTestnet").Args(o2.Arguments().String(user2)).RunReturnsJsonString()
	fmt.Println(res2)

}

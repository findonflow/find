package main

import (
	"fmt"

	"github.com/bjartek/overflow/v2"
)

func main() {
	o := overflow.Overflow(overflow.WithPrintResults())

	fmt.Println(o.GetNetwork())
}

package main

import (
	"fmt"

	"github.com/google/uuid"

	"example.com/repro/lib"
)

func main() {
	fmt.Println(lib.ID(), uuid.NewString())
}

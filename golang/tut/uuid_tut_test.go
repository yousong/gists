package main

import "testing"
import (
	"github.com/satori/go.uuid"
)

func TestUUID(t *testing.T) {
	var id uuid.UUID

	// current time and hardware address
	id, _ = uuid.NewV1()
	t.Logf("%s", id)

	// randomly generated uuid
	id, _ = uuid.NewV4()
	t.Logf("%s", id)
}

package lib

import "github.com/google/uuid"

// ID returns a new UUID string.
func ID() string {
	return uuid.NewString()
}

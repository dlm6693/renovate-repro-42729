module example.com/repro/app

go 1.24

require (
	example.com/repro/lib v0.0.0
	github.com/google/uuid v1.3.0
)

replace example.com/repro/lib => ../lib

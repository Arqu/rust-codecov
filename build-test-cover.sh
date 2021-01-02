#!/bin/bash

# set the destination for profile files
export LLVM_PROFILE_FILE="target/debug/coverage/%m.profraw"

# build the test binary with coverage instrumentation
executables=$(RUSTFLAGS="-Zinstrument-coverage" cargo test --tests --no-run --message-format=json | jq -r "select(.profile.test == true) | .executable")

# run instrumented tests
$executables

# combine profraw files
cargo profdata -- merge -sparse target/debug/coverage/*.profraw -o target/debug/coverage/combined.profdata

# collect coverage
cargo cov -- export $executables \
    --instr-profile=target/debug/coverage/combined.profdata \
    --ignore-filename-regex="$IGNORE_PATTERN" \
    --skip-functions \
    | cargo llvm-codecov-converter > $OUTPUT_PATH

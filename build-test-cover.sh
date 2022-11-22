#!/bin/bash

# set the destination for profile files
export LLVM_PROFILE_FILE="target/debug/coverage/%m.profraw"

# build the test binary with coverage instrumentation
executables=$(RUSTFLAGS="-Zinstrument-coverage" cargo +nightly test --tests --no-run --message-format=json | jq -r "select(.profile.test == true) | .executable")

# echo $executables

# run instrumented tests
executables=( $executables )
for i in "${executables[@]}"
do
    echo "Running $i"
    $i
done

# combine profraw files
cargo +nightly profdata -- merge -sparse target/debug/coverage/*.profraw -o target/debug/coverage/combined.profdata

# collect coverage
cargo +nightly cov -- export $executables \
    --instr-profile=target/debug/coverage/combined.profdata \
    --ignore-filename-regex="$IGNORE_PATTERN" \
    --skip-functions \
    | cargo +nightly llvm-codecov-converter > $OUTPUT_PATH

#!/usr/bin/env bash

set -euo pipefail  # Exit on error, undefined variable, and error in pipelines

# Function to verify the existence of required binaries
check_all_binaries_exist() {
    echo "Verifying the presence of required binaries..."

    # Define the list of required binaries
    REQUIRED_BINARIES=("test-connection" "benchmark" "kalypso-attestation-prover" "kalypso-cli")

    # Initialize an array to hold any missing binaries
    MISSING_BINARIES=()

    # Iterate over each required binary and check its existence and executability
    for binary in "${REQUIRED_BINARIES[@]}"; do
        if [ ! -x "./$binary" ]; then
            MISSING_BINARIES+=("$binary")
        fi
    done

    # If there are missing binaries, display an error and exit
    if [ "${#MISSING_BINARIES[@]}" -ne 0 ]; then
        echo "Error: The following required binaries are missing or not executable in the current directory:"
        for missing in "${MISSING_BINARIES[@]}"; do
            echo "  - $missing"
        done
        echo "Please ensure that all build steps completed successfully and the binaries are executable."
        exit 1
    else
        echo "All required binaries are present and executable in the current directory."
    fi
}

# Function to display usage instructions
usage() {
  echo "Usage: $0 {register-join|benchmark|test-connection|run-prover|symbiotic-stake|native-stake|claim-rewards|discard-request|read-stake|symbiotic-register|set-operator-meta|request-stake-withdrawal|read-pending-withdrawals|process-pending-withdrawals|check-reward|request-marketplace-exit}"
  echo
  echo "Options:"
  echo "  benchmark                      Run benchmark tests"
  echo "  check-reward                   Check Available Rewards"
  echo "  claim-rewards                  Claim Rewards"
  echo "  discard-request                Discard Request"
  echo "  leave-marketplace              Exit Marketplace"
  echo "  native-stake                   Stake your own tokens"
  echo "  process-pending-withdrawals    Process Pending Withdrawals"
  echo "  read-pending-withdrawals       Read Pending Withdrawals"
  echo "  read-stake                     Read Stake data"
  echo "  register-join                  Register and join the network"
  echo "  request-marketplace-exit       Request To Leave Marketplace"
  echo "  request-stake-withdrawal       Request Stake Withdrawal"
  echo "  run-prover                     Execute the prover service"
  echo "  set-operator-meta              Set Operator data"
  echo "  symbiotic-register             Register Operator with symbiotic"
  echo "  symbiotic-stake                Request Symbiotic Stake"
  echo "  test-connection                Test network connection"
  exit 1
}

# Cleanup function to handle termination
cleanup() {
  echo "Received termination signal. Cleaning up..."
  
  # Add any necessary cleanup commands here
  # For example, kill background processes if any
  # pkill -P $$  # Kills all child processes spawned by this script
  
  exit 0
}

# Trap SIGINT (Ctrl+C) and SIGTERM
trap cleanup SIGINT SIGTERM

# Verify binaries before proceeding
check_all_binaries_exist

# Check if at least one argument is provided
if [ $# -lt 1 ]; then
  echo "Error: No option provided."
  usage
fi

# Capture the first argument as the operation
OPERATION="$1"

# Export necessary environment variables
export CHAIN_ID="421614"
export PROOF_MARKETPLACE_ADDRESS="0xC05d689B341d84900f0d0CE36f35aDAbfB57F68d"
export GENERATOR_REGISTRY_ADDRESS="0x4743a2c7a96C9FBED8b7eAD980aD01822F9711Db"
export ENTITY_KEY_REGISTRY_ADDRESS="0x457D42573096b339bA48Be576e9Db4Fc5F186091"
export START_BLOCK="115108807"
export MARKET_ID="1"
export INDEXER_URL="https://kalypso-beta.justfortesting.me"

export STAKING_TOKEN="0xB5570D4D39dD20F61dEf7C0d6846790360b89a18"
export PAYMENT_TOKEN="0x8230d71d809718132C2054704F5E3aF1b86B669C"

# Execute based on the selected operation
case "$OPERATION" in
  register-join)
    # Temporarily disable exit on error for multistep process
    set +e

    export DECLARED_COMPUTE="10"
    export COMPUTE_PER_REQUEST="10"
    export PROPOSED_TIME="10000"
    
    echo "Starting registration and joining process..."
    
    # Run the first operation
    OPERATION_NAME="Register" ./kalypso-cli
    REGISTER_STATUS=$?
    echo "Registration process completed with exit status $REGISTER_STATUS"
    
    # Run the second operation regardless of the first one's result
    OPERATION_NAME="Join Marketplace" ./kalypso-cli
    JOIN_STATUS=$?
    echo "Join Marketplace process completed with exit status $JOIN_STATUS"
    
    # Re-enable exit on error
    set -e
    ;;

  request-marketplace-exit)
    # Temporarily disable exit on error for multistep process
    set +e
    
    # Run the first operation
    OPERATION_NAME="Request To Leave Marketplace" ./kalypso-cli
    STATUS=$?
    echo "Request to leave marketplace with exit status $STATUS"

    # Re-enable exit on error
    set -e
    ;;

  leave-marketplace)
    # Temporarily disable exit on error for multistep process
    set +e
    
    # Run the first operation
    OPERATION_NAME="Leave Marketplace" ./kalypso-cli
    STATUS=$?
    echo "Leave marketplace with exit status $STATUS"

    # Re-enable exit on error
    set -e
    ;;
  
  benchmark)
    echo "Running benchmark tests..."
    # Add your benchmark commands below
    RUST_BACKTRACE=1 ./benchmark &
    BENCHMARK_PID=$!
    wait "$BENCHMARK_PID"
    ;;
  
  test-connection)
    echo "Testing network connection..."
    # Add your connection test commands below
    ./test-connection --url "http://3.110.146.109:1500/attestation/raw" &
    HOST_PID=$!
    wait "$HOST_PID"
    ;;
  
  run-prover)
    export MAX_PARALLEL_PROOFS="1"
    export IVS_URL="http://3.110.146.109:3030"
    export PROVER_PORT=2020
    export PROMETHEUS_PORT=8888
    export POLLING_INTERVAL=10000
    
    echo "Executing the prover service..."
    # Add your prover execution commands below
    ./kalypso-attestation-prover &
    PROVER_PID=$!
    wait "$PROVER_PID"
    ;;
  
  symbiotic-stake)
    echo "Starting symbiotic stake request..."
    export SYMBIOTIC_CHAIN_ID="17000"
    export VAULT_OPT_IN_SERVICE="0x95CC0a052ae33941877c9619835A233D21D57351"
    export NETWORK_OPT_IN_SERVICE="0x58973d16FFA900D11fC22e5e2B6840d9f7e13401"
    
    OPERATION_NAME="Request Symbiotic Stake" ./kalypso-cli &
    SYM_PID=$!
    # Wait for background processes to finish
    wait "$SYM_PID"
    ;;

  native-stake)
    echo "Native Staking"
    export NATIVE_STAKING_ADDRESS="0x5F1666aEB646439157e139FF37637302168e6bb9"

    OPERATION_NAME="Native Stake" ./kalypso-cli &
    NAT_PID=$!
    # Wait for background processes to finish
    wait "$NAT_PID"
    ;;

  claim-rewards)
    echo "Claim Rewards"

    OPERATION_NAME="Claim Rewards" ./kalypso-cli &
    CLAIM_ID=$!
    # Wait for background processes to finish
    wait "$CLAIM_ID"
    ;;

  discard-request)
    echo "Discard Request"

    OPERATION_NAME="Discard Request" ./kalypso-cli &
    D_ID=$!
    # Wait for background processes to finish
    wait "$D_ID"
    ;;

  symbiotic-register)
    echo "Register Operator with symbiotic"

    export SYMBIOTIC_CHAIN_ID="17000"
    export SYMBIOTIC_OPERATOR_REGISTRY="0x6F75a4ffF97326A00e52662d82EA4FdE86a2C548"

    OPERATION_NAME="Symbiotic Operator Register" ./kalypso-cli &
    S_ID=$!
    # Wait for background processes to finish
    wait "$S_ID"
    ;;

  read-stake)
    echo "Read Operator Stake data"

    OPERATION_NAME="Read Stake Data" ./kalypso-cli &
    S_ID=$!
    # Wait for background processes to finish
    wait "$S_ID"
    ;;

  set-operator-meta) 
    echo "Update Operator Metadata"

    GENERATOR_META_JSON="./generatormeta.json"

    if [ ! -f "$GENERATOR_META_JSON" ]; then
      echo "Error: $GENERATOR_META_JSON NOT FOUND"
      exit 1
    else
      echo "Updating Operator Metadata from $GENERATOR_META_JSON"
    fi
    
    OPERATION_NAME="Update Generator Metadata" ./kalypso-cli &
    S_ID=$!
    # Wait for background processes to finish
    wait "$S_ID"
    ;;

  request-stake-withdrawal)
    echo "Request Stake Withdrawal"

    OPERATION_NAME="Request Native Stake Withdrawal" ./kalypso-cli &
    S_ID=$!
    # Wait for background processes to finish
    wait "$S_ID"
    ;;
    

  read-pending-withdrawals)
    echo "Read Pending Withdrawals"

    OPERATION_NAME="Read Native Staking Pending Withdrawals" ./kalypso-cli &
    S_ID=$!
    # Wait for background processes to finish
    wait "$S_ID"
    ;;

  process-pending-withdrawals)
    echo "Process Pending Withdrawals (if any)"
    
    OPERATION_NAME="Process Withdrawal Requests" ./kalypso-cli &
    S_ID=$!
    # Wait for background processes to finish
    wait "$S_ID"
    ;;

  check-reward)
    echo "Check Available Rewards"
    
    OPERATION_NAME="Read Rewards Info" ./kalypso-cli &
    S_ID=$!
    # Wait for background processes to finish
    wait "$S_ID"
    ;;

  *)
    echo "Error: Invalid option '$OPERATION'."
    usage
    ;;
esac

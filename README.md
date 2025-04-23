# Weaver Protocol

Weaver is an on-chain identity solution built within the Starknet ecosystem. It acts as a digital passport that verifies and showcases users' authenticity and contributions across various Starknet protocols.

## Contracts Overview

The Weaver protocol consists of several core contracts that work together to provide identity and contribution tracking:

1. **Weaver Contract** (`weaver.cairo`):
   - Main identity registry
   - Handles user registration
   - Manages protocol registration
   - Tracks user tasks and contributions

2. **WeaverNFT Contract** (`WeaverNFT.cairo`):
   - ERC721-compliant NFT contract
   - Mints identity NFTs for users
   - Tracks NFT ownership and minting history

3. **Protocol Contracts** (`protocols.cairo`, `protocolcomponent.cairo`, `protocolNFT.cairo`):
   - Protocol registration and management
   - Campaign creation and participation
   - Task creation and completion tracking
   - Protocol-specific NFT minting

4. **Interfaces** (`IWeaver.cairo`, `IWeaverNFT.cairo`, `Iprotocol.cairo`, etc.):
   - Standardized contract interfaces
   - Defines required functions for interoperability

5. **Utilities** (`Convert_felt_to_bytearray.cairo`):
   - Helper functions for data conversion

## Initialization and Setup

### Prerequisites
- Cairo and Starknet development environment
- Scarb package manager
- Starknet Foundry (for testing)

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/onlydustapp/weaver.git
   cd weaver
   ```
2. Install dependencies:
    ```bash
    scarb build
    ```
3. Set up testing environment:
    ```bash
    snforge
    ```

## Code Workflow

### User Flow
1. **Registration:**
    - Users register with the Weaver contract
    - Automatically receive a Weaver NFT
2. **Protocol Interaction:**
    - Protocols register with Weaver
    - Can create campaigns and tasks
    - Users join campaigns and complete tasks
3. **Contribution Tracking:**
    - Completed tasks are recorded on-chain
    - Users can mint NFTs for completed tasks
    - All activity is verifiable via the Weaver contract

### Contract Interactions
1. **Weaver Contract:**
    - Acts as the central registry
    - Coordinates between users, protocols, and NFTs
2. **WeaverNFT:**
    - Minted for user registration
    - Minted for protocol registration
    - Minted for task completion
3. **Protocol Contracts:**
    - Manage protocol-specific campaigns
    - Track task completion
    - Mint protocol-specific NFTs


## Running Tests

The test suite verifies all core functionality of the Weaver protocol.

### Test Structure
- `test_weaver_contract.cairo`: Tests for main Weaver contract
- `test_protocol_component.cairo`: Tests for protocol functionality

### Running Tests
1. **Run all tests:**
    ```bash
    snforge test  #or
    scarb test
    ```
2. **Run specific test file:**
    ```bash
    snforge test test_weaver_contract.cairo #or
    scarb test test_weaver_contract.cairo
    ```
3. **Run with detailed output:**
    ```bash
    snforge test -v #or
    scarb test -v
    ```

### Test Coverage
The tests cover:

- User registration
- Protocol registration
- Task creation and completion
- NFT minting
- Error cases and edge conditions
- Event emission


## Protocol Explanation
Weaver provides a comprehensive on-chain identity system with:

### Core Features
1. Digital Identity:
    - Unique NFT-based identity for each user
    - Verifiable on-chain credentials
2. Contribution Tracking:
    - Records user participation in protocols
    - Tracks task completion
    - Provides proof of work
3. Protocol Integration:
    - Standardized interface for protocols
    - Tools for campaign management
    - Contribution verification


### Use Cases
1. Developer Reputation:
    - Showcase contributions across Starknet ecosystem
    - Build verifiable reputation
2. Protocol Governance:
    - Identify active contributors
    - Weight voting power by contribution
3. Community Building:
    - Recognize and reward participation
    - Foster ecosystem engagement

### Technical Architecture
- Built on Starknet for scalability
- Uses Cairo for smart contracts
- Leverages ERC721 for identity NFTs
- Modular design for extensibility

## Additional Resources

For more information about the Weaver protocol, please refer to:

- [Project documentation](https://github.com/weaver-points)
- [Starknet developer resources](https://www.starknet.io/developers/)

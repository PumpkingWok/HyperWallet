# HyperWallet

A modular and secure smart wallet system designed for Hyperliquid's infrastructure, enabling seamless interaction between HyperEvm and Hyperliquid's Core.

## Overview

HyperWallet represents a cutting-edge wallet system that combines NFT-based ownership with a modular architecture to deliver secure and versatile asset management capabilities. Each wallet instance is uniquely represented by an NFT, granting the holder comprehensive control over the wallet's operations and features.

## Core Features

- **NFT-Based Ownership**: Each wallet is tied to a unique NFT, allowing for transferable ownership and control
- **Modular Architecture**: Extensible design that supports adding new functionality through modules
- **Multi-Action Support**: Execute multiple actions in a single transaction

## Getting Started

Install dependencies:
```bash
forge install
```

Build the project:
```bash
forge build
```

Run tests:
```bash
forge test
```

### Creating a New Wallet

Any address can create a new wallet through the `HyperWalletFactory`. When a wallet is created:
1. A new wallet contract is cloned (`HyperWallet`)
2. An NFT is minted to the creator's address
3. The NFT holder gains full control over the wallet's functionality

### Module System

The wallet's functionality can be extended through modules:
- Modules can be enabled/disabled by the wallet owner
- Each module can be granted specific permissions
- Multiple actions can be batched through modules
- Custom modules can be developed to add new features

### Available Modules

#### 1. Core Writer Module (LTS Module)
A module providing long-term support for Hyperliquid core interactions:
- Direct integration with Hyperliquid's core action system
- Efficient transaction routing through the core writer contract
- Seamless bridging between HyperEVM and Core operations
- Raw action execution capability (note: no data validation)

#### 2. Core Writer SDK Module (Version 1.0)
An enhanced interface built upon the Core Writer Module:
- Intuitive, human-readable function interfaces
- Standardized operation templates
- Simplified access to complex actions
- Version-specific implementation (requires updates for new core actions)

#### 3. Core Writer SDK Security Module
A security-enhanced version of the Core Writer SDK Module:
- Comprehensive security features built on Core Writer SDK Module
- Advanced validation of action parameters
- Proactive EVM-level transaction validation
- Prevention of failed core-side operations

#### 4. Enabler Module
A utility module designed to facilitate the initial account setup on Hyperliquid Core:
- Automates the account enabling process using evm funds, without any fund required at core.
- Handles the required HYPE and USDC token transfer for account activation

#### 5. Flash Loan Module
The FlashLoan module introduces an innovative lending mechanism that leverages HyperCore's spot balances. Unlike conventional flash loans that mandate repayment within the same transaction, this module enables users to borrow tokens against their Core spot account collateral, with repayment occurring in subsequent EVM blocks.

The current implementation requires liquidity providers to deposit tokens into the module contract. This V1 design prioritizes simplicity and security, while future iterations could incorporate:
- Fee structures for revenue generation
- Integration with ERC-4626 tokenized vaults
- Expanded liquidity provider incentives
- Advanced risk management systems

**Strategic Applications:**
This module bridges the async validation pattern between HyperEVM and HyperCore, enabling new use cases through immediate access to Core funds. Potential flash loan scenarios (ordered by risk level):

1. **Spot to EVM Transfer** (Lowest Risk)
   - Direct spot balance to system address transfer

2. **Perp to Spot to EVM**
   - USD class transfer from perpetual to spot
   - Subsequent transfer to system address

3. **Core Swap and Transfer**
   - Execute limit order swap on Core
   - Transfer resulting balance to system address

4. **Complex Perpetual Operations** (Highest Risk)
   - Execute perpetual market operations
   - Transfer proceeds through spot wallet
   - Final settlement to EVM

**Future Development:**
The module's architecture supports extension through new implementations featuring:
- Custom security policies
- Risk-based lending parameters
- Advanced collateralization mechanisms
- Automated risk assessment systems

## Contributing

We welcome contributions to the HyperWallet ecosystem! Here's how you can contribute:

### Ways to Contribute
- **Bug Reports**: Submit bug reports through GitHub issues
- **Module Requests**: Propose new module or improvements in the actual
- **Code Contributions**: Submit pull requests with improvements or new features

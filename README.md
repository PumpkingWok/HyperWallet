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

## Contributing

We welcome contributions to the HyperWallet ecosystem! Here's how you can contribute:

### Ways to Contribute
- **Bug Reports**: Submit bug reports through GitHub issues
- **Module Requests**: Propose new module or improvements in the actual
- **Code Contributions**: Submit pull requests with improvements or new features

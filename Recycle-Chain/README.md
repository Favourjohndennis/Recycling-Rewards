# Decentralized Recycling Rewards Smart Contract

## Overview

The Decentralized Recycling Rewards Smart Contract is a blockchain-based incentive system designed to promote environmental sustainability by rewarding users for recycling activities. Built on the Stacks blockchain using Clarity smart contract language, this system tokenizes recycling efforts and provides transparent, verifiable rewards for environmental stewardship.

## Features

### Core Functionality
- **User Registration**: Simple onboarding process for new participants
- **Recycling Submission**: Submit recycling activities with photo and location verification
- **Multi-Verifier System**: Requires multiple authorized verifiers to confirm recycling activities
- **Tokenized Rewards**: Automatic distribution of tokens based on material type and quantity
- **Material Type Support**: Six different recyclable material categories with varying reward multipliers
- **Reputation System**: User reputation scores that increase with verified recycling activities

### Security Features
- **Access Control**: Role-based permissions for different user types
- **Verification Timeout**: Time-limited verification windows to prevent stale submissions
- **Emergency Controls**: Contract pause functionality for emergency situations
- **Input Validation**: Comprehensive validation of all user inputs and system parameters

## Supported Material Types

| Material Type | ID | Reward Multiplier | Description |
|--------------|----|--------------------|-------------|
| Plastic | 1 | 1.2x | Plastic bottles, containers, packaging |
| Glass | 2 | 1.1x | Glass bottles, jars, containers |
| Metal | 3 | 1.5x | Aluminum cans, steel containers, metal scraps |
| Paper | 4 | 1.0x | Newspapers, cardboard, office paper |
| Electronic | 5 | 2.0x | E-waste, old electronics, batteries |
| Organic | 6 | 0.9x | Compostable organic waste |

## Contract Constants

### System Parameters
- **Base Reward**: 100 tokens per kg of recycled material
- **Minimum Recycling Amount**: 1 kg per submission
- **Maximum Recycling Amount**: 10,000 kg per submission
- **Verification Timeout**: 144 blocks (approximately 24 hours)
- **Default Verification Requirement**: 2 verifications per submission

### Initial Configuration
- **Rewards Pool**: 1,000,000 tokens
- **Material Types Supported**: 6 categories
- **Base Reputation Score**: 100 points for new users

## User Roles

### Regular Users
- Register in the system
- Submit recycling activities
- Receive token rewards
- Transfer tokens to other users
- Redeem tokens for benefits

### Authorized Verifiers
- Verify submitted recycling activities
- Must be approved by contract owner
- Typically environmental agencies or certified recycling centers

### Contract Owner
- Add/remove authorized verifiers
- Update reward multipliers
- Manage rewards pool
- Pause/unpause contract operations
- Update system parameters

## Key Functions

### User Functions

#### `register-user()`
Registers a new user in the system with initial reputation score.

#### `submit-recycling(material-type, weight-kg, location-hash, photo-hash)`
Submit a recycling activity for verification.
- `material-type`: Type of material recycled (1-6)
- `weight-kg`: Weight of recycled material in kilograms
- `location-hash`: Hash of location data for verification
- `photo-hash`: Hash of photo evidence

#### `transfer-tokens(from, to, amount)`
Transfer tokens between users.

#### `redeem-tokens(amount)`
Redeem tokens for rewards or benefits (burns tokens from circulation).

### Verifier Functions

#### `verify-recycling(submission-id)`
Verify a recycling submission (authorized verifiers only).

### Admin Functions

#### `add-verifier(verifier)`
Add a new authorized verifier to the system.

#### `remove-verifier(verifier)`
Remove an authorized verifier from the system.

#### `update-material-multiplier(material-type, multiplier)`
Update the reward multiplier for a specific material type.

#### `add-to-rewards-pool(amount)`
Add tokens to the rewards pool.

#### `pause-contract()` / `unpause-contract()`
Emergency functions to halt or resume contract operations.

## Read-Only Functions

### Data Retrieval

#### `get-user-profile(user)`
Returns user profile information including:
- Registration status
- Total recycled weight
- Total rewards earned
- Current reputation score
- Registration block height

#### `get-balance(user)`
Returns the token balance for a specific user.

#### `get-submission(submission-id)`
Returns detailed information about a specific recycling submission.

#### `get-contract-stats()`
Returns overall contract statistics:
- Total materials recycled across all users
- Total rewards distributed
- Current rewards pool balance
- Next submission ID

#### `calculate-reward(material-type, weight-kg)`
Calculates the reward amount for given material type and weight.

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| 100 | ERR-UNAUTHORIZED-ACCESS | User lacks required permissions |
| 101 | ERR-INSUFFICIENT-BALANCE | Insufficient token balance |
| 102 | ERR-INVALID-MATERIAL-TYPE | Invalid or unsupported material type |
| 103 | ERR-INVALID-AMOUNT | Invalid amount specified |
| 104 | ERR-SUBMISSION-NOT-FOUND | Recycling submission not found |
| 105 | ERR-ALREADY-VERIFIED | Submission already verified |
| 106 | ERR-VERIFICATION-EXPIRED | Verification period has expired |
| 107 | ERR-INVALID-VERIFIER | User not authorized to verify |
| 108 | ERR-USER-NOT-REGISTERED | User must register first |
| 109 | ERR-ALREADY-REGISTERED | User already registered |
| 110 | ERR-INSUFFICIENT-REWARDS-POOL | Not enough tokens in rewards pool |
| 111 | ERR-TRANSFER-FAILED | Token transfer failed |
| 112 | ERR-INVALID-MULTIPLIER | Invalid reward multiplier value |
| 113 | ERR-INVALID-HASH | Invalid hash provided |
| 114 | ERR-INVALID-PRINCIPAL | Invalid user principal |
| 115 | ERR-CONTRACT-PAUSED | Contract is currently paused |

## Usage Workflow

### For New Users
1. Call `register-user()` to join the system
2. Collect recyclable materials
3. Take photos and record location for verification
4. Submit recycling via `submit-recycling()` with required parameters
5. Wait for authorized verifiers to confirm submission
6. Receive tokens automatically upon successful verification
7. Use tokens for transfers or redemption

### For Verifiers
1. Get authorized by contract owner via `add-verifier()`
2. Monitor new submissions through blockchain events or queries
3. Verify legitimate recycling activities using `verify-recycling()`
4. Contribute to community trust and environmental goals

### For Administrators
1. Deploy contract with initial parameters
2. Add authorized verifiers for different regions/types
3. Monitor and adjust reward multipliers based on market conditions
4. Manage rewards pool to ensure sustainability
5. Handle emergency situations if needed

## Security Considerations

### Input Validation
- All user inputs are validated for type, range, and format
- Hash values are checked to ensure they contain actual data
- Principal addresses are validated to prevent null references
- Amount validations prevent zero or negative values

### Access Control
- Function-level permissions restrict sensitive operations
- Verifier authorization prevents unauthorized validation
- Owner-only functions protect critical system parameters

### Economic Security
- Verification requirements prevent single-point manipulation
- Time limits prevent stale or fraudulent submissions
- Reputation system incentivizes honest participation
- Rewards pool management ensures system sustainability

## Integration Guidelines

### Frontend Integration
- Query user profiles and balances for dashboard display
- Submit recycling activities with proper hash generation
- Monitor submission status and verification progress
- Display contract statistics and material multipliers

### Mobile App Considerations
- Implement photo capture and GPS location features
- Generate secure hashes for location and photo data
- Provide offline submission queuing for poor connectivity
- Display real-time token balances and transaction history

### API Integration
- Connect with external recycling center databases
- Integrate with environmental monitoring systems
- Support bulk verification for authorized processing centers
- Enable reward redemption through partner merchants

## Development and Testing

### Prerequisites
- Stacks blockchain development environment
- Clarity CLI tools for contract deployment
- Testing framework for comprehensive validation

### Deployment Steps
1. Configure initial parameters (rewards pool, material multipliers)
2. Deploy contract to chosen Stacks network
3. Add initial authorized verifiers
4. Test core functionality with small-scale submissions
5. Monitor system performance and adjust parameters
# StackLaunch - Decentralized Crowdfunding & Launchpad

A smart contract for decentralized crowdfunding and project launchpad on the Stacks blockchain.

## Overview

StackLaunch enables creators to launch campaigns and receive funding from the community while providing contributors with transparent, secure funding mechanisms on Bitcoin via Stacks.

## Features

**Campaign Creation** - Creators can launch campaigns with custom goals and deadlines
**Verified Campaigns** - Admin verification system ensures quality projects
**Funding Support** - Contributors can fund verified campaigns before deadline
**Goal Tracking** - Automatic detection when campaign reaches funding goal
**Fund Claiming** - Creators claim funds only when goal is met
**Refund Mechanism** - Contributors get refunds if campaign fails to meet goal
**Transparent Events** - All actions logged via contract events

## How It Works

### For Creators
1. Create a campaign with title, description, funding goal, and duration
2. Wait for admin verification
3. Once verified, receive funding from contributors
4. Claim funds when goal is reached before deadline expires
5. If goal not met, contributors can request refunds

### For Contributors
1. Browse verified campaigns
2. Fund campaigns before deadline with STX tokens
3. If goal is reached, creator claims funds
4. If goal is not met by deadline, claim your refund

## Contract Functions

### Public Functions
- `create-campaign` - Create a new funding campaign
- `verify-campaign` - Verify a campaign (admin only)
- `fund` - Contribute STX to a campaign
- `claim-funds` - Claim funds (creator only, goal must be met)
- `refund` - Get refund if campaign fails (contributor only)

### Read-Only Functions
- `get-campaign` - Retrieve campaign details
- `get-contribution` - Check contributor's funding amount
- `get-total-campaigns` - Get total number of campaigns

## Error Codes

| Code | Error | Meaning |
|------|-------|---------|
| 100 | ERR_NOT_CREATOR | Only creator can perform this action |
| 101 | ERR_ALREADY_FUNDED | Campaign already has funding |
| 102 | ERR_NOT_FOUND | Campaign doesn't exist |
| 103 | ERR_EXPIRED | Campaign deadline has passed |
| 104 | ERR_NOT_VERIFIED | Campaign hasn't been verified |
| 105 | ERR_ALREADY_CLAIMED | Funds already claimed |
| 106 | ERR_GOAL_NOT_MET | Funding goal not reached |
| 107 | ERR_INVALID_AMOUNT | Invalid amount provided |
| 108 | ERR_NOT_OWNER | Only owner can perform this action |

## Technical Details

- **Blockchain**: Stacks (Bitcoin settlement)
- **Language**: Clarity
- **Token**: STX (Stacks Token)
- **Verification**: On-chain event logging via `print` statements

## Development

### Prerequisites
- Clarinet CLI
- Node.js 14+

### Running Tests
```bash
clarinet test

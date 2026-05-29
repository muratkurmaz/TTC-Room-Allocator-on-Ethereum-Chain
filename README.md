# Room Allocator on Blockchain

A Solidity smart contract for allocating and exchanging student rooms using preference-based coordination.

The project implements a room allocation system where students are initially assigned available rooms, submit ranked room preferences, request mutually beneficial bilateral swaps, and optionally run a coordinated exchange mechanism based on **Top Trading Cycles (TTC)**.

## Overview

Room allocation can be inefficient when students are randomly assigned rooms but have different preferences. This contract models a decentralised allocation process where room ownership and exchanges are recorded on-chain.

The main mechanism is implemented in `coordinatedExchange()`, which uses TTC-style cycle detection to reallocate rooms while preserving one-to-one ownership and improving outcomes according to submitted preferences.

## Features

- Register a fixed number of rooms at deployment
- Allow students to register and receive an initial room allocation
- Store full or partial preference rankings for rooms
- Automatically complete partial preference lists
- Support bilateral room exchanges only when both students strictly improve
- Run a coordinated TTC-style exchange across registered students
- Query room ownership, student allocation, and student preferences

## Repository Structure

```text
.
├── contracts/
│   └── RoomAllocation.sol
├── docs/
│   ├── design-notes.md
│   └── testing-notes.md
├── scripts/
│   └── deploy.js
├── test/
│   └── README.md
├── hardhat.config.js
├── package.json
├── .gitignore
└── README.md
```

## Smart Contract

The core contract is:

```text
contracts/RoomAllocation.sol
```

Main functions:

| Function | Purpose |
|---|---|
| `registerStudent()` | Registers a student and assigns an available room |
| `setPreferences(uint256[] memory)` | Stores a student’s ranked room preferences |
| `checkAllocation()` | Returns the caller’s current room allocation |
| `requestExchange(address)` | Performs a mutually beneficial bilateral room swap |
| `getStudentByRoom(uint256)` | Returns the current owner of a room |
| `getPreferences(address)` | Returns a student’s preference list |
| `coordinatedExchange()` | Runs the TTC-style coordinated exchange mechanism |

## Requirements

- Node.js
- npm
- Hardhat

Install dependencies:

```bash
npm install
```

## Compile

```bash
npm run compile
```

## Test

A test directory is included as a placeholder for Hardhat tests.

```bash
npm test
```

## Deploy Locally

Start a local Hardhat node:

```bash
npx hardhat node
```

In another terminal, deploy with an example room count:

```bash
npm run deploy -- --network localhost
```

## Mechanism Summary

The coordinated exchange mechanism follows four stages:

1. Each unmatched student points to the current owner of their most preferred available room.
2. The contract follows these pointers to detect cycles.
3. Students in each cycle simultaneously receive their pointed-to rooms.
4. The process repeats until no unmatched students remain or no further cycles can be formed.

This approach is intended to produce preference-respecting reallocations while maintaining unique room ownership.

## Author

Murat Kurmaz

## License

This project is released under the MIT License.

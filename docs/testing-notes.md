# Testing Notes

The original coursework notes describe the following intended test coverage.

## Basic Validations

- Constructor rejects zero rooms.
- `coordinatedExchange()` rejects calls when no students are registered.
- `registerStudent()` rejects registration after all rooms are full.
- Invalid room IDs and duplicate preferences are rejected.
- Partial preference lists are automatically completed.

## Bilateral Exchange Tests

- A mutually beneficial swap should succeed.
- A swap where either student would be worse off should revert.
- A student cannot exchange with themselves.
- The requested target student must be registered.

## Coordinated Exchange Tests

- Final room assignments should remain one-to-one.
- No room should be assigned to more than one student.
- Registered students should retain a valid room allocation.
- TTC-style cycles should execute without breaking room ownership mappings.

## Gas and Size Checks

The contract was designed as an educational on-chain allocation mechanism. For larger groups, gas usage should be monitored because the TTC-style exchange scans preference lists and stores participant state on-chain.

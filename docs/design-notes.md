# Design Notes

## Coordination Mechanism

The contract uses a Top Trading Cycles style mechanism inside `coordinatedExchange()`.

The process works as follows:

1. Each registered student who has not yet been finalised points to the current owner of their highest-ranked room that has not already been taken in the coordinated exchange.
2. The contract follows the resulting pointer graph to detect cycles.
3. When a cycle is found, every student in the cycle is reassigned to the room they pointed to.
4. The students and rooms involved in that cycle are marked as complete.
5. The process repeats until all students are processed or no further progress can be made.

## Additional State

The implementation uses two additional state variables to support iteration and lookup:

```solidity
address[] internal studentList;
mapping(address => uint256) internal studentIndex;
```

`studentList` stores the registered students so that the exchange algorithm can iterate over participants.

`studentIndex` maps each student address to its index in `studentList`, allowing the algorithm to translate room ownership into array positions during cycle construction.

## Preference Handling

Students may submit a full or partial room ranking. If a partial preference list is submitted, the contract validates the provided room IDs, rejects duplicates, and then appends the remaining room IDs in ascending order.

This ensures every registered student has a complete preference list over all rooms.

## Bilateral Exchange

The `requestExchange(address)` function only allows a swap when both students strictly prefer the other student's room over their current room.

This is checked using:

```solidity
_better(address student, uint256 candidateRoom, uint256 currentRoom)
```

which compares the rank positions of the two rooms in the student's preference list.

## Complexity

For `N` students and `M` rooms, the coordinated exchange mechanism performs preference scans while building cycles. The practical complexity is approximately `O(N * M)`, which is suitable for small to medium educational examples.

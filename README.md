# Betunfair
A betting exchange platform implementation from Universidad Politécnica de Madrid students.

## Structure
For this application, a **supervisor** are used with **CubDB** as database library.

The supervisor handles database process recovers if there is a halt.

## Database

For saving the information, we opted to use *CubDB*. Write operations are made in a transactions and read operations are made in snapshots, looking for robustness in atomic operations.

There are 3 "tables" in the database: users, markets and bets.
They are implemented in the key-value structure CubDB offers with and adiccional key.
E.g. `CubDB.get(Database,{:user,1})` looks for a user with id "1".


## Testing

For runing tests, run the command:
`mix test`

## Decisions

Bet parcially cancelled: If a bet is cancelled and has stake matched, the remaining stake goes to 0 but remains ":active".

Stop the exchange: If the exchange is down when method `stop()` is called, no operation is done.

Clean the exchange: the method `clean()` calls `stop()`, terminating the running exchange if is the case. This is done
to avoid concurrency problems.

Bet has a field date for ordering in `market_pending_backs()` and `market_pending_lays()` (apart from the odds, obviously).



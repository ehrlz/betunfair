# Betunfair - Elixir Betting Exchange Platform
A betting exchange platform project for exploring the Elixir programming language through the lens of a compact yet functional betting exchange platform. This endeavor serves as a practical playground for enhancing my Elixir skills while delving into the fascinating world of betting systems.

![Elixir](https://img.shields.io/badge/elixir-%234B275F.svg?style=for-the-badge&logo=elixir&logoColor=white)

## What is Betunfair?
Betunfair is a modest implementation designed for personal learning, emphasizing the following key aspects:

- **Elixir Mastery**: Seamlessly blend your journey into Elixir with the construction of a practical betting exchange. Gain hands-on experience with Elixir's syntax, concurrency model, and fault-tolerant features.

- **Supervisor Patterns**: Witness the application of supervisor patterns in managing concurrent processes, ensuring the system's robustness and fault recovery.

- **CubDB Database Integration**: Explore the integration of CubDB, a key-value store, for handling essential database operations. Learn the nuances of transactional writes and snapshot-based reads.

- **Scalable System Basics**: Grasp fundamental principles of scalable system design while keeping the project concise and easy to understand.



## Betting Exchange System
Betunfair is based on the betting exchange system, allowing users to both back and lay bets on a specific event. This system is inspired by the concept popularized by Betfair, where users can not only bet in favor of an event (backing) but also bet against it (laying).

## Technical details
### Database
Betunfair utilizes **CubDB** as its database library. The choice of CubDB is motivated by its key features, allowing write operations in transactions and read operations in snapshots. This approach enhances robustness in atomic operations.

The database consists of three main "tables": **users**, **markets**, and **bets**. Each is implemented using CubDB's key-value structure with an additional key. For example, querying a user with id "1" can be done with:
`CubDB.get(Database, {:user, 1})`.

### Matching Mechanism

The matching mechanism is at the core of Betunfair's functionality. `market_match/1` function facilitates the matching process between back and lay bets. The algorithm iterates through the order books of pending backs and lays, identifying potential matches based on odds. When a match is found, the stake adjustments are handled, ensuring a seamless transaction.

## How to use it?

### Prerequisites
Make sure you have Elixir and Mix (Elixir's build tool) installed on your system. You can install them by following the official instructions at https://elixir-lang.org/install.html.

### Install
1. Get the code:
```
git clone https://github.com/your-username/Betunfair.git

cd Betunfair
```
2. Install the dependencies
```
mix deps.get
```

3. Run the tests
```
mix test
```

4. Start an interactive Elixir shell
```
iex -S mix
```

5. You can now explore the functionalities of the betting exchange platform directly from the Elixir shell. For example, you can create users, place bets, and interact with the implemented features. An example:
``` elixir
{:ok, user_id} = Betunfair.user_create("john_doe", "John Doe")

Betunfair.user_deposit(user_id, 100)

{:ok, bet_id} = Betunfair.bet_back(user_id, "market_id", 10, 3.00)
```

## Testing
To run tests and ensure the integrity of the application, execute the following command:
`mix test`

## Design Decisions
### Partially Cancelled Bets
In the event of a bet cancellation with a matched stake, the remaining stake is reduced to 0 but remains labeled as `:active`.

### Exchange Operations
- Stop the Exchange: If the exchange is down when `stop()` is called, no operation is performed, ensuring the safety of the system.

- Clean the Exchange: `clean()` method calls `stop()`, terminating the running exchange if necessary. This approach is implemented to mitigate potential concurrency problems.

- Date Field for Bet Ordering: Bets include a date field to facilitate ordering in the `market_pending_backs()` and `market_pending_lays()` methods, in addition to considering odds.

## Future work

* Telegram API
* Rest API
* Web interface with Phoenix
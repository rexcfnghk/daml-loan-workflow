# Daml Loan Worflow ![CI Status](https://github.com/rexcfnghk/daml-loan-workflow/actions/workflows/docker-image.yml/badge.svg)

A demonstration on modelling a loan workflow. The repository is split into three subfolders [Q1], [Q2], and [Q3].

[Q1]: ./Q1/
[Q2]: ./Q2/
[Q3]: ./Q3/

## Development Quick Start

### Building from source

You need to have [Daml] installed.

[Daml]: https://docs.daml.com

Change directory to the question folder you would like to build. We will use [Q1] as an example.

```bash
cd ./Q1
daml build
```

This will build you Daml code once.

### Testing

Each subfolder contains tests written with Daml Script. They can run using

```bash
cd ./Q1
daml test
```

### Containerisation

A [Dockerfile] is also provided to run the tests under all subfolders. This is used in the [GitHub action] for continuous integration.

[Dockerfile]: ./Dockerfile
[GitHub action]: ./.github/docker-image.yml

## Design Decisions/Considerations

### Q1

For this question, the simplest approach was taken. As two templates `LoanRequest`, `Loan` are required, these form a [Propose and Accept pattern](https://docs.daml.com/daml/patterns/propose-accept.html) to allow two signatories, the `bank` and the `borrower` to come into a bilateral agreement when creating a `Loan` contract.

Common sense assertions are also used in the form of `ensure` clauses to prevent the creation of invalid contracts (e.g. negative amount `Loan`s, having a loan contract where the `bank` and the `borrower` are the same party).

Tests are also in place to validate the logic.

### Q2

As the requirements ask for a `Token` template, a UTXO-based mechanism is coded when handling token disbursement, i.e. disbursing will not mutate existing minted tokens. Instead, new tokens are minted to reflect newly disbursed tokens. These tokens are recorded in the `disbursement` field of the `Loan` template to facilitate assertions that total disbursed amount must not exceed the total approved amount for the `Loan` contract.

There are no requirements for this question to specify how tokens are consumed by the borrower, thus it is assumed to be out-of-scope for the Daml workflow model. As a result, the `disbursement` field only stores a list of `Token`s, not a list of `ContractId Token`s. It is expected of the actor of the `Disburse` choice to keep track of returned `ContractId Token`s. The new `ContractId Loan` with the updated `disbursement` list and the newly minted token's contract ID are returned by the choice in the form of a tuple.

To address the requirement for allowing either the `bank` or the `borrower` to exercise the `Disburse` choice, an assertion is used to ensure the actor is either the `bank` or the `borrower`. Using the `controller bank, controller` syntax would not work in this case as this syntax would require both the `bank`'s *and* the `borrower`'s consent to exercise the choice.

For the `LoanLimit` template, it is a deliberate decision to only have one single party, the `bank`, as the signatory because no borrowers should be privy to a bank's loan limit, which is considered internal information of the bank's operations.

Another design choice here is the use of [Applicatives](https://docs.daml.com/daml/stdlib/Prelude.html#class-da-internal-prelude-applicative-9257) instead of [Actions](https://docs.daml.com/daml/stdlib/DA-Action.html) (equivalent to Haskell's monads). Because many choices involve archiving/creating contracts that has no dependencies on monadic values before the expressions, writing these choices in an applicative style could potentially improve performance by parallelising.

### Q3

The biggest difference between Q2 and Q3 is the fact that `Token`s can now be consumed when repaying a `Loan`, which is why a more sophisticated mechanism of handling `Token`s is created. Instead of storing a list of `Token`s in the `disbursement` field, the contract IDs of `Token` are now stored as the need to handle archiving tokens when they are consumed for repayment is required. This allows a more flexible processing of the `Token`'s lifecycle in a `Loan`.

An identifier field for a `Loan` contract, is also introduced for this question as it is not unusual for a `borrower` to have multiple loans made with the same `bank`. As each `Loan` might have different repayment restrictions, a stable contract key is required to link a `Loan` contract to its `RepaymentRestriction` contract. Using only the `bank` and the `borrower` as the key would not suffice as there would be a key collision when there are multiple loans.

The `Repay` choice of the `Loan` contract requires the simultaneous consent of both the `bank` and the `borrower`. After some thought, I came to the conclusion that this is a reasonable assumption as part of the repayment logic would require the archival of `Token`s or the archival of the `LoanLimit` contract, both require the `bank`'s consent to perform. Initially, the [Delegation Pattern](https://docs.daml.com/daml/patterns/delegation.html) was also considered but it was discarded eventually because assuming repayments require both the `bank`'s' and the `borrower`'s consent seems to match more closely to the real-life business scenario.

The repaid amount of a `Loan` is kept track of in `Loan.repaidAmount`. It is updated every time the `Repay` choice is called, provided the repaid amount is valid.

The algorithm for performing the repayment, from a high-level perspective, does the following:

1. Assert preconditions to make sure the processing can proceed in a reasonable manner, such as checking if the repayment amount is greater than the minimum repayment amount specified in `RepaymentRestriction`.
2. Retrieve all existing disbursed tokens by doing `fetch`es on the list of `ContractId Token`.
3. Build a `Map (ContractId Token) Token` so that the `ContractId Token` and the `Token` itself can be tracked together, as archiving would require the contract IDs.
4. Divide the map into two portions, one with entries of tokens greater than or equal to the repayment amount, and one with entries less than the repayment account.
5. If the former portion is not empty, then return the token with the minimum value to fulfil the repayment.
6. Else, pick a combination of tokens in the latter portion until their value is greater than or equal to the repayment amount.
7. Determine if change is needed as the tokens picked might have a value greater than the repayment amount.
8. If change is needed, mint a token that has the change amount as the value
9. Else, determine whether the loan is paid off when the sum of repayment and the repaid amount is greater than the approved amount
10. If the loan is paid off, archive the `Loan`, the `RepaymentRestriction` and the `Token`s used in repayment. Update the `LoanLimit` to release the funds used in the loan's approved amount.
11. Else, return a new `Loan` contract with updated disbursements with an optional `Token` for the change.

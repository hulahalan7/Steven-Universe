# Transparent Donations - A Clarinet Project

This project demonstrates a simple, yet powerful, use case for smart contracts: creating a transparent and auditable donation system on the Stacks blockchain.

It aims to address a real-world problem: the lack of trust and transparency in traditional charitable giving. By using a smart contract, all donations and withdrawals are recorded on an immutable public ledger, ensuring that anyone can verify the flow of funds.

## Features

- **Accept Donations:** Anyone can donate STX to the contract.
- **Track Totals:** The contract keeps a running total of all donations.
- **Transparent Ledger:** All transactions are public and verifiable.
- **Secure Withdrawals:** Only the designated contract owner can withdraw funds to a pre-defined beneficiary address.

## How to Use

1.  **Check the contract:** `clarinet check`
2.  **Run tests:** `npm test`
3.  **Deploy:** `clarinet contract deploy transparent-donations`

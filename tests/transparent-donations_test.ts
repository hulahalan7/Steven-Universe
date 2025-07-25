import { describe, expect, it, beforeEach } from "vitest";
import { simnet, Simnet } from "@hirosystems/clarinet-sdk";
import { Cl } from "@stacks/transactions";

const contract = "transparent-donations";

describe("Transparent Donations Contract", () => {
  let simnet: Simnet;
  let deployer: string;
  let wallet1: string;
  let beneficiary: string;

  beforeEach(() => {
    simnet = new Simnet();
    const accounts = simnet.getAccounts();
    deployer = accounts.get("deployer")!;
    wallet1 = accounts.get("wallet_1")!;
    beneficiary = accounts.get("beneficiary")!;
  });

  it("allows users to donate and updates totals correctly", () => {
    const amount = 1000;
    const response = simnet.callPublicFn(
      contract,
      "donate",
      [Cl.uint(amount)],
      wallet1
    );

    // Check response is ok
    expect(response.result).toBeOk(Cl.bool(true));

    // Check contract balance
    const contractBalance = simnet.getAssetsMap().get("STX")?.get(simnet.getContractAddress(contract));
    expect(contractBalance).toBe(BigInt(amount));

    // Check total donations received variable
    const totalDonations = simnet.callReadOnlyFn(contract, "get-total-donations-received", [], deployer);
    expect(totalDonations.result).toBeOk(Cl.uint(amount));

    // Check donation by address
    const wallet1Donations = simnet.callReadOnlyFn(contract, "get-donation-by-address", [Cl.principal(wallet1)], deployer);
    expect(wallet1Donations.result).toBeOk(Cl.uint(amount));
  });

  it("prevents non-owner from withdrawing funds", () => {
    // First, donate some funds
    simnet.callPublicFn(contract, "donate", [Cl.uint(1000)], wallet1);

    // Attempt to withdraw from a non-owner account
    const response = simnet.callPublicFn(
      contract,
      "withdraw",
      [Cl.uint(500)],
      wallet1 // wallet1 is not the owner
    );

    // Expect unauthorized error (err u100)
    expect(response.result).toBeErr(Cl.uint(100));
  });

  it("allows owner to withdraw funds to beneficiary and updates disbursed total", () => {
    const donationAmount = 5000;
    const withdrawAmount = 2000;

    // Donate funds first
    simnet.callPublicFn(contract, "donate", [Cl.uint(donationAmount)], wallet1);

    const beneficiaryInitialBalance = simnet.getAssetsMap().get("STX")?.get(beneficiary);

    // Owner withdraws funds
    const response = simnet.callPublicFn(
      contract,
      "withdraw",
      [Cl.uint(withdrawAmount)],
      deployer // deployer is the owner
    );

    // Check response is ok
    expect(response.result).toBeOk(Cl.bool(true));

    // Check contract balance is reduced
    const contractBalance = simnet.getAssetsMap().get("STX")?.get(simnet.getContractAddress(contract));
    expect(contractBalance).toBe(BigInt(donationAmount - withdrawAmount));

    // Check beneficiary balance is increased
    const beneficiaryFinalBalance = simnet.getAssetsMap().get("STX")?.get(beneficiary);
    expect(beneficiaryFinalBalance).toBe(beneficiaryInitialBalance! + BigInt(withdrawAmount));

    // Check total donations received variable is unchanged
    const totalDonations = simnet.callReadOnlyFn(contract, "get-total-donations-received", [], deployer);
    expect(totalDonations.result).toBeOk(Cl.uint(donationAmount));

    // Check total disbursed variable is increased
    const totalDisbursed = simnet.callReadOnlyFn(contract, "get-total-disbursed", [], deployer);
    expect(totalDisbursed.result).toBeOk(Cl.uint(withdrawAmount));
  });

  it("fails withdrawal if amount is greater than contract balance", () => {
    const donationAmount = 1000;
    const withdrawAmount = 2000;

    // Donate funds
    simnet.callPublicFn(contract, "donate", [Cl.uint(donationAmount)], wallet1);

    // Attempt to withdraw more than available
    const response = simnet.callPublicFn(
      contract,
      "withdraw",
      [Cl.uint(withdrawAmount)],
      deployer
    );

    // Expect insufficient funds error (err u103)
    expect(response.result).toBeErr(Cl.uint(103));
  });
});
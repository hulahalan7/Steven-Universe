;; transparent-donations.clar
;; A simple contract for transparent charitable donations.

;; ---
;; Constants
;; ---
(define-constant CONTRACT_OWNER tx-sender) ;; The deployer is the owner

;; ---
;; Errors
;; ---
(define-constant ERR_UNAUTHORIZED u100)
(define-constant ERR_TRANSFER_FAILED u101)
(define-constant ERR_NOTHING_TO_WITHDRAW u102)
(define-constant ERR_INSUFFICIENT_FUNDS u103)
(define-constant ERR_ZERO_DONATION u104)

;; ---
;; Data Storage
;; ---
(define-data-var beneficiary-address principal 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG)
(define-data-var total-donations-received uint u0)
(define-map donations principal uint)
(define-data-var total-disbursed uint u0)

;; ---
;; Public Functions
;; ---

;; @desc Donate STX to the cause.
;; @param amount The amount of STX to donate.
;; @returns (ok bool) on success, or an error code.
(define-public (donate (amount uint))
  (begin
    ;; Prevent zero-amount donations which just add to chain history with no value
    (asserts! (> amount u0) (err ERR_ZERO_DONATION))

    ;; Transfer STX from the sender to this contract
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))

    ;; Update total donations
    (var-set total-donations-received (+ (var-get total-donations-received) amount))

    ;; Update individual's donation amount
    (map-set donations tx-sender (+ (default-to u0 (map-get? donations tx-sender)) amount))

    ;; Print an event for off-chain indexing
    (print {
      type: "donation",
      donor: tx-sender,
      amount: amount
    })

    (ok true)
  )
)

;; @desc The contract owner can withdraw funds to the beneficiary.
;; @param amount The amount of STX to withdraw.
;; @returns (ok bool) on success, or an error code.
(define-public (withdraw (amount uint))
  (begin
    ;; Only the contract owner can withdraw
    (asserts! (is-eq tx-sender CONTRACT_OWNER) (err ERR_UNAUTHORIZED))
    (asserts! (> amount u0) (err ERR_NOTHING_TO_WITHDRAW))

    ;; Check if contract has enough funds
    (asserts! (>= (stx-get-balance (as-contract tx-sender)) amount) (err ERR_INSUFFICIENT_FUNDS))

    ;; Transfer STX from the contract to the beneficiary
    (match (as-contract (stx-transfer? amount (as-contract tx-sender) (var-get beneficiary-address)))
      success (begin
        ;; Update the total amount disbursed
        (var-set total-disbursed (+ (var-get total-disbursed) amount))
        (print {
          type: "withdrawal",
          recipient: (var-get beneficiary-address),
          amount: amount
        })
        (ok true)
      )
      error (err ERR_TRANSFER_FAILED)
    )
  )
)

;; @desc Allows the contract owner to update the beneficiary address.
;; @param new-beneficiary The new principal to receive funds.
;; @returns (ok bool)
(define-public (set-beneficiary (new-beneficiary principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) (err ERR_UNAUTHORIZED))
    (var-set beneficiary-address new-beneficiary)
    (ok true)
  )
)

;; ---
;; Read-Only Functions
;; ---

;; @desc Get the total amount of STX donated.
;; @returns (response uint uint)
(define-read-only (get-total-donations-received)
  (ok (var-get total-donations-received))
)

;; @desc Get the donation amount for a specific principal.
;; @param donor The principal to query.
;; @returns (response uint uint)
(define-read-only (get-donation-by-address (donor principal))
  (ok (default-to u0 (map-get? donations donor)))
)

;; @desc Get the contract balance.
;; @returns (response uint uint)
(define-read-only (get-contract-balance)
  (ok (stx-get-balance (as-contract tx-sender)))
)

;; @desc Get the total amount of STX disbursed to the beneficiary.
;; @returns (response uint uint)
(define-read-only (get-total-disbursed)
  (ok (var-get total-disbursed))
)

;; @desc Get the current beneficiary address.
;; @returns (response principal principal)
(define-read-only (get-beneficiary)
  (ok (var-get beneficiary-address))
)

;; Decentralized Recycling Rewards Smart Contract
;; This contract incentivizes recycling through tokenized rewards and verification systems

;; Error constants
(define-constant ERR-UNAUTHORIZED-ACCESS (err u100))
(define-constant ERR-INSUFFICIENT-BALANCE (err u101))
(define-constant ERR-INVALID-MATERIAL-TYPE (err u102))
(define-constant ERR-INVALID-AMOUNT (err u103))
(define-constant ERR-SUBMISSION-NOT-FOUND (err u104))
(define-constant ERR-ALREADY-VERIFIED (err u105))
(define-constant ERR-VERIFICATION-EXPIRED (err u106))
(define-constant ERR-INVALID-VERIFIER (err u107))
(define-constant ERR-USER-NOT-REGISTERED (err u108))
(define-constant ERR-ALREADY-REGISTERED (err u109))
(define-constant ERR-INSUFFICIENT-REWARDS-POOL (err u110))
(define-constant ERR-TRANSFER-FAILED (err u111))
(define-constant ERR-INVALID-MULTIPLIER (err u112))
(define-constant ERR-INVALID-HASH (err u113))
(define-constant ERR-INVALID-PRINCIPAL (err u114))
(define-constant ERR-CONTRACT-PAUSED (err u115))

;; Contract constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant MAX-MATERIAL-TYPES u10)
(define-constant VERIFICATION-TIMEOUT u144) ;; blocks (~24 hours)
(define-constant BASE-REWARD u100) ;; base tokens per kg
(define-constant MIN-RECYCLING-AMOUNT u1) ;; minimum 1kg
(define-constant MAX-RECYCLING-AMOUNT u10000) ;; maximum 10,000kg per submission

;; Material type definitions with reward multipliers
(define-constant MATERIAL-PLASTIC u1)
(define-constant MATERIAL-GLASS u2)
(define-constant MATERIAL-METAL u3)
(define-constant MATERIAL-PAPER u4)
(define-constant MATERIAL-ELECTRONIC u5)
(define-constant MATERIAL-ORGANIC u6)

;; Data variables
(define-data-var total-recycled uint u0)
(define-data-var total-rewards-distributed uint u0)
(define-data-var next-submission-id uint u1)
(define-data-var rewards-pool uint u1000000) ;; Initial pool of 1M tokens
(define-data-var verification-requirement uint u2) ;; Number of verifications required
(define-data-var contract-paused bool false)

;; Material reward multipliers (stored as percentage, 100 = 1.0x)
(define-map material-multipliers uint uint)

;; User registration and profiles
(define-map user-profiles 
  principal 
  {
    registered: bool,
    total-recycled: uint,
    total-rewards: uint,
    reputation-score: uint,
    registration-block: uint
  }
)

;; Recycling submissions awaiting verification
(define-map recycling-submissions
  uint
  {
    submitter: principal,
    material-type: uint,
    weight-kg: uint,
    location-hash: (buff 32),
    photo-hash: (buff 32),
    submission-block: uint,
    verification-count: uint,
    verified: bool,
    reward-amount: uint
  }
)

;; Track verifications by submission and verifier
(define-map verification-records
  {submission-id: uint, verifier: principal}
  {verified: bool, verification-block: uint}
)

;; Authorized verifiers (environmental agencies, certified recycling centers)
(define-map authorized-verifiers principal bool)

;; User token balances
(define-map token-balances principal uint)

;; Initialize material multipliers
(map-set material-multipliers MATERIAL-PLASTIC u120) ;; 1.2x for plastic
(map-set material-multipliers MATERIAL-GLASS u110) ;; 1.1x for glass
(map-set material-multipliers MATERIAL-METAL u150) ;; 1.5x for metal
(map-set material-multipliers MATERIAL-PAPER u100) ;; 1.0x for paper
(map-set material-multipliers MATERIAL-ELECTRONIC u200) ;; 2.0x for electronics
(map-set material-multipliers MATERIAL-ORGANIC u90) ;; 0.9x for organic

;; Helper functions for validation

;; Validate buffer hash is not empty
(define-private (is-valid-hash (hash (buff 32)))
  (not (is-eq hash 0x0000000000000000000000000000000000000000000000000000000000000000))
)

;; Validate principal is not null
(define-private (is-valid-principal (user principal))
  (not (is-eq user (as-contract tx-sender)))
)

;; Check if contract is paused
(define-private (check-contract-active)
  (begin
    (asserts! (not (var-get contract-paused)) ERR-CONTRACT-PAUSED)
    (ok true)
  )
)

;; Read-only functions

;; Get user profile information
(define-read-only (get-user-profile (user principal))
  (default-to 
    {registered: false, total-recycled: u0, total-rewards: u0, reputation-score: u0, registration-block: u0}
    (map-get? user-profiles user)
  )
)

;; Get user token balance
(define-read-only (get-balance (user principal))
  (default-to u0 (map-get? token-balances user))
)

;; Get recycling submission details
(define-read-only (get-submission (submission-id uint))
  (map-get? recycling-submissions submission-id)
)

;; Check if user is authorized verifier
(define-read-only (is-authorized-verifier (user principal))
  (default-to false (map-get? authorized-verifiers user))
)

;; Get material reward multiplier
(define-read-only (get-material-multiplier (material-type uint))
  (default-to u100 (map-get? material-multipliers material-type))
)

;; Calculate reward amount for given material and weight
(define-read-only (calculate-reward (material-type uint) (weight-kg uint))
  (let (
    (multiplier (get-material-multiplier material-type))
    (base-calculation (* BASE-REWARD weight-kg))
  )
    (/ (* base-calculation multiplier) u100)
  )
)

;; Get contract statistics
(define-read-only (get-contract-stats)
  {
    total-recycled: (var-get total-recycled),
    total-rewards-distributed: (var-get total-rewards-distributed),
    rewards-pool: (var-get rewards-pool),
    next-submission-id: (var-get next-submission-id)
  }
)

;; Check if verification has expired
(define-read-only (is-verification-expired (submission-block uint))
  (> (- block-height submission-block) VERIFICATION-TIMEOUT)
)

;; Check if contract is paused
(define-read-only (is-contract-paused)
  (var-get contract-paused)
)

;; Public functions

;; Register a new user in the system
(define-public (register-user)
  (let (
    (user tx-sender)
    (existing-profile (map-get? user-profiles user))
  )
    (try! (check-contract-active))
    (asserts! (is-none existing-profile) ERR-ALREADY-REGISTERED)
    (map-set user-profiles user {
      registered: true,
      total-recycled: u0,
      total-rewards: u0,
      reputation-score: u100, ;; Start with base reputation
      registration-block: block-height
    })
    (ok true)
  )
)

;; Submit recycling for verification
(define-public (submit-recycling 
  (material-type uint) 
  (weight-kg uint) 
  (location-hash (buff 32)) 
  (photo-hash (buff 32))
)
  (let (
    (user tx-sender)
    (submission-id (var-get next-submission-id))
    (user-profile (get-user-profile user))
    (reward-amount (calculate-reward material-type weight-kg))
  )
    ;; Check contract is active
    (try! (check-contract-active))
    
    ;; Validate user is registered
    (asserts! (get registered user-profile) ERR-USER-NOT-REGISTERED)
    
    ;; Validate material type
    (asserts! (and (>= material-type u1) (<= material-type u6)) ERR-INVALID-MATERIAL-TYPE)
    
    ;; Validate weight amount
    (asserts! (and (>= weight-kg MIN-RECYCLING-AMOUNT) (<= weight-kg MAX-RECYCLING-AMOUNT)) ERR-INVALID-AMOUNT)
    
    ;; Validate hashes are not empty
    (asserts! (is-valid-hash location-hash) ERR-INVALID-HASH)
    (asserts! (is-valid-hash photo-hash) ERR-INVALID-HASH)
    
    ;; Create submission record with validated inputs
    (map-set recycling-submissions submission-id {
      submitter: user,
      material-type: material-type,
      weight-kg: weight-kg,
      location-hash: location-hash,
      photo-hash: photo-hash,
      submission-block: block-height,
      verification-count: u0,
      verified: false,
      reward-amount: reward-amount
    })
    
    ;; Increment submission counter
    (var-set next-submission-id (+ submission-id u1))
    
    (ok submission-id)
  )
)

;; Verify a recycling submission (only authorized verifiers)
(define-public (verify-recycling (submission-id uint))
  (let (
    (verifier tx-sender)
    (submission (unwrap! (map-get? recycling-submissions submission-id) ERR-SUBMISSION-NOT-FOUND))
    (verification-key {submission-id: submission-id, verifier: verifier})
    (existing-verification (map-get? verification-records verification-key))
  )
    ;; Check contract is active
    (try! (check-contract-active))
    
    ;; Check verifier authorization
    (asserts! (is-authorized-verifier verifier) ERR-INVALID-VERIFIER)
    
    ;; Check submission hasn't expired
    (asserts! (not (is-verification-expired (get submission-block submission)))
              ERR-VERIFICATION-EXPIRED)
    
    ;; Check not already verified by this verifier
    (asserts! (is-none existing-verification) ERR-ALREADY-VERIFIED)
    
    ;; Check not already fully verified
    (asserts! (not (get verified submission)) ERR-ALREADY-VERIFIED)
    
    ;; Record verification
    (map-set verification-records verification-key {
      verified: true,
      verification-block: block-height
    })
    
    ;; Update submission verification count
    (let (
      (new-count (+ (get verification-count submission) u1))
      (required-verifications (var-get verification-requirement))
    )
      (map-set recycling-submissions submission-id
        (merge submission {verification-count: new-count})
      )
      
      ;; If enough verifications, mark as verified and distribute reward
      (if (>= new-count required-verifications)
        (finalize-verification submission-id)
        (ok true)
      )
    )
  )
)

;; Finalize verification and distribute rewards
(define-private (finalize-verification (submission-id uint))
  (let (
    (submission (unwrap! (map-get? recycling-submissions submission-id) ERR-SUBMISSION-NOT-FOUND))
    (submitter (get submitter submission))
    (reward-amount (get reward-amount submission))
    (weight-kg (get weight-kg submission))
    (current-pool (var-get rewards-pool))
  )
    ;; Check sufficient rewards pool
    (asserts! (>= current-pool reward-amount) ERR-INSUFFICIENT-REWARDS-POOL)
    
    ;; Mark submission as verified
    (map-set recycling-submissions submission-id
      (merge submission {verified: true})
    )
    
    ;; Transfer rewards to submitter
    (try! (transfer-tokens CONTRACT-OWNER submitter reward-amount))
    
    ;; Update user profile
    (let (
      (user-profile (get-user-profile submitter))
    )
      (map-set user-profiles submitter {
        registered: true,
        total-recycled: (+ (get total-recycled user-profile) weight-kg),
        total-rewards: (+ (get total-rewards user-profile) reward-amount),
        reputation-score: (if (> (+ (get reputation-score user-profile) u5) u1000) u1000 (+ (get reputation-score user-profile) u5)),
        registration-block: (get registration-block user-profile)
      })
    )
    
    ;; Update contract statistics
    (var-set total-recycled (+ (var-get total-recycled) weight-kg))
    (var-set total-rewards-distributed (+ (var-get total-rewards-distributed) reward-amount))
    (var-set rewards-pool (- current-pool reward-amount))
    
    (ok true)
  )
)

;; Transfer tokens between users
(define-public (transfer-tokens (from principal) (to principal) (amount uint))
  (let (
    (sender-balance (get-balance from))
    (recipient-balance (get-balance to))
  )
    ;; Check contract is active
    (try! (check-contract-active))
    
    ;; Check authorization (sender must be tx-sender or contract owner)
    (asserts! (or (is-eq tx-sender from) (is-eq tx-sender CONTRACT-OWNER)) ERR-UNAUTHORIZED-ACCESS)
    
    ;; Validate principals
    (asserts! (is-valid-principal to) ERR-INVALID-PRINCIPAL)
    
    ;; Check sufficient balance
    (asserts! (>= sender-balance amount) ERR-INSUFFICIENT-BALANCE)
    
    ;; Validate amount
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    
    ;; Update balances with validated inputs
    (map-set token-balances from (- sender-balance amount))
    (map-set token-balances to (+ recipient-balance amount))
    
    (ok true)
  )
)

;; Redeem tokens for rewards/benefits (placeholder for external integrations)
(define-public (redeem-tokens (amount uint))
  (let (
    (user tx-sender)
    (user-balance (get-balance user))
  )
    ;; Check contract is active
    (try! (check-contract-active))
    
    ;; Check sufficient balance
    (asserts! (>= user-balance amount) ERR-INSUFFICIENT-BALANCE)
    
    ;; Validate amount
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    
    ;; Burn tokens (remove from circulation)
    (map-set token-balances user (- user-balance amount))
    
    (ok amount)
  )
)

;; Admin functions (only contract owner)

;; Add authorized verifier
(define-public (add-verifier (verifier principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (is-valid-principal verifier) ERR-INVALID-PRINCIPAL)
    (map-set authorized-verifiers verifier true)
    (ok true)
  )
)

;; Remove authorized verifier
(define-public (remove-verifier (verifier principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (is-valid-principal verifier) ERR-INVALID-PRINCIPAL)
    (map-delete authorized-verifiers verifier)
    (ok true)
  )
)

;; Update material reward multiplier
(define-public (update-material-multiplier (material-type uint) (multiplier uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (and (>= material-type u1) (<= material-type u6)) ERR-INVALID-MATERIAL-TYPE)
    (asserts! (and (>= multiplier u50) (<= multiplier u500)) ERR-INVALID-MULTIPLIER)
    (map-set material-multipliers material-type multiplier)
    (ok true)
  )
)

;; Add tokens to rewards pool
(define-public (add-to-rewards-pool (amount uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (var-set rewards-pool (+ (var-get rewards-pool) amount))
    (ok true)
  )
)

;; Update verification requirement
(define-public (update-verification-requirement (requirement uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (and (>= requirement u1) (<= requirement u5)) ERR-INVALID-AMOUNT)
    (var-set verification-requirement requirement)
    (ok true)
  )
)

;; Emergency functions

;; Pause contract (emergency stop)
(define-public (pause-contract)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED-ACCESS)
    (var-set contract-paused true)
    (ok true)
  )
)

(define-public (unpause-contract)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED-ACCESS)
    (var-set contract-paused false)
    (ok true)
  )
)
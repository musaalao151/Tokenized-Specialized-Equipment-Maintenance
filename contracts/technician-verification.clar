;; Technician Verification Contract
;; Validates qualified service providers

;; Technician structure
(define-map technicians
  { technician: principal }
  {
    name: (string-ascii 64),
    certification: (string-ascii 64),
    specialization: (list 5 (string-ascii 32)),
    certification-expiry: uint,
    is-active: bool
  }
)

;; Admin list
(define-map admins
  { admin: principal }
  { is-admin: bool }
)

;; Initialize contract with contract deployer as admin
(define-data-var contract-owner principal tx-sender)

;; Register a new technician
(define-public (register-technician
    (technician principal)
    (name (string-ascii 64))
    (certification (string-ascii 64))
    (specialization (list 5 (string-ascii 32)))
    (certification-expiry uint)
  )
  (let
    (
      (admin tx-sender)
    )
    ;; Check if caller is an admin
    (asserts! (is-admin admin) (err u403))

    ;; Add technician to technicians map
    (map-set technicians
      { technician: technician }
      {
        name: name,
        certification: certification,
        specialization: specialization,
        certification-expiry: certification-expiry,
        is-active: true
      }
    )

    (ok true)
  )
)

;; Check if a technician is verified
(define-read-only (is-verified (technician principal))
  (let
    (
      (tech-data (map-get? technicians { technician: technician }))
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
    )
    (if (is-some tech-data)
      (let
        (
          (tech (unwrap-panic tech-data))
        )
        ;; Check if technician is active and certification is not expired
        (ok (and (get is-active tech) (> (get certification-expiry tech) current-time)))
      )
      (ok false)
    )
  )
)

;; Get technician details
(define-read-only (get-technician (technician principal))
  (map-get? technicians { technician: technician })
)

;; Update technician status
(define-public (update-technician-status (technician principal) (is-active bool))
  (let
    (
      (admin tx-sender)
      (tech-data (unwrap! (map-get? technicians { technician: technician }) (err u404)))
    )
    ;; Check if caller is an admin
    (asserts! (is-admin admin) (err u403))

    ;; Update status
    (map-set technicians
      { technician: technician }
      (merge tech-data { is-active: is-active })
    )

    (ok true)
  )
)

;; Update technician certification
(define-public (update-certification
    (technician principal)
    (certification (string-ascii 64))
    (certification-expiry uint)
  )
  (let
    (
      (admin tx-sender)
      (tech-data (unwrap! (map-get? technicians { technician: technician }) (err u404)))
    )
    ;; Check if caller is an admin
    (asserts! (is-admin admin) (err u403))

    ;; Update certification
    (map-set technicians
      { technician: technician }
      (merge tech-data {
        certification: certification,
        certification-expiry: certification-expiry
      })
    )

    (ok true)
  )
)

;; Add a new admin
(define-public (add-admin (new-admin principal))
  (let
    (
      (caller tx-sender)
    )
    ;; Check if caller is the contract owner or an existing admin
    (asserts! (or (is-eq caller (var-get contract-owner)) (is-admin caller)) (err u403))

    ;; Add new admin
    (map-set admins
      { admin: new-admin }
      { is-admin: true }
    )

    (ok true)
  )
)

;; Remove an admin
(define-public (remove-admin (admin-to-remove principal))
  (let
    (
      (caller tx-sender)
    )
    ;; Check if caller is the contract owner
    (asserts! (is-eq caller (var-get contract-owner)) (err u403))

    ;; Cannot remove the contract owner
    (asserts! (not (is-eq admin-to-remove (var-get contract-owner))) (err u403))

    ;; Remove admin
    (map-delete admins { admin: admin-to-remove })

    (ok true)
  )
)

;; Check if a principal is an admin
(define-private (is-admin (user principal))
  (or
    (is-eq user (var-get contract-owner))
    (default-to false (get is-admin (map-get? admins { admin: user })))
  )
)

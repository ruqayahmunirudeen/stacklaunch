;; stacklaunch.clar
;; A decentralized crowdfunding and launchpad contract on Stacks

;; --------------------------------
;; ERRORS
;; --------------------------------
(define-constant ERR_NOT_CREATOR u100)
(define-constant ERR_ALREADY_FUNDED u101)
(define-constant ERR_NOT_FOUND u102)
(define-constant ERR_EXPIRED u103)
(define-constant ERR_NOT_VERIFIED u104)
(define-constant ERR_ALREADY_CLAIMED u105)
(define-constant ERR_GOAL_NOT_MET u106)
(define-constant ERR_INVALID_AMOUNT u107)
(define-constant ERR_NOT_OWNER u108)

;; --------------------------------
;; DATA VARIABLES
;; --------------------------------
(define-data-var owner principal tx-sender)
(define-data-var next-campaign-id uint u0)
(define-data-var total-campaigns uint u0)

(define-map campaigns
  uint
  (tuple
    (creator principal)
    (title (string-ascii 64))
    (description (string-ascii 256))
    (goal uint)
    (deadline uint)
    (raised uint)
    (verified bool)
    (claimed bool)
  )
)

(define-map contributions
  (tuple (campaign-id uint) (funder principal))
  uint
)

;; --------------------------------
;; NOTES
;; --------------------------------
;; Event logging is handled via print statements in Clarity
;; Users can filter contract events via transaction logs

;; --------------------------------
;; PRIVATE HELPERS
;; --------------------------------
(define-private (only-owner)
  (if (is-eq tx-sender (var-get owner))
      (ok true)
      (err ERR_NOT_OWNER))
)

;; --------------------------------
;; PUBLIC FUNCTIONS
;; --------------------------------

;; Create a new campaign
(define-public (create-campaign (title (string-ascii 64)) (description (string-ascii 256)) (goal uint) (duration uint))
  (if (> goal u0)
      (let ((id (+ (var-get next-campaign-id) u1)))
        (map-set campaigns id
          (tuple
            (creator tx-sender)
            (title title)
            (description description)
            (goal goal)
            (deadline (+ burn-block-height duration))
            (raised u0)
            (verified false)
            (claimed false)))
        (var-set next-campaign-id id)
        (var-set total-campaigns (+ (var-get total-campaigns) u1))
        (print {event: "campaign-created", id: id, creator: tx-sender})
        (ok (tuple (campaign-id id) (goal goal))))
      (err ERR_INVALID_AMOUNT)))

;; Verify campaign (admin only)
(define-public (verify-campaign (campaign-id uint) (status bool))
  (begin
    (try! (only-owner))
    (let ((c (map-get? campaigns campaign-id)))
      (match c
        camp
          (begin
            (map-set campaigns campaign-id
              (tuple
                (creator (get creator camp))
                (title (get title camp))
                (description (get description camp))
                (goal (get goal camp))
                (deadline (get deadline camp))
                (raised (get raised camp))
                (verified status)
                (claimed (get claimed camp))))
            (print {event: "verified", campaign-id: campaign-id, status: status})
            (ok (tuple (campaign-id campaign-id) (verified status))))
        (err ERR_NOT_FOUND)))
  )
)

;; Fund a campaign
(define-public (fund (campaign-id uint) (amount uint))
  (begin
    (if (> amount u0)
        (let ((campaign (map-get? campaigns campaign-id)))
          (match campaign
            camp
              (if (and (get verified camp) (<= burn-block-height (get deadline camp)))
                  (begin
                    (try! (stx-transfer? amount tx-sender contract-caller))
                    (map-set contributions 
                      (tuple (campaign-id campaign-id) (funder tx-sender))
                      (+ amount (default-to u0 (map-get? contributions (tuple (campaign-id campaign-id) (funder tx-sender))))))
                    (map-set campaigns campaign-id
                      (tuple
                        (creator (get creator camp))
                        (title (get title camp))
                        (description (get description camp))
                        (goal (get goal camp))
                        (deadline (get deadline camp))
                        (raised (+ (get raised camp) amount))
                        (verified (get verified camp))
                        (claimed (get claimed camp))))
                    (if (>= (+ (get raised camp) amount) (get goal camp))
                        (print {event: "goal-reached", campaign-id: campaign-id})
                        (print {event: "funded", campaign-id: campaign-id, funder: tx-sender, amount: amount}))
                    (ok "Funding successful"))
                  (err ERR_NOT_VERIFIED))
            (err ERR_NOT_FOUND)))
        (err ERR_INVALID_AMOUNT))
  )
)

;; Claim funds (creator)
;; Claim funds (creator)
(define-public (claim-funds (campaign-id uint))
  (let ((c (map-get? campaigns campaign-id)))
    (match c
      camp
        (if (is-eq tx-sender (get creator camp))
            (if (and (>= (get raised camp) (get goal camp)) (not (get claimed camp)))
                (begin
                  (try! (stx-transfer? (get raised camp) contract-caller tx-sender))
                  (map-set campaigns campaign-id
                    (tuple
                      (creator (get creator camp))
                      (title (get title camp))
                      (description (get description camp))
                      (goal (get goal camp))
                      (deadline (get deadline camp))
                      (raised (get raised camp))
                      (verified (get verified camp))
                      (claimed true)))
                  (print {event: "claimed", campaign-id: campaign-id, creator: tx-sender, amount: (get raised camp)})
                  (ok "Funds claimed"))
                (err ERR_GOAL_NOT_MET))
            (err ERR_NOT_CREATOR))
      (err ERR_NOT_FOUND))
  )
)

;; Refund contributors if campaign fails
(define-public (refund (campaign-id uint))
  (let ((c (map-get? campaigns campaign-id)))
    (match c
      camp
        (if (and (>= burn-block-height (get deadline camp)) (< (get raised camp) (get goal camp)))
            (let ((amount (map-get? contributions (tuple (campaign-id campaign-id) (funder tx-sender)))))
              (match amount
                a
                  (begin
                    (try! (stx-transfer? a contract-caller tx-sender))
                    (map-delete contributions (tuple (campaign-id campaign-id) (funder tx-sender)))
                    (print {event: "refunded", campaign-id: campaign-id, funder: tx-sender, amount: a})
                    (ok "Refund successful"))
                (err ERR_ALREADY_CLAIMED)))
            (err ERR_GOAL_NOT_MET))
      (err ERR_NOT_FOUND))
  )
)

;; --------------------------------
;; READ-ONLY FUNCTIONS
;; --------------------------------
(define-read-only (get-campaign (id uint))
  (map-get? campaigns id)
)

(define-read-only (get-contribution (campaign-id uint) (funder principal))
  (map-get? contributions (tuple (campaign-id campaign-id) (funder funder)))
)

(define-read-only (get-total-campaigns)
  (var-get total-campaigns)
)

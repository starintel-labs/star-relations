; star-relations: declarative OSINT relation taxonomy for StarLang.
; Library org.starintel/relations@1, version 1.0.0.
;
; Self-contained bootstrap: no imports. The thin base/document markers
; below exist only because org.starintel/core@1 is not yet published with
; a real sha256 digest. See README.org for the pinned core-import swap
; plan; endpoints are typed against these markers so the swap is
; mechanical.
(spec-library "org.starintel/relations@1"
  (:version "1.0.0")

  (enum relation-direction
    (directed symmetric inverse unknown))

  ; Minimal self-contained document base. One required identity field;
  ; everything else arrives with the core import.
  (document base
    (:persistence persistent)
    (id string :required))

  ; Root document kind. All marker kinds extend this. Additively
  ; swappable for org.starintel/core@1 document.
  (document document
    (:extends base
     :persistence persistent))

  ; Thin kind markers: no extra fields, typed endpoints only.
  (document person
    (:extends document :persistence persistent))

  (document org
    (:extends document :persistence persistent))

  (document host
    (:extends document :persistence persistent))

  (document domain
    (:extends document :persistence persistent))

  (document file
    (:extends document :persistence persistent))

  (document network
    (:extends document :persistence persistent))

  (document network-device
    (:extends document :persistence persistent))

  (document wireless-network
    (:extends document :persistence persistent))

  (document wireless-station
    (:extends document :persistence persistent))

  (document pcap-capture
    (:extends document :persistence persistent))

  (document network-conversation
    (:extends document :persistence persistent))

  (document breach
    (:extends document :persistence persistent))

  (document location
    (:extends document :persistence persistent))

  (document user
    (:extends document :persistence persistent))

  (document source
    (:extends document :persistence persistent))

  ; -----------------------------------------------------------------
  ; Live OSINT relation vocabulary. These predicate identifiers are in
  ; production use in the canonical database; names are frozen.
  ; Symmetric/inverse/transitive semantics are documented in README.org
  ; because star-lang predicates carry no inverse metadata.
  ; -----------------------------------------------------------------

  ; People and organizations.
  (predicate affiliated_with
    (:source person :destination org))

  (predicate member_of
    (:source person :destination org))

  (predicate partner
    (:source org :destination org))

  (predicate fellow_of
    (:source person :destination org))

  (predicate board_member_of
    (:source person :destination org))

  (predicate employed_by
    (:source person :destination org))

  (predicate subsidiary_of
    (:source org :destination org))

  (predicate lobbies_for
    (:source org :destination org))

  (predicate lobbies_through
    (:source org :destination org))

  (predicate advisor_to
    (:source person :destination org))

  (predicate chair_of
    (:source person :destination org))

  (predicate director_of
    (:source person :destination org))

  (predicate executive_of
    (:source person :destination org))

  (predicate reports_to
    (:source person :destination person))

  (predicate serves_as
    (:source person :destination person))

  (predicate contracts_with
    (:source org :destination org))

  (predicate procures_from
    (:source org :destination org))

  (predicate uses_vendor
    (:source org :destination org))

  (predicate uses_vendor_technology
    (:source org :destination org))

  (predicate participates_in_joint_fundraising_committee
    (:source org :destination org))

  (predicate owned_and_developed_by
    (:source org :destination org))

  ; Attribution and identity.
  (predicate possible_same_person_as
    (:source person :destination person))

  (predicate declared_linked_account
    (:source user :destination user))

  ; Content and observation.
  (predicate authored_by
    (:source source :destination person))

  (predicate reply_to
    (:source source :destination source))

  (predicate viewed_live_camera
    (:source user :destination source))

  ; -----------------------------------------------------------------
  ; Network, capture, and leak relations.
  ; -----------------------------------------------------------------

  (predicate resolves_to
    (:source domain :destination host))

  (predicate hosted_on
    (:source host :destination network-device))

  (predicate hosted_by
    (:source host :destination org))

  (predicate communicates_with
    (:source host :destination host))

  (predicate connected_to
    (:source host :destination host))

  (predicate observed_in_capture
    (:source host :destination pcap-capture))

  ; Reified conversation document, one edge per participating host.
  (predicate conversation_between
    (:source network-conversation :destination host))

  (predicate manufactured_by
    (:source network-device :destination org))

  (predicate manages
    (:source org :destination network-device))

  (predicate located_at
    (:source wireless-network :destination location))

  (predicate observed_at_station
    (:source wireless-station :destination wireless-network))

  (predicate leak_affects
    (:source breach :destination org))

  (predicate leak_contains
    (:source breach :destination file))

  (predicate leak_mentions
    (:source breach :destination domain))

  (predicate distributed_by
    (:source breach :destination user))

  (predicate attributed_to
    (:source breach :destination org)))

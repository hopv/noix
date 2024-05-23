(** * Mutex machinery *)

From nola.heap_lang Require Import notation proofmode.
From nola.util Require Import prod.
From nola.iris Require Export ofe inv.
Import ProdNotation iPropAppNotation UpdwNotation WpwNotation.

Implicit Type (b : bool) (l : loc) (n : nat).

(** ** Camera for the mutex machinery *)

Local Definition mutex_prop PROP : oFunctor := leibnizO loc * PROP.
Class mutexGS PROP Σ := mutexGS_inv : inv'GS (mutex_prop PROP) Σ.
Local Existing Instances mutexGS_inv.

Class mutexGpreS PROP Σ := mutexGpreS_inv : inv'GpreS PROP Σ.
Local Existing Instances mutexGpreS_inv.
Definition mutexΣ PROP `{!oFunctorContractive PROP} := #[inv'Σ PROP].
#[export] Instance subG_mutexΣ
  `{!oFunctorContractive PROP, !subG (mutexΣ PROP) Σ} : mutexGpreS PROP Σ.
Proof. solve_inG. Qed.

(** ** Mutex *)
Section mutex.
  Context `{!heapGS_gen hlc Σ, !mutexGS PROP Σ}.
  Implicit Types (intp : PROP $oi Σ → iProp Σ) (P : PROP $oi Σ).

  (** [mutex_tok]: Mutex token *)
  Definition mutex_tok l P : iProp Σ := inv_tok nroot (l, P).

  (** [mutex_tok] is persistent *)
  Fact mutex_tok_persistent {l P} : Persistent (mutex_tok l P).
  Proof. exact _. Qed.
  (** [mutex_tok] is timeless if the underlying OFE is discrete *)
  Fact mutex_tok_timeless `{!OfeDiscrete (PROP $oi Σ)} {l P} :
    Timeless (mutex_tok l P).
  Proof. exact _. Qed.

  (** Interpretation for a mutex *)
  Local Definition mutex_intp (intp : PROP $oi Σ -d> iProp Σ)
    : mutex_prop PROP $oi Σ -d> iProp Σ := λ '(l, P),
    (∃ b, l ↦ #b ∗ if b then True else intp P)%I.
  #[export] Instance mutex_intp_ne `{!NonExpansive intp} :
    NonExpansive (mutex_intp intp).
  Proof. move=> ?[??][??][/=??]. solve_proper. Qed.

  (** World satisfaction for the mutex machinery *)
  Local Definition mutex_wsat_def (intp : PROP $oi Σ -d> iProp Σ) : iProp Σ :=
    inv_wsat (mutex_intp intp).
  Local Lemma mutex_wsat_aux : seal mutex_wsat_def. Proof. by eexists. Qed.
  Definition mutex_wsat := mutex_wsat_aux.(unseal).
  Local Lemma mutex_wsat_unseal : mutex_wsat = mutex_wsat_def.
  Proof. exact: seal_eq. Qed.

  (** [mutex_wsat] is non-expansive *)
  #[export] Instance mutex_wsat_ne : NonExpansive mutex_wsat.
  Proof.
    rewrite mutex_wsat_unseal /mutex_wsat_def=> ????. f_equiv. case=> ??.
    unfold mutex_intp. solve_proper.
  Qed.
  #[export] Instance mutex_wsat_proper : Proper ((≡) ==> (≡)) mutex_wsat.
  Proof. apply ne_proper, _. Qed.

  Context `{!NonExpansive intp}.

  (** Create a new mutex *)
  Definition new_mutex : val := λ: <>, ref #false.
  Lemma twp_new_mutex {P} :
    [[{ intp P }]][mutex_wsat intp]
      new_mutex #()
    [[{ l, RET #l; mutex_tok l P }]].
  Proof.
    rewrite mutex_wsat_unseal. iIntros (Φ) "P →Φ". wp_lam.
    iApply twpw_fupdw_nonval; [done|]. wp_alloc l as "↦". iModIntro.
    iMod (inv_tok_alloc (PROP:=mutex_prop _) (l, P) with "[↦ P]") as "l".
    { by iFrame. } { iApply ("→Φ" with "l"). }
  Qed.

  (** Create a new mutex with the lock acquired *)
  Definition new_acquire_mutex : val := λ: <>, ref #true.
  Lemma twp_new_acquire_mutex {P} :
    [[{ True }]][mutex_wsat intp]
      new_acquire_mutex #()
    [[{ l, RET #l; mutex_tok l P }]].
  Proof.
    rewrite mutex_wsat_unseal. iIntros (Φ) "_ →Φ". wp_lam.
    iApply twpw_fupdw_nonval; [done|]. wp_alloc l as "↦". iModIntro.
    iMod (inv_tok_alloc (PROP:=mutex_prop _) (l, P) with "[↦]") as "l".
    { iFrame. } { iApply ("→Φ" with "l"). }
  Qed.

  (** Try to acquire the lock on the mutex *)
  Definition try_acquire_mutex : val := λ: "l", CAS "l" #false #true.
  Lemma twp_try_acquire_mutex {l P} :
    [[{ mutex_tok l P }]][mutex_wsat intp]
      try_acquire_mutex #l
    [[{ b, RET #b; if b then intp P else True }]].
  Proof.
    rewrite mutex_wsat_unseal. iIntros (Φ) "l →Φ". wp_lam.
    wp_bind (CmpXchg _ _ _).
    iMod (inv_tok_acc (intp:=mutex_intp _) with "l") as "[[%b[↦ big]]cl]";
      [done|]; case b.
    - wp_cmpxchg_fail. iModIntro. iMod ("cl" with "[$↦//]") as "_". iModIntro.
      wp_pures. by iApply "→Φ".
    - wp_cmpxchg_suc. iModIntro. iMod ("cl" with "[$↦//]") as "_". iModIntro.
      wp_pures. by iApply "→Φ".
  Qed.

  (** Try to acquire the lock on the mutex repeatedly with a timeout *)
  Definition try_acquire_loop_mutex : val :=
    rec: "self" "n" "l" :=
      if: "n" = #0 then #false else
      if: try_acquire_mutex "l" then #true else "self" ("n" - #1) "l".
  Lemma twp_try_acquire_loop_mutex {l P n} :
    [[{ mutex_tok l P }]][mutex_wsat intp]
      try_acquire_loop_mutex #n #l
    [[{ b, RET #b; if b then intp P else True }]].
  Proof.
    iIntros (Φ) "#l →Φ". iInduction n as [|n] "IH".
    { wp_lam. wp_pures. by iApply "→Φ". }
    wp_lam. wp_pures. wp_apply (twp_try_acquire_mutex with "l"). iIntros ([|]).
    - iIntros "?". wp_pures. iModIntro. by iApply "→Φ".
    - iIntros "_". wp_pures. have ->: (S n - 1)%Z = n by lia. by iApply "IH".
  Qed.

  (** Release the lock on the mutex *)
  Definition release_mutex : val := λ: "l", "l" <- #false.
  Lemma twp_release_mutex {l P} :
    [[{ mutex_tok l P ∗ intp P }]][mutex_wsat intp]
      release_mutex #l
    [[{ RET #(); True }]].
  Proof.
    rewrite mutex_wsat_unseal. iIntros (Φ) "[#l P] →Φ". wp_lam.
    iMod (inv_tok_acc (intp:=mutex_intp _) with "l") as "[[%[↦ _]]cl]"; [done|].
    wp_store. iModIntro. iMod ("cl" with "[$]") as "_". iModIntro.
    by iApply "→Φ".
  Qed.
End mutex.
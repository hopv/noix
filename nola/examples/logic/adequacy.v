(** * Adequacy *)

From nola.examples.logic Require Export deriv.
From nola.examples.heap_lang Require Export adequacy total_adequacy.

(** Precursor of [nintpGS] *)
Class nintpGpreS Σ := NintpGpreS {
  nintpGpreS_sinv :: sinvGpreS (nPropS (;ᵞ)) Σ;
  nintpGpreS_ninv :: ninvGpreS (nPropS (;ᵞ)) Σ;
  nintpGpreS_na_ninv :: na_ninvGpreS (nPropS (;ᵞ)) Σ;
  nintpGpreS_na_inv :: na_invG Σ;
  nintpGpreS_cinv :: cinvG Σ;
  nintpGpreS_pborrow :: pborrowGpreS nsynty (nPropS (;ᵞ)) Σ;
  nintpGpreS_heap :: heapGpreS Σ;
}.

(** [gFunctors] for [nintpGpreS] *)
Definition nintpΣ : gFunctors :=
  #[sinvΣ (nPropS (;ᵞ)); ninvΣ (nPropS (;ᵞ)); na_ninvΣ (nPropS (;ᵞ)); na_invΣ;
    cinvΣ; pborrowΣ nsynty (nPropS (;ᵞ)); heapΣ].
#[export] Instance subG_nintpGpreS `{!subG nintpΣ Σ} : nintpGpreS Σ.
Proof. solve_inG. Qed.

(** Whole world satisfaction *)
Definition nwsatd `{!nintpGS Σ} : iProp Σ :=
  sinv_wsatd ∗ inv_wsatd ∗ na_inv_wsatd ∗ pborrow_wsatd ∗ proph_wsat.

(** Adequacy of [wp] over [inv_wsatd] *)
Lemma wp_n_adequacy `{!nintpGpreS Σ} {s e σ φ} :
  (∀ `{!nintpGS Σ}, ⊢ inv_heap_inv -∗ WP[nwsatd] e @ s; ⊤ {{ v, ⌜φ v⌝ }}) →
  adequate s e σ (λ v _, φ v).
Proof.
  move=> towp. apply (heap_adequacy Σ HasNoLc)=> ?.
  iMod sinv_wsat_alloc as (?) "W0". iMod inv_wsat_alloc as (?) "W1".
  iMod na_inv_wsat_alloc as (?) "W2".
  iMod proph_pborrow_wsat_alloc as (?) "[W W3]". iModIntro.
  iDestruct (towp (NintpGS _ _ _ _ _ _ _)) as "big". iExists nwsatd.
  iFrame "big W". iSplitL "W0"; [done|]. iSplitL "W1"; [done|]. by iSplitL "W2".
Qed.

(** Adequacy of [twp] over [inv_wsatd] *)
Lemma twp_n_adequacy `{!nintpGpreS Σ} {s e σ φ} :
  (∀ `{!nintpGS Σ}, ⊢ inv_heap_inv -∗  WP[nwsatd] e @ s; ⊤ [{ v, ⌜φ v⌝ }]) →
  sn erased_step ([e], σ).
Proof.
  move=> totwp. apply (heap_total Σ s _ _ φ)=> ?.
  iMod sinv_wsat_alloc as (?) "W0". iMod inv_wsat_alloc as (?) "W1".
  iMod na_inv_wsat_alloc as (?) "W2".
  iMod proph_pborrow_wsat_alloc as (?) "[W W4]". iModIntro.
  iDestruct (totwp (NintpGS _ _ _ _ _ _ _)) as "big". iExists nwsatd.
  iFrame "big W". iSplitL "W0"; [done|]. iSplitL "W1"; [done|]. by iSplitL "W2".
Qed.

(** * Adequacy *)

From nola.examples.rust_halt Require Export type num.

Implicit Type JUDG : ofe.

(** Allocate the world satisfaction *)
Lemma rust_wsat_alloc `{!rust_haltGpreS CON Σ,
  lrustGS_gen0 : !lrustGS_gen HasNoLc Σ} {JUDG} :
  ⊢ |==> ∃ _ : rust_haltGS CON Σ, ⌜rust_haltGS_lrust = lrustGS_gen0⌝ ∧
    ∀ (_ : Csem CON JUDG Σ) (_ : Jsem JUDG (iProp Σ)), rust_halt_wsat.
Proof.
  iMod inv_wsat_alloc as (?) "Winv". iMod dinv_wsat_alloc as (?) "Wdinv".
  iMod borrow_wsat_alloc as (?) "Wborrow". iMod proph_init as (?) "_".
  iMod fborrow_wsat_alloc as (?) "Wfborrow". iModIntro.
  iExists (RustHaltGS _ _ _ _ _ _ _ _ _ _ _). iSplit; [done|]. iIntros (??).
  iDestruct ("Winv" with "[]") as "$"; [iApply ne_internal_ne|].
  iDestruct ("Wdinv" with "[]") as "$"; [iApply ne_internal_ne|].
  iDestruct ("Wborrow" with "[]") as "$"; [iApply ne_internal_ne|].
  iApply "Wfborrow".
Qed.

(** Usual adequacy for a partial weakest precondition *)
Theorem wp_adequacy `{!rust_haltGpreS CON Σ} {JUDG e σ φ} :
  (∀ `{!rust_haltGS CON Σ}, ∃ (_ : Csem CON JUDG Σ) (_ : Jsem JUDG (iProp Σ)),
    ⊢ |={⊤}=> WP[rust_halt_wsat] e {{ v, |=[rust_halt_wsat]{⊤}=> ⌜φ v⌝ }}) →
  adequate NotStuck e σ (λ v _, φ v).
Proof.
  move=> towp. eapply lrust_adequacy; [exact _|]=> ?.
  iMod rust_wsat_alloc as (?<-) "→W". case: (towp _)=> ?[? wp].
  iMod wp as "wp". rewrite wpw_fupdw_fupdw. iDestruct ("→W" $! _ _) as "W".
  iExists _. by iMod ("wp" with "W") as "[? $]".
Qed.

(** Termination adequacy over a total weakest precondition *)
Theorem twp_total `{!rust_haltGpreS CON Σ} {JUDG e σ} :
  (∀ `{!rust_haltGS CON Σ}, ∃ (_ : Csem CON JUDG Σ) (_ : Jsem JUDG (iProp Σ)) Φ,
    ⊢ |={⊤}=> WP[rust_halt_wsat] e [{ Φ }]) →
  sn erased_step ([e], σ).
Proof.
  move=> totwp. eapply lrust_total; [exact _|]=> ?.
  iMod rust_wsat_alloc as (?<-) "→W". case: (totwp _)=> ?[?[? twp]].
  iMod twp as "$". iModIntro. iApply "→W".
Qed.

(** Usual adequacy over a typing judgment *)
Theorem type_adeqaucy `{!rust_haltGpreS CON Σ} {Xl post pre Γo e σ JUDG} :
  pre post () →
  (∀ `{!rust_haltGS CON Σ}, ∃ (_ : Csem CON JUDG Σ) (_ : Jsem JUDG (iProp Σ)),
    ⊢ type (Yl:=Xl) ⊤ ᵖ[] e (λ _, Γo) pre) →
  adequate NotStuck e σ (λ _ _, ∃ xl, post xl).
Proof.
  move=> topre totyp. eapply wp_adequacy=> ?. case: (totyp _)=> ?[? typ].
  exists _, _. rewrite type_unseal in typ.
  iMod (na_alloc (na_invG0:=rust_haltGS_na_inv)) as (t) "t". iModIntro.
  iDestruct (typ $! 1%Qp t (λ _, post) (λ _,()) with "[//] t [] [//]")
    as "twp".
  { by iApply proph_obs_true. }
  iApply twp_wp. iApply (twp_mono with "twp")=> ?. f_equiv.
  iDestruct 1 as "(% & _ & _ & obs & _)". rewrite proph_obs_sat.
  iDestruct "obs" as "[% %]". by iExists _.
Qed.
Theorem type_adeqaucy_int `{!rust_haltGpreS CON Σ, !rust_haltC CON}
  {Xl post pre Γo e σ JUDG} :
  pre post () →
  (∀ `{!rust_haltGS CON Σ}, ∃ (_ : Csem CON JUDG Σ) (_ : Jsem JUDG (iProp Σ)),
    ⊢ type (Yl:=_::Xl) ⊤ ᵖ[] e (λ r, r ◁ ty_int ᵖ:: Γo) pre) →
  adequate NotStuck e σ (λ v _, ∃ (n : Z) xl, v = #n ∧ post (n ᵖ:: xl)).
Proof.
  move=> topre totyp. eapply wp_adequacy=> ?. case: (totyp _)=> ?[? typ].
  exists _, _. rewrite type_unseal in typ.
  iMod (na_alloc (na_invG0:=rust_haltGS_na_inv)) as (t) "t". iModIntro.
  iDestruct (typ $! 1%Qp t (λ _, post) (λ _,()) with "[//] t [] [//]")
    as "twp".
  { by iApply proph_obs_true. }
  iApply twp_wp. iApply (twp_mono with "twp")=> ?. f_equiv.
  rewrite /ty_int ty_pty_unseal /=. iDestruct 1 as "(% & _ & _ & obs & %i & _)".
  case i=> [?[? +]]. rewrite of_path_val. move=> [[->][?[eq[->]]]].
  rewrite proph_obs_sat. iDestruct "obs" as "[%π %]". rewrite -(eq π).
  by iExists _, _.
Qed.

(** Termination adequacy over a typing judgment *)
Theorem type_total `{!rust_haltGpreS CON Σ} {Xl post pre Γo e σ JUDG} :
  pre post () →
  (∀ `{!rust_haltGS CON Σ}, ∃ (_ : Csem CON JUDG Σ) (_ : Jsem JUDG (iProp Σ)),
    ⊢ type (Yl:=Xl) ⊤ ᵖ[] e (λ _, Γo) pre) →
  sn erased_step ([e], σ).
Proof.
  move=> topre totyp. eapply twp_total=> ?. case: (totyp _)=> ?[? typ].
  exists _, _, (λ _, True)%I. rewrite type_unseal in typ.
  iMod (na_alloc (na_invG0:=rust_haltGS_na_inv)) as (t) "t". iModIntro.
  iDestruct (typ $! 1%Qp t (λ _, post) (λ _,()) with "[//] t [] [//]")
    as "twp"; [by iApply proph_obs_true|].
  iApply (twp_mono with "twp"). by iIntros.
Qed.

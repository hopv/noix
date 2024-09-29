(** * Modality with a custom world satisfaction *)

From nola.bi Require Export mod.
From iris.bi Require Export bi.
From iris.proofmode Require Import proofmode.

Implicit Type PROP : bi.

(** ** World satisfaction inclusion *)

Class WsatIncl {PROP} (W W' Wr : PROP) : Prop := wsat_incl : W ⊣⊢ W' ∗ Wr.
Hint Mode WsatIncl + ! ! - : typeclass_instances.
Arguments WsatIncl {_} _%_I _%_I _%_I : simpl never.
Arguments wsat_incl {_} _%_I _%_I _%_I {_}.

Section wsat_incl.
  Context {PROP}.
  Implicit Types W Wr : PROP.

  #[export] Instance wsat_incl_refl {W} : WsatIncl W W emp.
  Proof. by rewrite /WsatIncl right_id. Qed.
  #[export] Instance wsat_incl_emp {W} : WsatIncl W emp W.
  Proof. by rewrite /WsatIncl left_id. Qed.
  #[export] Instance wsat_incl_True `{!BiAffine PROP} {W} : WsatIncl W True W.
  Proof. by rewrite /WsatIncl bi.True_sep. Qed.
  #[export] Instance wsat_incl_sep_in {W W'1 W'2 Wr Wr'} :
    WsatIncl W W'1 Wr → WsatIncl Wr W'2 Wr' → WsatIncl W (W'1 ∗ W'2) Wr' | 2.
  Proof. rewrite /WsatIncl=> ->->. by rewrite assoc. Qed.
  #[export] Instance wsat_incl_in_sep_l {W1 W2 W' Wr} :
    WsatIncl W1 W' Wr → WsatIncl (W1 ∗ W2) W' (Wr ∗ W2) | 4.
  Proof. rewrite /WsatIncl=> ->. by rewrite assoc. Qed.
  #[export] Instance wsat_incl_in_sep_r {W1 W2 W' Wr} :
    WsatIncl W2 W' Wr → WsatIncl (W1 ∗ W2) W' (W1 ∗ Wr) | 6.
  Proof. rewrite /WsatIncl=> ->. rewrite !assoc. f_equiv. by rewrite comm. Qed.
End wsat_incl.

(** ** Modality with a world satisfaction *)

Definition modw {PROP} (M : PROP → PROP) (W P : PROP) : PROP :=
  W -∗ M (W ∗ P)%I.
Arguments modw : simpl never.

(** Instances of [modw] *)
#[export] Instance modw_mod `{!@Mod PROP M} {W} : Mod (modw M W).
Proof. split; solve_proper. Qed.
#[export] Instance modw_mod_intro `{!@ModIntro PROP M} {W} :
  ModIntro (modw M W).
Proof. iIntros "% ?? !>". iFrame. Qed.
#[export] Instance modw_mod_trans `{!@Mod PROP M, !ModTrans M} {W} :
  ModTrans (modw M W).
Proof.
  iIntros "%P →P W". iDestruct ("→P" with "W") as "?". iStopProof.
  rewrite -[(M (W ∗ P))%I]mod_trans. f_equiv. iIntros "[W →P]". by iApply "→P".
Qed.
#[export] Instance modw_mod_frame `{!@Mod PROP M, !ModFrame M} {W} :
  ModFrame (modw M W).
Proof. by iIntros "%%[$?]". Qed.
#[export] Instance modw_mod_upd `{!@ModUpd PROP M} {W} : ModUpd (modw M W).
Proof. split; exact _. Qed.
#[export] Instance absorb_bupd_modw
  `{!BiBUpd PROP, !AbsorbBUpd (PROP:=PROP) M} {W} :
  AbsorbBUpd (modw M W) | 10.
Proof. by iIntros (?) ">$$". Qed.
#[export] Instance mod_plain_modw `{!BiPlainly PROP, !BiBUpd PROP}
  `{!@Mod PROP M, !ModPlain M, !Affine W} :
  ModPlain (modw M W) | 10.
Proof.
  split.
  - move=> >. iIntros "[→P R] W". rewrite [(W ∗ _)%I]comm -assoc.
    rewrite -mod_plain_keep_l. iFrame "R W". iIntros "[R W]".
    iDestruct ("→P" with "R W") as "?". iStopProof. f_equiv. iIntros "[_ $]".
  - move=> ? Φ ?. iIntros "→Φ W".
    iApply (mod_plain_keep_r (M:=M) (P:=∀ a, Φ a)). iFrame "W".
    iIntros "W". iApply (mod_plain_forall (M:=M) (Φ:=Φ)). iIntros (a).
    iDestruct ("→Φ" $! a with "W") as "?". iStopProof. f_equiv. iIntros "[_ $]".
Qed.

(** *** Lemmas *)
Section lemmas.
  Context {PROP}.
  Implicit Type (M : PROP → PROP) (W P Q R : PROP).

  (** Fold the definition of [modw] *)
  Lemma modw_fold M W P : (W -∗ M (W ∗ P)) ⊣⊢ modw M W P.
  Proof. done. Qed.

  (** [modw] is non-expansive and proper *)
  #[export] Instance modw_ne `{!NonExpansive M} : NonExpansive2 (modw M) | 10.
  Proof. solve_proper. Qed.
  #[export] Instance modw_proper `{!Proper ((⊣⊢) ==> (⊣⊢)) M} :
    Proper ((⊣⊢) ==> (⊣⊢) ==> (⊣⊢)) (modw M) | 10.
  Proof. solve_proper. Qed.
  Lemma modw_ne_mod {n M M' W P} :
    (∀ P, M P ≡{n}≡ M' P) → modw M W P ≡{n}≡ modw M' W P.
  Proof. by unfold modw=> ->. Qed.
  Lemma modw_proper_mod {M M' W P} :
    (∀ P, M P ≡ M' P) → modw M W P ≡ modw M' W P.
  Proof.
    move=> ?. apply equiv_dist=> ?. apply modw_ne_mod=> ?. by apply equiv_dist.
  Qed.

  (** [modw] is monotone for monotone [M] *)
  #[export] Instance modw_mono `{!Proper ((⊢) ==> (⊢)) M} {W} :
    Proper ((⊢) ==> (⊢)) (modw M W) | 10.
  Proof. solve_proper. Qed.
  #[export] Instance modw_flip_mono `{!Proper ((⊢) ==> (⊢)) M} {W} :
    Proper (flip (⊢) ==> flip (⊢)) (modw M W) | 10.
  Proof. solve_proper. Qed.

  (** Modify the world satisfaction of [modw] under [ModFrame M] *)
  Lemma modw_incl `{!Mod M, !ModFrame M} {P} `(!WsatIncl W W' Wr) :
    modw M W' P ⊢ modw M W P.
  Proof.
    rewrite (wsat_incl W W'). iIntros "→P [W' $]". by iApply "→P".
  Qed.

  (** [modw] preserves [IsExcept0] *)
  #[export] Instance is_except_0_modw `{!∀ P, IsExcept0 (M P)} {W P} :
    IsExcept0 (modw M W P) | 10.
  Proof. unfold IsExcept0. by iIntros ">?". Qed.

  (** Introduce [modw] *)
  Lemma modw_intro {M W P} : (∀ P, P ⊢ M P) → P ⊢ modw M W P.
  Proof. iIntros (toM) "??". iApply toM. iFrame. Qed.
  Lemma from_modal_modw {M W P} :
    (∀ P, P ⊢ M P) → FromModal True modality_id (modw M W P) (modw M W P) P.
  Proof. rewrite /FromModal=> ? _. by apply modw_intro. Qed.
  Lemma from_assumption_modw {M W} `{!FromAssumption p P Q} :
    (∀ P, P ⊢ M P) → KnownRFromAssumption p P (modw M W Q).
  Proof.
    move: FromAssumption0. rewrite /KnownRFromAssumption /FromAssumption=> -> ?.
    by apply modw_intro.
  Qed.
  Lemma from_pure_modw {M W} `{!FromPure a P φ} :
    (∀ P, P ⊢ M P) → FromPure a (modw M W P) φ.
  Proof. move: FromPure0. rewrite /FromPure=> -> ?. by apply modw_intro. Qed.

  (** Compose [modw]s composing the modalities *)
  Lemma modw_compose `{!Proper ((⊢) ==> (⊢)) M} {M' M'' W P} :
    (∀ P, M (M' P) ⊢ M'' P) → modw M W (modw M' W P) ⊢ modw M'' W P.
  Proof.
    iIntros (toM'') "→P W". iDestruct ("→P" with "W") as "→P". iApply toM''.
    iStopProof. f_equiv. iIntros "[W →P]". by iApply "→P".
  Qed.

  (** [modw] frames for framing [M] *)
  Lemma modw_frame_r `{!Proper ((⊣⊢) ==> (⊣⊢)) M} {W P Q} :
    (∀ P Q, M P ∗ Q ⊢ M (P ∗ Q)) → modw M W P ∗ Q ⊢ modw M W (P ∗ Q).
  Proof.
    iIntros (fr) "[→P Q] W". iDestruct ("→P" with "W") as "→P". rewrite assoc.
    iApply fr. iFrame.
  Qed.
  Lemma modw_frame_l `{!Proper ((⊣⊢) ==> (⊣⊢)) M} {W P Q} :
    (∀ P Q, M P ∗ Q ⊢ M (P ∗ Q)) → Q ∗ modw M W P ⊢ modw M W (Q ∗ P).
  Proof. rewrite !(comm _ Q). apply modw_frame_r. Qed.

  (** Compose [modw]s accumulating the world satisfaction *)
  Lemma modw_modw_sep `{!Proper ((⊣⊢) ==> (⊣⊢)) M} {W W' P} :
    modw (modw M W) W' P ⊣⊢ modw M (W ∗ W') P.
  Proof.
    iSplit.
    - iIntros "→P [W W']". iDestruct ("→P" with "W'") as "→P".
      iDestruct ("→P" with "W") as "→P". iStopProof. apply bi.equiv_entails.
      f_equiv. by rewrite assoc.
    - iIntros "→P W' W". iDestruct ("→P" with "[$W $W']") as "→P". iStopProof.
      apply bi.equiv_entails. f_equiv. by rewrite assoc.
  Qed.

  (** [modw] over [emp] world satisfaction *)
  Lemma modw_emp `{!Proper ((⊣⊢) ==> (⊣⊢)) M} {P} : modw M emp P ⊣⊢ M P.
  Proof. by rewrite /modw !left_id. Qed.
End lemmas.

(** ** Update with a custom world satisfaction [W] *)

(** Basic update with a world satisfaction *)
Notation bupdw := (modw bupd).
(** Fancy update with a world satisfaction *)
Notation fupdw E E' := (modw (fupd E E')).

(** *** Notation *)

Module UpdwNotation.
  Notation "|=[ W ] => P" := (bupdw W P)
    (at level 99, P at level 200, format "'[  ' |=[ W ] =>  '/' P ']'")
    : bi_scope.
  Notation "P =[ W ]=∗ Q" := (P -∗ |=[W]=> Q)%I
    (at level 99, Q at level 200, format "'[' P  =[ W ]=∗  '/' '[' Q ']' ']'")
    : bi_scope.
  Notation "P =[ W ]=∗ Q" := (P -∗ |=[W]=> Q) : stdpp_scope.

  Notation "|=[ W ] { E , E' }=> P" := (fupdw E E' W P)
    (at level 99, P at level 200,
      format "'[  ' |=[ W ] { E , E' }=>  '/' P ']'") : bi_scope.
  Notation "|=[ W ] { E }=> P" := (fupdw E E W P)
    (at level 99, P at level 200, format "'[  ' |=[ W ] { E }=>  '/' P ']'")
    : bi_scope.
  Notation "P =[ W ] { E , E' }=∗ Q" := (P -∗ |=[W]{E,E'}=> Q)%I
    (at level 99, Q at level 200,
      format "'[' P  =[ W ] { E , E' }=∗  '/' '[' Q ']' ']'") : bi_scope.
  Notation "P =[ W ] { E , E' }=∗ Q" := (P -∗ |=[W]{E,E'}=> Q) : stdpp_scope.
  Notation "P =[ W ] { E }=∗ Q" := (P -∗ |=[W]{E}=> Q)%I
    (at level 99, Q at level 200,
      format "'[' P  =[ W ] { E }=∗  '/' '[' Q ']' ']'") : bi_scope.
  Notation "P =[ W ] { E }=∗ Q" := (P -∗ |=[W]{E}=> Q) : stdpp_scope.

  (** We move the position of [▷] to make the notation work *)
  Notation "|=[ W ] { E }▷[ E' ] => P" := (|=[W]{E,E'}=> ▷ |=[W]{E',E}=> P)%I
    (at level 99, P at level 200,
      format "'[  ' |=[ W ] { E }▷[ E' ] =>  '/' P ']'") : bi_scope.
  Notation "|=[ W ] { E }▷=> P" := (|=[W]{E}=> ▷ |=[W]{E}=> P)%I
    (at level 99, P at level 200,
      format "'[  ' |=[ W ] { E }▷=>  '/' P ']'") : bi_scope.
  Notation "|=[ W ] { E }▷[ E' ] =>^ n P" :=
    (Nat.iter n (λ Q, |=[W]{E}▷[E'] => Q) P)%I
    (at level 99, P at level 200, n at level 9,
      format "'[  ' |=[ W ] { E }▷[ E' ] =>^ n  '/' P ']'") : bi_scope.
  Notation "|=[ W ] { E }▷=>^ n P" :=
    (Nat.iter n (λ Q, |=[W]{E}▷=> Q) P)%I
    (at level 99, P at level 200, n at level 9,
      format "'[  ' |=[ W ] { E }▷=>^ n  '/' P ']'") : bi_scope.
End UpdwNotation.
Import UpdwNotation.

(** *** Lemmas *)
Section lemmas.
  Context {PROP}.
  Implicit Type (M : PROP → PROP) (W P Q R : PROP).

  (** For [modw M] over [AbsorbBUpd] [M] *)
  Lemma from_bupdw `{!BiBUpd PROP, !ModIntro M, !AbsorbBUpd M} {W P} :
    (|=[W]=> P) ⊢ modw M W P.
  Proof. by rewrite /bupdw /modw -(absorb_bupd (M:=M)) -(mod_intro (M:=M)). Qed.
  #[export] Instance elim_modal_modw_mod_upd {p P Q}
    `{!BiBUpd PROP, !Mod M, !ModTrans M, !ModFrame M, !WsatIncl W W' Wr} :
    ElimModal True p false (modw M W' P) P (modw M W Q) (modw M W Q) | 10.
  Proof.
    by rewrite /ElimModal bi.intuitionistically_if_elim mod_frame_r
      bi.wand_elim_r (modw_incl (W:=W)) mod_trans.
  Qed.
  #[export] Instance elim_modal_bupdw_modw_mod_upd {p P Q}
    `{!BiBUpd PROP, !Mod M, !ModTrans M, !ModFrame M, !ModIntro M,
      !AbsorbBUpd M, !WsatIncl W W' Wr} :
    ElimModal True p false (|=[W']=> P) P (modw M W Q) (modw M W Q) | 10.
  Proof. move=> ?. by rewrite (from_bupdw (M:=M)) elim_modal_modw_mod_upd. Qed.

  (** [fupdw] absorbs [◇] *)
  #[export] Instance is_except_0_fupdw `{!BiFUpd PROP} {E E' W P} :
    IsExcept0 (|=[W]{E,E'}=> P).
  Proof. rewrite /IsExcept0. by iIntros ">?". Qed.

  (** [bupdw] is monotone *)
  #[export] Instance bupdw_mono `{!BiBUpd PROP} {W} :
    Proper ((⊢) ==> (⊢)) (bupdw W).
  Proof. exact _. Qed.
  #[export] Instance bupdw_flip_mono `{!BiBUpd PROP} {W} :
    Proper (flip (⊢) ==> flip (⊢)) (bupdw W).
  Proof. exact _. Qed.

  (** [fupdw] is monotone *)
  #[export] Instance fupdw_mono `{!BiFUpd PROP} {E E' W} :
    Proper ((⊢) ==> (⊢)) (fupdw E E' W).
  Proof. exact _. Qed.
  #[export] Instance fupdw_flip_mono `{!BiFUpd PROP} {E E' W} :
    Proper (flip (⊢) ==> flip (⊢)) (fupdw E E' W).
  Proof. exact _. Qed.

  (** Modify the world satisfaction of [bupdw] *)
  Lemma bupdw_incl_bupd `{!BiBUpd PROP} {W W' P} :
    (W ==∗ W' ∗ (W' ==∗ W)) -∗ (|=[W']=> P) =[W]=∗ P.
  Proof.
    iIntros "∝ →P W". iMod ("∝" with "W") as "[W' →W]".
    iMod ("→P" with "W'") as "[W' $]". by iApply "→W".
  Qed.
  Lemma bupdw_incl `{!BiBUpd PROP} {P} `(!WsatIncl W W' Wr) :
    (|=[W']=> P) ⊢ |=[W]=> P.
  Proof. exact (modw_incl WsatIncl0). Qed.

  (** Modify the world satisfaction of [fupdw] *)
  Lemma fupdw_incl_fupd `{!BiFUpd PROP} {W W' E E' P} :
    (W ={E}=∗ W' ∗ (W' ={E'}=∗ W)) -∗ (|=[W']{E,E'}=> P) =[W]{E,E'}=∗ P.
  Proof.
    iIntros "∝ →P W". iMod ("∝" with "W") as "[W' →W]".
    iMod ("→P" with "W'") as "[W' $]". by iApply "→W".
  Qed.
  Lemma fupdw_incl `{!BiFUpd PROP} {E E' P} `(!WsatIncl W W' Wr) :
    (|=[W']{E,E'}=> P) ⊢ |=[W]{E,E'}=> P.
  Proof. apply (modw_incl WsatIncl0). Qed.

  (** Introduce [bupdw] *)
  #[export] Instance from_modal_bupdw `{!BiBUpd PROP} {W P} :
    FromModal True modality_id (|=[W]=> P) (|=[W]=> P) P.
  Proof. exact _. Qed.
  #[export] Instance from_assumption_bupdw
    `{!BiBUpd PROP, !FromAssumption p P Q} {W} :
    KnownRFromAssumption p P (|=[W]=> Q).
  Proof. exact _. Qed.
  #[export] Instance from_pure_bupdw `{!BiBUpd PROP, !FromPure a P φ} {W} :
    FromPure a (|=[W]=> P) φ.
  Proof. exact _. Qed.

  (** Introduce [fupdw] *)
  #[export] Instance from_modal_fupdw `{!BiFUpd PROP} {E W P} :
    FromModal True modality_id (|=[W]{E}=> P) (|=[W]{E}=> P) P.
  Proof. apply from_modal_modw. iIntros. by iModIntro. Qed.
  #[export] Instance from_modal_fupdw_wrong_mask `{!BiFUpd PROP} {E E' W P} :
    FromModal (pm_error
      "Only non-mask-changing update modalities can be introduced directly.
Use [iApply fupdw_mask_intro] to introduce mask-changing update modalities")
      modality_id (|=[W]{E,E'}=> P) (|=[W]{E,E'}=> P) P | 100.
  Proof. by case. Qed.
  #[export] Instance from_assumption_fupdw
    `{!BiFUpd PROP, !FromAssumption p P Q} {E W} :
    KnownRFromAssumption p P (|=[W]{E}=> Q).
  Proof. apply from_assumption_modw. iIntros. by iModIntro. Qed.
  #[export] Instance from_pure_fupdw `{!BiFUpd PROP, !FromPure a P φ} {E W} :
    FromPure a (|=[W]{E}=> P) φ.
  Proof. apply from_pure_modw. iIntros. by iModIntro. Qed.
  Lemma fupdw_mask_intro `{!BiFUpd PROP} {E E' W P} : E' ⊆ E →
    ((|={E',E}=> emp) -∗ P) ⊢ |=[W]{E,E'}=> P.
  Proof. iIntros (?) "? $". by iApply fupd_mask_intro. Qed.
  Lemma bupdw_fupdw `{!BiBUpd PROP, !BiFUpd PROP, !BiBUpdFUpd PROP} E {W P} :
    (|=[W]=> P) ⊢ |=[W]{E}=> P.
  Proof. exact from_bupdw. Qed.

  (** Frame over [bupdw] *)
  #[export] Instance frame_bupdw `{!BiBUpd PROP, !Frame p R P Q} {W} :
    Frame p R (|=[W]=> P) (|=[W]=> Q) | 2.
  Proof. exact _. Qed.

  (** Frame over [fupdw] *)
  #[export] Instance frame_fupdw `{!BiFUpd PROP, !Frame p R P Q} {E E' W} :
    Frame p R (|=[W]{E,E'}=> P) (|=[W]{E,E'}=> Q) | 2.
  Proof. exact _. Qed.
  Lemma fupdw_frame_r `{!BiFUpd PROP} {E E' W P Q} :
    (|=[W]{E,E'}=> P) ∗ Q ⊢ |=[W]{E,E'}=> P ∗ Q.
  Proof. by iIntros "[? $]". Qed.

  (** Compose with [bupdw] *)
  #[export] Instance elim_modal_bupdw `{!BiBUpd PROP, !WsatIncl W W' Wr}
    {p P Q} : ElimModal True p false (|=[W']=> P) P (|=[W]=> Q) (|=[W]=> Q).
  Proof. rewrite /ElimModal (bupdw_incl (W:=W)). exact elim_modal_mod_upd. Qed.
  #[export] Instance elim_modal_bupdw_wrong_wsat `{!BiBUpd PROP} {p P Q W W'} :
    ElimModal
      (pm_error "The target world satisfaction doesn't satisfy [WsatIncl]")
      p false (|=[W']=> P) False (|=[W]=> Q) False | 100.
  Proof. case. Qed.
  #[export] Instance elim_modal_bupd_bupdw `{!BiBUpd PROP} {p W P Q} :
    ElimModal True p false (|==> P) P (|=[W]=> Q) (|=[W]=> Q).
  Proof. exact _. Qed.
  #[export] Instance add_modal_bupdw `{!BiBUpd PROP} {W P Q} :
    AddModal (|=[W]=> P) P (|=[W]=> Q).
  Proof. exact _. Qed.

  (** Compose with [fupdw] *)
  Lemma fupdw_trans `{!BiFUpd PROP} {E E' E'' W P} :
    (|=[W]{E,E'}=> |=[W]{E',E''}=> P) ⊢ |=[W]{E,E''}=> P.
  Proof. apply modw_compose. by iIntros "% >?". Qed.
  #[export] Instance elim_modal_fupdw_fupdw
    `{!BiFUpd PROP, !WsatIncl W W' Wr} {p E E' E'' P Q} :
    ElimModal True p false (|=[W']{E,E'}=> P) P
      (|=[W]{E,E''}=> Q) (|=[W]{E',E''}=> Q).
  Proof.
    by rewrite /ElimModal bi.intuitionistically_if_elim fupdw_frame_r
      bi.wand_elim_r (fupdw_incl (W:=W)) fupdw_trans.
  Qed.
  #[export] Instance elim_modal_fupdw_fupdw_wrong_mask
    `{!BiFUpd PROP, !WsatIncl W W' Wr} {p E E' E'' E''' P Q} :
    ElimModal
      (pm_error "Goal and eliminated modality must have the same mask.
Use [iMod (fupd_mask_subseteq E')] to adjust the mask of your goal to [E']")
      p false (|=[W']{E,E'}=> P) False (|=[W]{E'',E'''}=> Q) False | 80.
  Proof. case. Qed.
  #[export] Instance elim_modal_fupdw_fupdw_wrong_wsat
    `{!BiFUpd PROP} {p E E' E'' P Q W W'} :
    ElimModal
      (pm_error "The target world satisfaction doesn't satisfy [WsatIncl]")
      p false (|=[W']{E,E'}=> P) False (|=[W]{E,E''}=> Q) False | 100.
  Proof. case. Qed.
  #[export] Instance elim_modal_bupdw_fupdw {p E E' P Q}
    `{!BiBUpd PROP, !BiFUpd PROP, !BiBUpdFUpd PROP, !WsatIncl W W' Wr} :
    ElimModal True p false (|=[W']=> P) P (|=[W]{E,E'}=> Q) (|=[W]{E,E'}=> Q).
  Proof. move=> ?. by rewrite (bupdw_fupdw E) elim_modal_fupdw_fupdw. Qed.
  #[export] Instance elim_modal_bupdw_fupdw_wrong_wsat {p E E' P Q W W'}
    `{!BiBUpd PROP, !BiFUpd PROP, !BiBUpdFUpd PROP} :
    ElimModal
      (pm_error "The target world satisfaction doesn't satisfy [WsatIncl]")
      p false (|=[W']=> P) False (|=[W]{E,E'}=> Q) False | 100.
  Proof. case. Qed.
  #[export] Instance elim_modal_fupd_fupdw `{!BiFUpd PROP} {p E E' E'' W P Q} :
    ElimModal True p false (|={E,E'}=> P) P
      (|=[W]{E,E''}=> Q) (|=[W]{E',E''}=> Q).
  Proof. exact _. Qed.
  #[export] Instance elim_modal_fupd_fupdw_wrong_mask `{!BiFUpd PROP}
    {p E E' E'' E''' P Q W} :
    ElimModal
      (pm_error "Goal and eliminated modality must have the same mask.
Use [iMod (fupd_mask_subseteq E')] to adjust the mask of your goal to [E']")
      p false (|={E,E'}=> P) False (|=[W]{E'',E'''}=> Q) False | 100.
  Proof. case. Qed.
  #[export] Instance elim_modal_bupd_fupdw
    `{!BiBUpd PROP, !BiFUpd PROP, !BiBUpdFUpd PROP} {p E E' W P Q} :
    ElimModal True p false (|==> P) P (|=[W]{E,E'}=> Q) (|=[W]{E,E'}=> Q).
  Proof. exact _. Qed.
  #[export] Instance add_modal_fupdw `{!BiFUpd PROP} {E E' W P Q} :
    AddModal (|=[W]{E}=> P) P (|=[W]{E,E'}=> Q).
  Proof. by rewrite /AddModal fupdw_frame_r bi.wand_elim_r fupdw_trans. Qed.
  #[export] Instance add_modal_fupd_fupdw `{!BiFUpd PROP} {E E' W P Q} :
    AddModal (|={E}=> P) P (|=[W]{E,E'}=> Q).
  Proof. rewrite /AddModal fupd_frame_r bi.wand_elim_r. iIntros ">$". Qed.

  (** [modw] over [bupdw] *)
  Lemma modw_bupdw `{!BiBUpd PROP} {W W' P} :
    modw (bupdw W) W' P ⊣⊢ |=[W ∗ W']=> P.
  Proof. exact modw_modw_sep. Qed.
  (** [modw] over [fupdw] *)
  Lemma modw_fupdw `{!BiFUpd PROP} {W W' E E' P} :
    modw (fupdw E E' W) W' P ⊣⊢ |=[W ∗ W']{E,E'}=> P.
  Proof. exact modw_modw_sep. Qed.

  (** More instances for [bupdw] *)
  #[export] Instance from_sep_bupdw `{!BiBUpd PROP, !FromSep P Q Q'} {W} :
    FromSep (|=[W]=> P) (|=[W]=> Q) (|=[W]=> Q').
  Proof. exact _. Qed.
  #[export] Instance from_or_bupdw `{!BiBUpd PROP, !FromOr P Q Q'} {W} :
    FromOr (|=[W]=> P) (|=[W]=> Q) (|=[W]=> Q').
  Proof. exact _. Qed.
  #[export] Instance from_exist_bupdw `{!BiBUpd PROP, !FromExist (A:=A) P Φ}
    {W} : FromExist (|=[W]=> P) (λ x, |=[W]=> (Φ x))%I.
  Proof. exact _. Qed.
  #[export] Instance into_and_bupdw `{!BiBUpd PROP, !IntoAnd false P Q R} {W} :
    IntoAnd false (|=[W]=> P) (|=[W]=> Q) (|=[W]=> R).
  Proof. exact _. Qed.
  #[export] Instance into_forall_bupdw `{!BiBUpd PROP, !IntoForall (A:=A) P Φ}
    {W} : IntoForall (|=[W]=> P) (λ x, |=[W]=> (Φ x))%I.
  Proof. exact _. Qed.

  (** More instances for [fupdw] *)
  #[export] Instance from_sep_fupdw `{!BiFUpd PROP, !FromSep P Q Q'} {E W} :
    FromSep (|=[W]{E}=> P) (|=[W]{E}=> Q) (|=[W]{E}=> Q').
  Proof. rewrite /FromSep -(from_sep P). by iIntros "[>$ >$]". Qed.
  #[export] Instance from_or_fupdw `{!BiFUpd PROP, !FromOr P Q Q'} {E W} :
    FromOr (|=[W]{E}=> P) (|=[W]{E}=> Q) (|=[W]{E}=> Q').
  Proof.
    rewrite /FromOr -(from_or P). iIntros "[>?|>?] !>"; by [iLeft|iRight].
  Qed.
  #[export] Instance from_exist_fupdw `{!BiFUpd PROP, !FromExist (A:=A) P Φ}
    {E E' W} : FromExist (|=[W]{E,E'}=> P) (λ x, |=[W]{E,E'}=> (Φ x))%I.
  Proof.
    rewrite /FromExist -(from_exist P). iIntros "[% >?] !>". by iExists _.
  Qed.
  #[export] Instance into_and_fupdw
    `{!BiFUpd PROP, !IntoAnd false P Q R} {E E' W} :
    IntoAnd false (|=[W]{E,E'}=> P) (|=[W]{E,E'}=> Q) (|=[W]{E,E'}=> R).
  Proof.
    move: IntoAnd0. rewrite /IntoAnd=>/=->. iIntros "∧".
    iSplit; by [iMod "∧" as "[$ _]"|iMod "∧" as "[_ $]"].
  Qed.
  #[export] Instance into_forall_fupdw
    `{!BiFUpd PROP, !IntoForall (A:=A) P Φ} {E E' W} :
    IntoForall (|=[W]{E,E'}=> P) (λ x, |=[W]{E,E'}=> (Φ x))%I.
  Proof.
    rewrite /IntoForall (into_forall P). iIntros "Φ %". iMod "Φ". iApply "Φ".
  Qed.
  #[export] Instance elim_acc_fupdw `{!BiFUpd PROP} {X E E' E'' W α β γ P} :
    ElimAcc (X:=X) True (fupd E E') (fupd E' E) α β γ (|=[W]{E,E''}=> P)
      (λ x, |=[W]{E'}=> β x ∗ (γ x -∗? |=[W]{E,E''}=> P))%I.
  Proof.
    iIntros (_) "→P ∝ W". iMod "∝" as (x) "[α β→]".
    iMod ("→P" with "α W") as "[W[β γ→]]".
    iMod ("β→" with "β") as "γ". by iApply ("γ→" with "γ").
  Qed.

  (** Turn [step_fupdwN] into [step_fupdN]

    Combining this with adequacy lemmas for [step_fupdN],
    one can prove adequacy lemmas for [step_fupdwN]. *)
  Lemma step_fupdwN_step_fupdN `{!BiFUpd PROP} {W n E E' P} :
    (|=[W]{E}▷[E']=>^n P) ⊢ W -∗ |={E}[E']▷=>^n W ∗ P.
  Proof.
    elim: n=>/=; [by iIntros; iFrame|]=> n ->.
    iIntros "big W". iMod ("big" with "W") as "[W big]". iModIntro. iNext.
    iMod ("big" with "W") as "[W big]". iModIntro. by iApply "big".
  Qed.
End lemmas.
(** * Modality classes *)

From nola Require Export prelude.
From nola.bi Require Import util.
From iris.bi Require Export bi.
From iris.proofmode Require Import proofmode.

Implicit Type PROP : bi.

(** ** [GenUpd]: General update, i.e., monad strong w.r.t. [∗] *)

Class GenUpd {PROP} (M : PROP → PROP) : Prop := GEN_UPD {
  gen_upd_ne :: NonExpansive M;
  gen_upd_mono {P Q} : (P ⊢ Q) → M P ⊢ M Q;
  gen_upd_intro {P} : P ⊢ M P;
  gen_upd_trans {P} : M (M P) ⊢ M P;
  gen_upd_frame_r {P Q} : M P ∗ Q ⊢ M (P ∗ Q);
}.
Hint Mode GenUpd + ! : typeclass_instances.

#[export] Instance gen_upd_proper `{!@GenUpd PROP M} :
  Proper ((⊣⊢) ==> (⊣⊢)) M.
Proof. apply ne_proper, _. Qed.

(** Instances of [GenUpd] *)
#[export] Instance id_gen_upd {PROP} : GenUpd (PROP:=PROP) id.
Proof. split; [exact _|done..]. Qed.
#[export] Instance except_0_gen_upd {PROP} : GenUpd (PROP:=PROP) bi_except_0.
Proof.
  split=> >. { exact _. } { by move=> ->. } { by iIntros. } { iIntros ">$". }
  { by iIntros "[>$$]". }
Qed.
#[export] Instance bupd_gen_upd `{!BiBUpd PROP} : GenUpd (PROP:=PROP) bupd.
Proof.
  split=> >. { exact _. } { by move=> ->. } { by iIntros. } { iIntros ">$". }
  { by iIntros "[>$$]". }
Qed.
#[export] Instance fupd_gen_upd `{!BiFUpd PROP} {E} :
  GenUpd (PROP:=PROP) (fupd E E).
Proof.
  split=> >. { exact _. } { by move=> ->. } { by iIntros "? !>". }
  { iIntros ">$". } { by iIntros "[>$$]". }
Qed.

Section gen_upd.
  Context `{!GenUpd (PROP:=PROP) M}.

  (** Monotonicity *)
  #[export] Instance gen_upd_mono' : Proper ((⊢) ==> (⊢)) M | 10.
  Proof. move=> ??. apply gen_upd_mono. Qed.
  #[export] Instance gen_upd_flip_mono' : Proper (flip (⊢) ==> flip (⊢)) M | 10.
  Proof. move=>/= ??. apply gen_upd_mono. Qed.

  (** Introduce *)
  #[export] Instance from_modal_gen_upd {P} :
    FromModal True modality_id (M P) (M P) P | 10.
  Proof. move=> _. rewrite /FromModal /=. apply gen_upd_intro. Qed.
  #[export] Instance from_assumption_gen_upd `{!FromAssumption p P Q} :
    KnownRFromAssumption p P (M Q) | 10.
  Proof.
    rewrite /KnownRFromAssumption /FromAssumption from_assumption.
    apply gen_upd_intro.
  Qed.
  #[export] Instance from_pure_gen_upd `{!FromPure a P φ} :
    FromPure a (M P) φ | 10.
  Proof. rewrite /FromPure -(from_pure _ P). apply gen_upd_intro. Qed.

  (** Frame *)
  Lemma gen_upd_frame_l {P Q} : P ∗ M Q ⊢ M (P ∗ Q).
  Proof. by rewrite comm gen_upd_frame_r comm. Qed.
  #[export] Instance frame_gen_upd `{!Frame p R P Q} :
    Frame p R (M P) (M Q) | 10.
  Proof. move: Frame0. rewrite /Frame=> <-. apply gen_upd_frame_l. Qed.

  (** Transitivity *)
  #[export] Instance elim_modal_gen_upd {p P Q} :
    ElimModal True p false (M P) P (M Q) (M Q) | 10.
  Proof.
    by rewrite /ElimModal bi.intuitionistically_if_elim gen_upd_frame_r
      bi.wand_elim_r gen_upd_trans.
  Qed.
  #[export] Instance add_modal_gen_upd {P Q} : AddModal (M P) P (M Q) | 10.
  Proof. by rewrite /AddModal gen_upd_frame_r bi.wand_elim_r gen_upd_trans. Qed.

  (** More instances *)
  #[export] Instance from_sep_gen_upd `{!FromSep P Q Q'} :
    FromSep (M P) (M Q) (M Q') | 10.
  Proof. rewrite /FromSep -(from_sep P). by iIntros "[>$ >$]". Qed.
  #[export] Instance from_or_gen_upd `{!FromOr P Q Q'} :
    FromOr (M P) (M Q) (M Q') | 10.
  Proof.
    rewrite /FromOr -(from_or P). iIntros "[>?|>?] !>"; by [iLeft|iRight].
  Qed.
  #[export] Instance from_exist_gen_upd `{!FromExist (A:=A) P Φ} :
    FromExist (M P) (λ x, M (Φ x)) | 10.
  Proof.
    rewrite /FromExist -(from_exist P). iIntros "[% >?] !>". by iExists _.
  Qed.
  #[export] Instance into_and_gen_upd `{!IntoAnd false P Q R} :
    IntoAnd false (M P) (M Q) (M R) | 10.
  Proof.
    move: IntoAnd0. rewrite /IntoAnd=>/=->. iIntros "∧".
    iSplit; by [iMod "∧" as "[$ _]"|iMod "∧" as "[_ $]"].
  Qed.
  #[export] Instance into_forall_gen_upd `{!IntoForall (A:=A) P Φ} :
    IntoForall (M P) (λ x, M (Φ x)) | 10.
  Proof.
    rewrite /IntoForall (into_forall P). iIntros "Φ %". iMod "Φ". iApply "Φ".
  Qed.

  (** [GenUpd] [M] with [relax_0] absorbs [◇] *)
  #[export] Instance gen_upd_relax_0_is_except_0 {P} :
    IsExcept0 (relax_0 M P)%I | 10.
  Proof. apply is_except_0_intro. by iIntros. Qed.

  (** [relax_0] preserves [GenUpd] *)
  #[export] Instance gen_upd_relax_0 : GenUpd (relax_0 M)%I | 10.
  Proof.
    split=> >. { solve_proper. } { solve_proper. } { by iIntros. }
    { iIntros ">>$". } { by iIntros "[?$]". }
  Qed.

  (** [MonoidHomomorphism] instances *)
  Lemma gen_upd_sep {P Q} : M P ∗ M Q ⊢ M (P ∗ Q).
  Proof. by iIntros "[>$ >$]". Qed.
  #[export] Instance gen_upd_sep_homomorphism :
    MonoidHomomorphism bi_sep bi_sep (flip (⊢)) M | 10.
  Proof.
    split; [split|]; (try apply _)=> >; [apply gen_upd_sep|apply gen_upd_intro].
  Qed.
  Lemma gen_upd_or {P Q} : M P ∨ M Q ⊢ M (P ∨ Q).
  Proof. iIntros "[>?|>?] !>"; by [iLeft|iRight]. Qed.
  #[export] Instance gen_upd_or_homomorphism :
    MonoidHomomorphism bi_or bi_or (flip (⊢)) M | 10.
  Proof.
    split; [split|]; (try apply _)=> >; [apply gen_upd_or|apply gen_upd_intro].
  Qed.

  (** Over big operators *)
  Lemma big_sepL_gen_upd {A} (Φ : nat → A → PROP) l :
    ([∗ list] k↦x ∈ l, M (Φ k x)) ⊢ M ([∗ list] k↦x ∈ l, Φ k x).
  Proof. by rewrite (big_opL_commute _). Qed.
  Lemma big_sepM_gen_upd {A} `{Countable K} (Φ : K → A → PROP) l :
    ([∗ map] k↦x ∈ l, M (Φ k x)) ⊢ M ([∗ map] k↦x ∈ l, Φ k x).
  Proof. by rewrite (big_opM_commute _). Qed.
  Lemma big_sepS_gen_upd `{Countable A} (Φ : A → PROP) l :
    ([∗ set] x ∈ l, M (Φ x)) ⊢ M ([∗ set] x ∈ l, Φ x).
  Proof. by rewrite (big_opS_commute _). Qed.
  Lemma big_sepMS_gen_upd `{Countable A} (Φ : A → PROP) l :
    ([∗ mset] x ∈ l, M (Φ x)) ⊢ M ([∗ mset] x ∈ l, Φ x).
  Proof. by rewrite (big_opMS_commute _). Qed.
End gen_upd.

(** ** [FromBUpd]: Modality subsuming [bupd] *)

Class FromBUpd `{!BiBUpd PROP} (M : PROP → PROP) : Prop :=
  from_bupd : ∀{P}, (|==> P) ⊢ M P.
Hint Mode FromBUpd + - ! : typeclass_instances.

(** [bupd] and [fupd] satisfy [FromBUpd] *)
#[export] Instance bupd_from_bupd `{!BiBUpd PROP} : FromBUpd (PROP:=PROP) bupd.
Proof. by move=> ?. Qed.
#[export] Instance fupd_from_bupd
  `{!BiBUpd PROP, !BiFUpd PROP, !BiBUpdFUpd PROP} {E} :
  FromBUpd (PROP:=PROP) (fupd E E).
Proof. by iIntros (?) ">?". Qed.

Section from_bupd.
  Context `{!BiBUpd PROP, !FromBUpd (PROP:=PROP) M, !GenUpd (PROP:=PROP) M}.

  (** [relax_0] preserves [FromBUpd] *)
  #[export] Instance from_bupd_relax_0 : FromBUpd (relax_0 M)%I | 10.
  Proof.
    move=> ?. rewrite (from_bupd (M:=M)) /relax_0. f_equiv. by iIntros.
  Qed.

  (** Eliminate [bupd] under [FromBupd] *)
  #[export] Instance elim_modal_from_bupd {p P Q} :
    ElimModal True p false (|==> P) P (M Q) (M Q) | 10.
  Proof.
    by rewrite /ElimModal bi.intuitionistically_if_elim gen_upd_frame_r
      bi.wand_elim_r (from_bupd (M:=M)) gen_upd_trans.
  Qed.
End from_bupd.

(** ** [ModPlain]: Modality behaving nicely over plain propositions

  Analogous to [BiFupdPlainly] *)

Class ModPlain `{!BiPlainly PROP} M : Prop := GEN_UPD_PLAIN {
  (** Eliminate the modality over a plain proposition, keeping the premise *)
  mod_plain_keep_l `{!Plain P} {R} : (R -∗ M P) ∗ R ⊢ M (P ∗ R);
  (** Eliminating a universal quantifier over the modality over plain
    propositions *)
  mod_plain_forall_2 {A} {Φ : A → PROP} `{!∀ a, Plain (Φ a)} :
    (∀ a, M (Φ a)) ⊢ M (∀ a, Φ a);
}.
Hint Mode ModPlain + - ! : typeclass_instances.

(** [id] is [ModPlain] *)
#[export] Instance id_mod_plain `{!BiPlainly PROP, !BiAffine PROP} :
  ModPlain (PROP:=PROP) id.
Proof.
  split=>/=; [|done]. move=> >. iIntros "[→P R]".
  iDestruct ("→P" with "R") as "#?". by iFrame.
Qed.

(** [◇] is [ModPlain] *)
#[export] Instance except_0_mod_plain `{!BiPlainly PROP, !BiAffine PROP} :
  ModPlain (PROP:=PROP) bi_except_0.
Proof.
  split.
  { move=> >. iIntros "[→P R]". iDestruct ("→P" with "R") as "#?". by iFrame. }
  { move=> >. by iIntros "? %". }
Qed.

(** [bupd] is [ModPlain] under [BiBUpdPlainly] *)
#[export] Instance bupd_mod_plain
  `{!BiBUpd PROP, !BiPlainly PROP, !BiBUpdPlainly PROP, !BiAffine PROP} :
  ModPlain (PROP:=PROP) bupd.
Proof.
  split.
  - move=> >. iIntros "[→P R] !>". rewrite bupd_elim.
    iDestruct ("→P" with "R") as "#?". by iFrame.
  - move=> ? Φ ?. have ->: (∀ a, |==> Φ a) ⊢ (∀ a, Φ a); [|by iIntros].
    f_equiv=> ?. by rewrite bupd_elim.
Qed.

(** [fupd] is [ModPlain] under [BiFUpdPlainly] *)
#[export] Instance fupd_mod_plain
  `{!BiFUpd PROP, !BiPlainly PROP, !BiFUpdPlainly PROP} {E} :
  ModPlain (PROP:=PROP) (fupd E E).
Proof.
  split=> >. { apply fupd_plain_keep_l, _. } { apply fupd_plain_forall_2, _. }
Qed.

(** [relax_0] preserves [ModPlain] *)
#[export] Instance mod_plain_except_0
  `{!BiPlainly PROP, !@GenUpd PROP M, !ModPlain M} :
  ModPlain (relax_0 M).
Proof.
  unfold relax_0. split.
  - move=> >. rewrite mod_plain_keep_l. by iIntros ">[>$$]".
  - move=> >. by rewrite mod_plain_forall_2 bi.except_0_forall.
Qed.

Section mod_plain.
  Context `{!BiPlainly PROP, !@GenUpd PROP M, !ModPlain M}.

  (** Variant of [mod_plain_keep_l] *)
  Lemma mod_plain_keep_r `{!Plain P} {R} : R ∗ (R -∗ M P) ⊢ M (R ∗ P).
  Proof. rewrite comm [(_ ∗ P)%I]comm. apply mod_plain_keep_l. Qed.

  (** Variant of [mod_plain_forall_2] *)
  Lemma mod_plain_forall {A} {Φ : A → PROP} `{!∀ a, Plain (Φ a)} :
    M (∀ a, Φ a) ⊣⊢ ∀ a, M (Φ a).
  Proof.
    apply bi.equiv_entails. split; [|exact mod_plain_forall_2].
    iIntros "→Φ %". by iMod "→Φ".
  Qed.
End mod_plain.

Section mod_acsr.
  Context {PROP}.

  (** ** [mod_acsr]: Accessor from [P] to [Q] via the modality [M] *)
  Definition mod_acsr M P Q : PROP := P -∗ M (Q ∗ (Q -∗ M P))%I.

  (** [mod_acsr] is non-expansive *)
  #[export] Instance mod_acsr_ne_gen {n} :
    Proper (((≡{n}≡) ==> (≡{n}≡)) ==> (≡{n}≡) ==> (≡{n}≡) ==> (≡{n}≡)) mod_acsr.
  Proof.
    move=> ?? eqv ??????. unfold mod_acsr. f_equiv=>//. apply eqv.
    do 2 f_equiv=>//. by apply eqv.
  Qed.
  #[export] Instance mod_acsr_ne `{!NonExpansive M} :
    NonExpansive2 (mod_acsr M).
  Proof. exact _. Qed.
  #[export] Instance mod_acsr_proper :
    Proper (((≡) ==> (≡)) ==> (≡) ==> (≡) ==> (≡)) mod_acsr.
  Proof.
    move=> ?? eqv ??????. unfold mod_acsr. f_equiv=>//. apply eqv.
    do 2 f_equiv=>//. by apply eqv.
  Qed.

  Context `{!GenUpd (PROP:=PROP) M}.

  (** [mod_acsr] is reflexive and transitive *)
  Lemma mod_acsr_refl {P} : ⊢ mod_acsr M P P.
  Proof. by iIntros "$ !> $". Qed.
  Lemma mod_acsr_trans {P Q R} :
    mod_acsr M P Q -∗ mod_acsr M Q R -∗ mod_acsr M P R.
  Proof.
    iIntros "PQP QRQ P". iMod ("PQP" with "P") as "[Q QP]".
    iMod ("QRQ" with "Q") as "[$ RQ]". iIntros "!> R".
    iMod ("RQ" with "R") as "Q". by iApply "QP".
  Qed.

  (** [mod_acsr] over [∗] *)
  Lemma mod_acsr_sep_l {P Q} : ⊢ mod_acsr M (P ∗ Q) P.
  Proof. by iIntros "[$$] !> $". Qed.
  Lemma mod_acsr_sep_r {P Q} : ⊢ mod_acsr M (P ∗ Q) Q.
  Proof. by iIntros "[$$] !> $". Qed.

  (** [∗-∗] into [mod_acsr] *)
  Lemma wand_iff_mod_acsr {P Q} : □ (P ∗-∗ Q) ⊢ mod_acsr M P Q.
  Proof.
    iIntros "#[PQ QP] P". iDestruct ("PQ" with "P") as "$". iIntros "!> ? !>".
    by iApply "QP".
  Qed.
End mod_acsr.
Arguments mod_acsr : simpl never.

Section mod_iff.
  Context {PROP}.

  (** ** [mod_iff]: Equivalence of [P] and [Q] under the modality [M] *)
  Definition mod_iff M P Q : PROP := ((P -∗ M Q) ∧ (Q -∗ M P))%I.

  (** [mod_iff] is non-expansive *)
  #[export] Instance mod_iff_ne_gen {n} :
    Proper (((≡{n}≡) ==> (≡{n}≡)) ==> (≡{n}≡) ==> (≡{n}≡) ==> (≡{n}≡)) mod_iff.
  Proof.
    move=> ?? eqv ??????. unfold mod_iff. do 2 f_equiv=>//; by apply eqv.
  Qed.
  #[export] Instance mod_iff_ne `{!NonExpansive M} : NonExpansive2 (mod_iff M).
  Proof. exact _. Qed.
  #[export] Instance mod_iff_proper_gen :
    Proper (((≡) ==> (≡)) ==> (≡) ==> (≡) ==> (≡)) mod_iff.
  Proof.
    move=> ?? eqv ??????. unfold mod_iff. do 2 f_equiv=>//; by apply eqv.
  Qed.
  #[export] Instance mod_iff_proper `{!Proper ((≡) ==> (≡)) M} :
    Proper ((≡) ==> (≡) ==> (≡)) (mod_iff M).
  Proof. exact _. Qed.

  Context `{!GenUpd (PROP:=PROP) M}.

  (** [mod_iff] is reflexive, symmetric and transitive *)
  Lemma mod_iff_refl {P} : ⊢ mod_iff M P P.
  Proof. iSplit; by iIntros. Qed.
  Lemma mod_iff_sym {P Q} : mod_iff M P Q ⊢ mod_iff M Q P.
  Proof. by rewrite /mod_iff bi.and_comm. Qed.
  Lemma mod_iff_trans {P Q R} : mod_iff M P Q -∗ mod_iff M Q R -∗ mod_iff M P R.
  Proof.
    iIntros "PQ QR". iSplit.
    - iIntros "P". iMod ("PQ" with "P"). by iApply "QR".
    - iIntros "R". iMod ("QR" with "R"). by iApply "PQ".
  Qed.

  (** [∗-∗] into [mod_iff] *)
  Lemma wand_iff_mod_iff {P Q} : P ∗-∗ Q ⊢ mod_iff M P Q.
  Proof. iIntros "PQ". iSplit; iIntros "? !>"; by iApply "PQ". Qed.
End mod_iff.
Arguments mod_iff : simpl never.

(** * [deriv]: Derivability *)

From nola.util Require Export pred.
From iris.bi Require Import lib.fixpoint.
From iris.proofmode Require Import proofmode.

(** ** Preliminaries *)

(** [dwrap]: Wrapper for a derivability candidate *)

#[projections(primitive)]
Record dwrap (A : Type) := Dwrap { dunwrap : A }.
Arguments Dwrap {_} _.
Arguments dunwrap {_} _.
Add Printing Constructor dwrap.

(** Notation for [dwrap] *)
Module DerivNotation'.
  Notation "⸨ J ⸩ ( δ )" := (dunwrap δ J)
    (format "'[' ⸨  J  ⸩ '/  ' ( δ ) ']'") : nola_scope.
End DerivNotation'.
Import DerivNotation'.

(** Make [dwrap A] [ofe] for [A : ofe] *)
#[export] Instance dwrap_equiv `{!Equiv A} : Equiv (dwrap A)
  := λ '(Dwrap a) '(Dwrap b), a ≡ b.
#[export] Instance dwrap_dist `{!Dist A} : Dist (dwrap A)
  := λ n '(Dwrap a) '(Dwrap b), a ≡{n}≡ b.
Lemma dwrap_ofe_mixin (A : ofe) : OfeMixin (dwrap A).
Proof.
  split; unfold equiv, dist, dwrap_equiv, dwrap_dist.
  - move=> [?][?]. apply equiv_dist.
  - move=> ?. split; move=> *; by [|symmetry|etrans].
  - move=> ??[?][?]. apply dist_lt.
Qed.
Canonical dwrap_ofe (A : ofe) := Ofe (dwrap A) (dwrap_ofe_mixin A).
#[export] Instance Dwrap_ne `{A : ofe} : NonExpansive (Dwrap (A:=A)).
Proof. solve_proper. Qed.

Implicit Type (JUDG : Type) (PROP : bi).

(** Type for derivability *)
Notation deriv_ty JUDG PROP := (dwrap (JUDG -d> PROP)).

(** [derivs]: Derivation structure *)
Structure derivst (PROP : bi) : Type := Derivst {
  derivst_judg :> Type;
  (** Interpretation parameterized over derivability candidates *)
  #[canonical=no] derivst_intp :
    deriv_ty derivst_judg PROP → derivst_judg → PROP;
}.
Arguments derivst_judg {PROP DER} : rename.
Arguments derivst_intp {PROP DER} : rename.

(** Notation for [derivs_intp] *)
Notation derivst_intp' δ := (Dwrap (derivst_intp δ)).
Module IntpNotation.
  Notation "⟦ J ⟧ ( δ )" := (derivst_intp δ J)
    (format "'[' ⟦  J  ⟧ '/  ' ( δ ) ']'") : nola_scope.
End IntpNotation.
Import IntpNotation.

(** Conversion between candidates [δ], [δ'] *)
Definition dtrans {JUDG PROP} (δ δ' : deriv_ty JUDG PROP) : PROP :=
  ∀ J, ⸨ J ⸩(δ) -∗ ⸨ J ⸩(δ').
#[export] Instance dtrans_ne {JUDG PROP} : NonExpansive2 (@dtrans JUDG PROP).
Proof.
  unfold dtrans=> ??? seq ?? δ'eq. do 3 f_equiv; [apply seq|apply δ'eq].
Qed.

(** Soundness of a candidate [δ] with respect the semantics by [δ'] *)
Definition dsound {PROP} {DER : derivst PROP} (δ δ' : deriv_ty DER PROP)
  : PROP := ∀ J, ⸨ J ⸩(δ) -∗ ⟦ J ⟧(δ').

(** ** [Deriv] : Derivability candidate *)

Inductive Deriv {PROP} {DER : derivst PROP}
  (ih : deriv_ty DER PROP → Prop) (δ : deriv_ty DER PROP) : Prop := {
  (** For [Deriv_intp] *)
  Deriv_byintp' :
    (* Parameterization by [Deriv'] is for strict positivity *)
    ∃ Deriv' : _ → Prop, (∀ δ', Deriv' δ' → Deriv ih δ') ∧ ∀ J,
      (∀ δ', ⌜Deriv' δ'⌝ → ⌜ih δ'⌝ →
        □ dsound δ δ' -∗ □ dtrans δ δ' -∗ ⟦ J ⟧(δ')) -∗ ⸨ J ⸩(δ)
}.
Existing Class Deriv.

(** Get the candidate [⸨ J ⸩(δ)] by the interpretaion *)
Lemma Deriv_byintp `{!@Deriv PROP DER ih δ} {J} :
  (∀ δ', (* Take any candidate [δ'] *) ⌜Deriv ih δ'⌝ →
    (* Get access to the inductive hypothesis *) ⌜ih δ'⌝ →
    (* Turn the base candidate into the sematics by the given candidate *)
      □ dsound δ δ' -∗
    (* Turn the base candidate into the given candidate *) □ dtrans δ δ' -∗
    (* The semantics by the given candidate *) ⟦ J ⟧(δ'))
  -∗ (* The base candidate *) ⸨ J ⸩(δ).
Proof.
  have X := (@Deriv_byintp' _ _ ih δ). move: X=> [dy[dyto byintp]]. iIntros "→".
  iApply byintp. iIntros (δ' dyd'). apply dyto in dyd'. by iApply "→".
Qed.

(** [Deriv] is monotone over the inductive hypothesis *)
Lemma Deriv_mono `{D : !@Deriv PROP DER ih δ} (ih' : _ → Prop) :
  (∀ δ', ih δ' → ih' δ') → Deriv ih' δ.
Proof.
  move=> ihto. move: δ D. fix FIX 2=> δ [[dy[dyto byintp]]]. split.
  exists (Deriv ih'). split; [done|]=>/= ?. iIntros "big". iApply byintp.
  iIntros (???). iApply "big"; iPureIntro; by [apply FIX, dyto|apply ihto].
Qed.

(** [Deriv] can accumulate the inductive hypothesis *)
Lemma Deriv_acc {PROP DER ih} res :
  (∀ δ, @Deriv PROP DER (res ∧₁ ih) δ → res δ) → ∀ δ, Deriv ih δ → res δ.
Proof.
  move=> to δ dyd. apply to. move: δ dyd. fix FIX 2=> δ [[dy[dyto byintp]]].
  split. exists (Deriv (res ∧₁ ih)). split; [done|]=>/= ?. iIntros "big".
  iApply byintp. iIntros (? dyd' ?). move: dyd'=>/dyto/FIX ?.
  iApply "big"; iPureIntro; [done|]. split; by [apply to|].
Qed.

(** Introduce a candidate *)
Lemma Deriv_intro `{!@Deriv PROP DER ih δ} {J} :
  (∀ δ', ⌜Deriv ih δ'⌝ → ⌜ih δ'⌝ → ⟦ J ⟧(δ')) -∗ ⸨ J ⸩(δ).
Proof.
  iIntros "∀". iApply Deriv_byintp. iIntros (???) "_ _". by iApply "∀".
Qed.

(** Update candidates *)
Lemma Deriv_map `{!@Deriv PROP DER ih δ} {J J'} :
  (∀ δ', ⌜Deriv ih δ'⌝ → ⌜ih δ'⌝ → ⟦ J ⟧(δ') -∗ ⟦ J' ⟧(δ')) -∗
  ⸨ J ⸩(δ) -∗ ⸨ J' ⸩(δ).
Proof.
  iIntros "∀ J". iApply Deriv_byintp. iIntros (???) "#→ _".
  iApply "∀"; by [| |iApply "→"].
Qed.
Lemma Deriv_map2 `{!@Deriv PROP DER ih δ} {J J' J''} :
  (∀ δ', ⌜Deriv ih δ'⌝ → ⌜ih δ'⌝ → ⟦ J ⟧(δ') -∗ ⟦ J' ⟧(δ') -∗
    ⟦ J'' ⟧(δ')) -∗
  ⸨ J ⸩(δ) -∗ ⸨ J' ⸩(δ) -∗ ⸨ J'' ⸩(δ).
Proof.
  iIntros "∀ J J'". iApply Deriv_byintp. iIntros (???) "#→ _".
  iApply ("∀" with "[//] [//] [J]"); by iApply "→".
Qed.
Lemma Deriv_map3 `{!@Deriv PROP DER ih δ} {J J' J'' J'''} :
  (∀ δ', ⌜Deriv ih δ'⌝ → ⌜ih δ'⌝ → ⟦ J ⟧(δ') -∗ ⟦ J' ⟧(δ') -∗
    ⟦ J'' ⟧(δ') -∗ ⟦ J''' ⟧(δ')) -∗
  ⸨ J ⸩(δ) -∗ ⸨ J' ⸩(δ) -∗ ⸨ J'' ⸩(δ) -∗ ⸨ J''' ⸩(δ).
Proof.
  iIntros "∀ J J' J''". iApply Deriv_byintp. iIntros (???) "#→ _".
  iApply ("∀" with "[//] [//] [J] [J']"); by iApply "→".
Qed.
Lemma Deriv_mapl `{!@Deriv PROP DER ih δ} {Js J'} :
  (∀ δ', ⌜Deriv ih δ'⌝ → ⌜ih δ'⌝ →
    ([∗ list] J ∈ Js, ⟦ J ⟧(δ')) -∗ ⟦ J' ⟧(δ')) -∗
  ([∗ list] J ∈ Js, ⸨ J ⸩(δ)) -∗ ⸨ J' ⸩(δ).
Proof.
  iIntros "∀ Js". iApply Deriv_byintp. iIntros (???) "#→ _".
  iApply "∀"; [done..|]. iInduction Js as [|J Js] "IH"=>/=; [done|].
  iDestruct "Js" as "[J Js]". iSplitL "J"; by [iApply "→"|iApply "IH"].
Qed.

(** ** [der]: Derivability *)

(** [der_gen]: What becomes [der] by taking [bi_least_fixpoint] *)
Definition der_gen {PROP} {DER : derivst PROP} (self : DER → PROP)
  : DER → PROP := λ J,
  (∀ δ, ⌜@Deriv PROP DER True₁ δ⌝ → □ dsound (Dwrap self) δ -∗
    □ dtrans (Dwrap self) δ -∗ ⟦ J ⟧(δ))%I.
#[export] Instance der_gen_mono {PROP DER} :
  BiMonoPred (A:=leibnizO _) (@der_gen PROP DER).
Proof.
  split; [|solve_proper]=> Φ Ψ ??. iIntros "#ΦΨ" (?) "big".
  iIntros (??) "#Ψδ #Ψδ'".
  iApply "big"; [done|..]; iIntros "!> % ?"; [iApply "Ψδ"|iApply "Ψδ'"];
    by iApply "ΦΨ".
Qed.

(** [der]: Derivability *)
Definition der_def {PROP} {DER : derivst PROP} : deriv_ty DER PROP :=
  Dwrap (bi_least_fixpoint (A:=leibnizO _) (@der_gen PROP DER)).
Lemma der_aux : seal (@der_def). Proof. by eexists. Qed.
Definition der {PROP DER} := der_aux.(unseal) PROP DER.
Lemma der_unseal : @der = @der_def. Proof. exact: seal_eq. Qed.

(** Notation for [dwrap] *)
Module DerivNotation.
  Export DerivNotation'.
  Notation "⸨ J ⸩" := ⸨ J ⸩(der) (format "⸨  J  ⸩") : nola_scope.
End DerivNotation.

(** [der] satisfies [Deriv] *)
#[export] Instance der_Deriv {PROP DER} : @Deriv PROP DER True₁ der.
Proof.
  rewrite der_unseal. split. eexists _. split; [done|]=>/=. iIntros (?) "big".
  rewrite least_fixpoint_unfold. iIntros (??) "#→δ #→δ'".
  iApply "big"; [done..| |]; iIntros "!> % ?/="; by [iApply "→δ"|iApply "→δ'"].
Qed.

(** [der] is sound w.r.t. the interpretation under [der] *)
Lemma der_sound {PROP DER} : ⊢ @dsound PROP DER der der.
Proof.
  rewrite der_unseal. iApply (least_fixpoint_ind (A:=leibnizO _)).
  iIntros "!> % gen". rewrite -der_unseal.
  iApply ("gen" $! _ der_Deriv); iIntros "!> % /="; rewrite der_unseal.
  { iIntros "[$ _]". } { iIntros "[_ $]". }
Qed.

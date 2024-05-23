(** * Showcase logic *)

From nola.iris Require Import ciprop inv_deriv.
From nola.heap_lang Require Import notation proofmode.
Import WpwNotation iPropAppNotation PintpNotation.

Implicit Type (N : namespace) (l : loc).

(** ** [sel]: Selector *)
Variant sel :=
| (** Invariant *) cips_inv (N : namespace).

(** ** [idom]: Domain for inductive parts *)
Definition idom (_ : sel) : Type := Empty_set.

(** ** [cdom]: Domain for coinductive parts *)
Definition cdom (s : sel) : Type := match s with
  | cips_inv _ => unit
  end.

(** ** [dataOF]: Data [oFunctor] *)
Definition dataOF (s : sel) : oFunctor := match s with
  | cips_inv _ => unitO
  end.

(** [dataOF] is contractive *)
#[export] Instance dataOF_contractive {s} : oFunctorContractive (dataOF s).
Proof. by case s. Qed.

(** ** [ciProp]: Proposition *)
Notation ciProp Σ := (ciProp idom cdom dataOF Σ).
Notation ciPropOF := (ciPropOF idom cdom dataOF).

(** [ciPropOF] is contractive *)
Fact ciPropOF_contractive : oFunctorContractive ciPropOF.
Proof. exact _. Qed.

(** ** Construct [ciProp] *)
Section ciProp.
  Context {Σ : gFunctors}.
  Definition cip_inv N (Px : ciProp Σ) : ciProp Σ :=
    cip_custom (cips_inv N) nullary (unary Px) ().

  #[export] Instance cip_inv_ne {N} : NonExpansive (cip_inv N).
  Proof. move=> ????. apply cip_custom_ne; solve_proper. Qed.
End ciProp.

(** ** [judg]: Judgment *)
Definition judg Σ : ofe := prodO (leibnizO namespace) (ciProp Σ).
Definition inv_jacsr {Σ} N P : judg Σ := (N, P).
#[export] Instance inv_jacsr_ne {Σ N} : NonExpansive (@inv_jacsr Σ N).
Proof. done. Qed.

#[export] Instance judg_inv_pre_deriv {Σ} :
  InvPreDeriv (ciProp Σ) (judg Σ) := INV_PRE_DERIV inv_jacsr.

Section iris.
  Context `{!inv'GS ciPropOF Σ}.
  Implicit Type δ : judg Σ → iProp Σ.

  (** ** [bintp]: Base interpretation *)
  Definition bintp δ s : (idom s -d> iProp Σ) → (cdom s -d> ciProp Σ) →
    dataOF s $oi Σ → iProp Σ :=
    match s with
    | cips_inv N => λ _ Pxs _, inv' δ N (Pxs ())
    end.

  (** [bintp] is non-expansive *)
  #[export] Instance bintp_ne `{!NonExpansive δ} {s} :
    NonExpansive3 (bintp δ s).
  Proof. case s; solve_proper. Qed.

  (** ** Parameterized interpretation of [ciProp] *)
  #[export] Instance ciProp_dintp : Dintp (judg Σ) (ciProp Σ) (iProp Σ) :=
    DINTP (λ δ, cip_intp (bintp δ)).

  (** [ciProp_intp] is non-expansive *)
  Fact ciProp_intp_ne `{!NonExpansive δ} : NonExpansive ⟦⟧(δ)@{ciProp Σ}.
  Proof. exact _. Qed.

  Context `{!invGS_gen hlc Σ}.

  (** ** [jintp]: Judgment interpretation *)
  Definition jintp δ (J : judg Σ) := match J with
    | (N, Px) => inv_acsr ⟦⟧(δ) N ⟦ Px ⟧(δ)
    end.
  Local Instance jintp_ne `{!NonExpansive δ} : NonExpansive (jintp δ).
  Proof. move=> ?[??][??][/=??]. solve_proper. Qed.
  Canonical judgJ : judgi (iProp Σ) := Judgi _ jintp.

  #[export] Instance judg_inv_deriv : InvDeriv ciPropOF Σ judgJ.
  Proof. done. Qed.
End iris.

(** ** Target function: Linked list mutation *)
Definition iter : val := rec: "self" "f" "c" "l" :=
  if: !"c" = #0 then #() else
    "f" "l";; "c" <- !"c" - #1;; "self" "f" "c" (!("l" +ₗ #1)).

Section iris.
  Context `{!inv'GS ciPropOF Σ, !heapGS_gen hlc Σ}.

  Section ilist.
    Context N (Φ : loc → ciProp Σ).

    (** [ilist]: Syntactic proposition for a list *)
    Definition ilist_gen Ilist' l : ciProp Σ :=
      cip_inv N (Φ l) ∗ cip_inv N (Ilist' l).
    Definition ilist'_gen Ilist' l : ciProp Σ :=
      ∃ l', ▷ (l +ₗ 1) ↦ #l' ∗ ilist_gen Ilist' l'.
    CoFixpoint ilist' : loc → ciProp Σ := ilist'_gen ilist'.
    Definition ilist : loc → ciProp Σ := ilist_gen ilist'.
  End ilist.

  (** ** Termination of [iter] *)
  Lemma twp_iter {N Φ c l} {f : val} {n : nat} :
    (∀ l0 : loc,
      [[{ inv' der N (Φ l0) }]][inv_wsatd der]
        f #l0 @ ↑N
      [[{ RET #(); True }]]) -∗
    [[{ c ↦ #n ∗ ⟦ ilist N Φ l ⟧(der) }]][inv_wsatd der]
      iter f #c #l @ ↑N
    [[{ RET #(); c ↦ #0 }]].
  Proof.
    iIntros "#Hf". iIntros (Ψ) "!> [c↦ #[ihd itl]]/= HΨ".
    iInduction n as [|m] "IH" forall (l) "ihd itl".
    { wp_rec. wp_pures. wp_load. wp_pures. by iApply "HΨ". }
    wp_rec. wp_pures. wp_load. wp_pures. wp_apply "Hf"; [done|]. iIntros "_".
    wp_pures. wp_load. wp_op. have -> : (S m - 1)%Z = m by lia. wp_store.
    wp_op. wp_bind (! _)%E.
    iMod (inv'_acc with "itl") as "/=[(%l' & >↦l' & #itlhd & #itltl) cl]/=";
      [done|].
    wp_load. iModIntro. iMod ("cl" with "[↦l']") as "_".
    { iExists _. iFrame "↦l'". by iSplit. }
    iModIntro. by iApply ("IH" with "c↦ HΨ").
  Qed.
End iris.

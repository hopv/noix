(** * Derivability *)

From nola.examples.logic Require Export eval.
From nola Require Export util.wft judg.
From iris.base_logic.lib Require Import iprop.

Implicit Type (d : nderiv_ty) (δ : npderiv_ty) (i j : nat).

(** ** [nJudg]: Judgment *)
Definition nJudgTy i : Type := nPropL (;) * nPropL (;).
Canonical nJudg Σ `{!nevalG Σ} := Judg nat nJudgTy
  (λ d _ '(P, Q), neval' Σ d _ P ⊢ neval d Q).

(** ** [nderivy], [ninderivy], [nderiv]: Derivability *)
Class nderivy Σ `{!nevalG Σ} δ := Nderivy {
  nderivy_derivy :: derivy (nJudg Σ) δ;
}.
#[export] Instance derivy_nderivy `{!nevalG Σ, !derivy (nJudg Σ) δ} :
  nderivy Σ δ.
Proof. split. apply _. Qed.
Class ninderivy Σ `{!nevalG Σ} δ δ' d i := Ninderivy {
  ninderivy_inderivy :: inderivy (nJudg Σ) δ δ' d i;
}.

Definition nderiv Σ `{!nevalG Σ} := deriv (nJudg Σ).

(** Operations on [nderiv_ty] *)
Definition Falseⁿᵈ : nderiv_ty := λ _ _, False.
Notation "⊥ⁿᵈ" := Falseⁿᵈ : nola_scope.
Definition orⁿᵈ d d' : nderiv_ty := λ i PQ, d i PQ ∨ d' i PQ.
Infix "∨ⁿᵈ" := orⁿᵈ (at level 50, left associativity) : nola_scope.
Definition apporⁿᵈ δ d : nderiv_ty := δ d ∨ⁿᵈ d.
Infix "$∨ⁿᵈ" := apporⁿᵈ (at level 50, left associativity) : nola_scope.
Definition implⁿᵈ d d' : Prop := ∀ i PQ, d i PQ → d' i PQ.
Infix "→ⁿᵈ" := implⁿᵈ (at level 99, right associativity) : nola_scope.

(** ** Basic laws for [nderivy] *)
Section basic.
  Context `{!nevalG Σ, !nderivy Σ δ}.

  (** [δ] is monotone over the coinductive hypothesis *)
  Lemma n_mono {d d'} : (d →ⁿᵈ d') → δ d →ⁿᵈ δ d'.
  Proof. apply (derivy_mono (JU:=nJudg Σ)). Qed.

  (** [δ] can accumulate the coinductive hypothesis *)
  Lemma n_acc {d} res : (res →ⁿᵈ δ (d ∨ⁿᵈ res)) → res →ⁿᵈ δ d.
  Proof. apply (derivy_acc (JU:=nJudg Σ)). Qed.

  (** [δ] can be proved by its semantics *)
  Lemma n_bysem {d i P Q} :
    (∀ δ' : npderiv_ty,
      ninderivy Σ δ' δ d i → neval (δ' ⊥ⁿᵈ) P ⊢ neval' Σ (δ' ⊥ⁿᵈ) _ Q) →
    δ d i (P, Q).
  Proof. move=> H. apply (derivy_bysem (JU:=nJudg Σ))=> ??. by apply H. Qed.

  (** We can get [⊢] out of [δ] under [ninderivy Σ δ' δ] *)
  Lemma nin_sem {δ' : npderiv_ty} `{!ninderivy Σ δ' δ d i} {P Q} :
    δ d i (P, Q) → neval (δ' ⊥ⁿᵈ) P ⊢ neval' Σ (δ' ⊥ⁿᵈ) _ Q.
  Proof. apply (inderivy_sem (JU:=nJudg Σ) (P, Q)). Qed.

  (** We can turn [δ $∨ⁿᵈ d] into [δ' ⊥ⁿᵈ] under [ninderivy] *)
  Lemma nin_turn `{!ninderivy Σ δ' δ d i} : (δ $∨ⁿᵈ d) →ⁿᵈ δ' ⊥ⁿᵈ.
  Proof. apply (inderivy_turn (JU:=nJudg Σ)). Qed.

  (** We can get [⊢] out of [δ' j] for [j < i] under [ninderivy Σ δ' δ d i] *)
  Lemma nin_semlow `{!ninderivy Σ δ' δ d i} {j P Q} :
    j < i → δ' ⊥ⁿᵈ j (P, Q) → neval (δ' ⊥ⁿᵈ) P ⊢ neval' Σ (δ' ⊥ⁿᵈ) _ Q.
  Proof. move=> ji H. apply (inderivy_semlow (JU:=nJudg Σ) j ji (P, Q) H). Qed.

  (** Utility lemmas *)
  Lemma nin_turn_l `{!ninderivy Σ δ' δ d i} : δ d →ⁿᵈ δ' ⊥ⁿᵈ.
  Proof. apply (inderivy_turn_l (JU:=nJudg Σ)). Qed.
  Lemma nin_turn_r `{!ninderivy Σ δ' δ d i} : d →ⁿᵈ δ' ⊥ⁿᵈ.
  Proof. apply (inderivy_turn_r (JU:=nJudg Σ)). Qed.
  Lemma nin_turn_semlow `{!ninderivy Σ δ' δ d i} {j P Q} :
    j < i → (δ $∨ⁿᵈ d) j (P, Q) → neval (δ' ⊥ⁿᵈ) P ⊢ neval' Σ (δ' ⊥ⁿᵈ) _ Q.
  Proof. move=> ji ?. by apply (nin_semlow ji), nin_turn. Qed.
  Lemma nin_turn_semlow_l `{!ninderivy Σ δ' δ d i} {j P Q} :
    j < i → δ d j (P, Q) → neval (δ' ⊥ⁿᵈ) P ⊢ neval' Σ (δ' ⊥ⁿᵈ) _ Q.
  Proof. move=> ji ?. by apply (nin_semlow ji), nin_turn_l. Qed.
  Lemma nin_turn_semlow_r `{!ninderivy Σ δ' δ d i} {j P Q} :
    j < i → d j (P, Q) → neval (δ' ⊥ⁿᵈ) P ⊢ neval' Σ (δ' ⊥ⁿᵈ) _ Q.
  Proof. move=> ji ?. by apply (nin_semlow ji), nin_turn_r. Qed.

  (** [δ] is monotone over the index *)
  Lemma n_up {i j d P Q} : i ≤ j → δ d i (P, Q) → δ d j (P, Q).
  Proof.
    move=> /Nat.lt_eq_cases [|<-]; [|done]=> ? H. apply n_bysem=> ??.
    by apply nin_turn_semlow_l in H.
  Qed.
End basic.

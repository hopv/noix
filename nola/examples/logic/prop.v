(** * [nProp]: Syntactic proposition *)

From nola.examples.logic Require Export ctx.
From nola Require Export util.funext util.rel.
From stdpp Require Export coPset.
From iris.bi Require Import notation.
Import EqNotations.

(** ** [nProp]: Nola syntactic proposition

  Its universe level is strictly higher than those of [V : npvar]
  and the domain [A : Type] of [n_forall]/[n_exist].

  Connectives that operate on the context [Γ : nctx] take decomposed contexts
  [Γᵘ, Γᵍ] for smooth type inference

  In nominal proposition arguments (e.g., [n_deriv]'s arguments), unguarded
  variables are flushed into guarded, with the context [(; Γᵘ ++ Γᵍ)];
  for connectives with such arguments we make [Γᵘ] explicit for the users
  to aid type inference around [++] *)

Inductive nProp : nsort → nctx → Type :=

(** Pure proposition *)
| n_pure {σ Γ} : Prop → nProp σ Γ
(** Conjunction *)
| n_and {σ Γ} : nProp σ Γ → nProp σ Γ → nProp σ Γ
(** Disjunction *)
| n_or {σ Γ} : nProp σ Γ → nProp σ Γ → nProp σ Γ
(** Implication *)
| n_impl {σ Γ} : nProp σ Γ → nProp σ Γ → nProp σ Γ
(** Universal quantification *)
| n_forall {σ Γ} {A : Type} : (A → nProp σ Γ) → nProp σ Γ
(** Existential quantification *)
| n_exist {σ Γ} {A : Type} : (A → nProp σ Γ) → nProp σ Γ

(** Separating conjunction *)
| n_sep {σ Γ} : nProp σ Γ → nProp σ Γ → nProp σ Γ
(** Magic wand *)
| n_wand {σ Γ} : nProp σ Γ → nProp σ Γ → nProp σ Γ
(** Persistence modality *)
| n_persistently {σ Γ} : nProp σ Γ → nProp σ Γ
(** Plainly modality *)
| n_plainly {σ Γ} : nProp σ Γ → nProp σ Γ
(** Basic update modality *)
| n_bupd {σ Γ} : nProp σ Γ → nProp σ Γ
(** Fancy update modality *)
| n_fupd {σ Γ} : coPset → coPset → nProp σ Γ → nProp σ Γ

(** Later modality *)
| n_later {σ} Γᵘ {Γᵍ} : nProp nL (; Γᵘ ++ Γᵍ) → nProp σ (Γᵘ; Γᵍ)
(** Judgment derivability *)
| n_deriv {σ} Γᵘ {Γᵍ} :
    nat → nProp nL (; Γᵘ ++ Γᵍ) → nProp nL (; Γᵘ ++ Γᵍ) → nProp σ (Γᵘ; Γᵍ)

(** Recursive small proposition *)
| n_recs {σ Γᵘ Γᵍ} {A : Type} :
    (A → nProp nS (A →nPS :: Γᵘ; Γᵍ)) → A → nProp σ (Γᵘ; Γᵍ)
(** Recursive large proposition *)
| n_recl {Γᵘ Γᵍ} {A : Type} :
    (A → nProp nL (A →nPL :: Γᵘ; Γᵍ)) → A → nProp nL (Γᵘ; Γᵍ)
(** Universal quantification over [A → nProp] *)
| n_n_forall {σ Γᵘ Γᵍ} V : nProp σ (V :: Γᵘ; Γᵍ) → nProp σ (Γᵘ; Γᵍ)
(** Existential quantification over [A → nProp] *)
| n_n_exist {σ Γᵘ Γᵍ} V : nProp σ (V :: Γᵘ; Γᵍ) → nProp σ (Γᵘ; Γᵍ)

(** Guarded small variable *)
| n_vargs {σ Γᵘ Γᵍ} : schoice npargS Γᵍ → nProp σ (Γᵘ; Γᵍ)
(** Guarded large variable, [nPropL] only *)
| n_vargl {Γᵘ Γᵍ} : schoice npargL Γᵍ → nProp nL (Γᵘ; Γᵍ)
(** Unguarded small variable, [nPropL] only *)
| n_varus {Γᵘ Γᵍ} : schoice npargS Γᵘ → nProp nL (Γᵘ; Γᵍ)
(** Substituted [n_varus] *)
| n_subus {Γᵘ Γᵍ} : nProp nS (;) → nProp nL (Γᵘ; Γᵍ).

Notation nPropS := (nProp nS).
Notation nPropL := (nProp nL).

(** ** Notations for [nProp] connectives *)

Declare Scope nProp_scope.
Delimit Scope nProp_scope with n.
Bind Scope nProp_scope with nProp.

Notation "'⌜' φ '⌝'" := (n_pure φ%type%stdpp%nola) : nProp_scope.
Notation "'True'" := (n_pure True) : nProp_scope.
Notation "'False'" := (n_pure False) : nProp_scope.
Infix "∧" := n_and : nProp_scope.
Notation "(∧)" := n_and (only parsing) : nProp_scope.
Infix "∨" := n_or : nProp_scope.
Notation "(∨)" := n_or (only parsing) : nProp_scope.
Infix "→" := n_impl : nProp_scope.
Notation "¬ P" := (n_impl P (n_pure False)) : nProp_scope.
Notation "∀' Φ" := (n_forall Φ)
  (at level 200, right associativity, only parsing) : nProp_scope.
Notation "∀ x .. z , P" :=
  (n_forall (λ x, .. (n_forall (λ z, P%n)) ..)) : nProp_scope.
Notation "∃' Φ" := (n_exist Φ)
  (at level 200, right associativity, only parsing) : nProp_scope.
Notation "∃ x .. z , P" :=
  (n_exist (λ x, .. (n_exist (λ z, P%n)) ..)) : nProp_scope.

Infix "∗" := n_sep : nProp_scope.
Notation "(∗)" := n_sep (only parsing) : nProp_scope.
Infix "-∗" := n_wand : nProp_scope.
Notation "□ P" := (n_persistently P) : nProp_scope.
Notation "■ P" := (n_plainly P) : nProp_scope.
Notation "|==> P" := (n_bupd P) : nProp_scope.
Notation "|={ E , E' }=> P" := (n_fupd E E' P) : nProp_scope.

Notation "▷{ Γᵘ } P" := (n_later Γᵘ P)
  (at level 20, right associativity, only parsing) : nProp_scope.
Notation "▷ P" := (n_later _ P) : nProp_scope.
Definition n_except_0 {σ Γᵘ Γᵍ} (P : nProp σ (Γᵘ; Γᵍ)) : nProp σ (Γᵘ; Γᵍ)
  := ▷ False ∨ P.
Notation "◇ P" := (n_except_0 P) : nProp_scope.
Notation "P ⊢!{ i }{ Γᵘ } Q" := (n_deriv Γᵘ i P Q)
  (at level 99, Q at level 200, only parsing) : nProp_scope.
Notation "P ⊢!{ i } Q" := (n_deriv _ i P Q)
  (at level 99, Q at level 200, format "P  ⊢!{ i }  Q") : nProp_scope.

Notation "rec:ˢ' Φ" := (n_recs Φ)
  (at level 200, right associativity, only parsing) : nProp_scope.
Notation "rec:ˢ x , P" := (n_recs (λ x, P))
  (at level 200, right associativity,
    format "'[' '[' rec:ˢ  x ,  '/' P ']' ']'") : nProp_scope.
Notation "rec:ˡ' Φ" := (n_recl Φ)
  (at level 200, right associativity, only parsing) : nProp_scope.
Notation "rec:ˡ x , P" := (n_recl (λ x, P))
  (at level 200, right associativity,
    format "'[' '[' rec:ˡ  x ,  '/' P ']' ']'") : nProp_scope.
Notation "∀: V , P" := (n_n_forall V P)
  (at level 200, right associativity,
    format "'[' '[' ∀:  V ']' ,  '/' P ']'") : nProp_scope.
Notation "∃: V , P" := (n_n_exist V P)
  (at level 200, right associativity,
    format "'[' '[' ∃:  V ']' ,  '/' P ']'") : nProp_scope.

Notation "%ᵍˢ s" := (n_vargs s) (at level 20, right associativity)
  : nProp_scope.
Notation "%ᵍˡ s" := (n_vargl s) (at level 20, right associativity)
  : nProp_scope.
Notation "%ᵘˢ s" := (n_varus s) (at level 20, right associativity)
  : nProp_scope.
Notation "!ᵘˢ P" := (n_subus P) (at level 20, right associativity)
  : nProp_scope.

(** ** [nlarge]: Turn [nProp σ Γ] into [nPropL Γ]
  Although the main interest is the case [σ = nS],
  we keep the function polymorphic over [σ] for ease of definition *)
Fixpoint nlarge {σ Γ} (P : nProp σ Γ) : nPropL Γ :=
  match P with
  | ⌜φ⌝ => ⌜φ⌝
  | P ∧ Q => nlarge P ∧ nlarge Q
  | P ∨ Q => nlarge P ∨ nlarge Q
  | P → Q => nlarge P → nlarge Q
  | P ∗ Q => nlarge P ∗ nlarge Q
  | P -∗ Q => nlarge P -∗ nlarge Q
  | ∀' Φ => ∀' nlarge ∘ Φ
  | ∃' Φ => ∃' nlarge ∘ Φ
  | □ P => □ nlarge P
  | ■ P => ■ nlarge P
  | |==> P => |==> nlarge P
  | |={E,E'}=> P => |={E,E'}=> nlarge P
  | ▷ P => ▷ P
  | P ⊢!{i} Q => P ⊢!{i} Q
  | (rec:ˢ' Φ) a => (rec:ˢ' Φ) a
  | (rec:ˡ' Φ) a => (rec:ˡ' Φ) a
  | ∀: V, P => ∀: V, nlarge P
  | ∃: V, P => ∃: V, nlarge P
  | %ᵍˢ s => %ᵍˢ s
  | %ᵍˡ s => %ᵍˡ s
  | %ᵘˢ s => %ᵘˢ s
  | !ᵘˢ P => !ᵘˢ P
  end%n.

(** [nunsmall]: Turn [nPropS Γ] into [nProp σ Γ] *)
Definition nunsmall {σ Γ} (P : nPropS Γ) : nProp σ Γ :=
  match σ with nS => P | nL => nlarge P end.

(** [nlarge] is identity for [nPropL] *)
Lemma nlarge_id' {σ Γ} {P : nProp σ Γ} (eq : σ = nL) :
  nlarge P = rew[λ σ, nProp σ Γ] eq in P.
Proof.
  move: σ Γ P eq. fix FIX 3=> σ Γ.
  case=>/=; intros; subst=>//=; f_equal; try exact (FIX _ _ _ eq_refl);
  try (funext=> ?; exact (FIX _ _ _ eq_refl)); by rewrite (eq_dec_refl eq).
Qed.
Lemma nlarge_id {Γ} {P : nPropL Γ} : nlarge P = P.
Proof. exact (nlarge_id' eq_refl). Qed.

(** [nlarge] over [nunsmall] *)
Lemma nlarge_nunsmall {Γ σ} {P : nPropS Γ} :
  nlarge (σ:=σ) (nunsmall P) = nlarge P.
Proof. case σ=>//=. exact nlarge_id. Qed.

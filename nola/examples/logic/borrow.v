(** * On the borrowing *)

From nola.examples.logic Require Export deriv.

(** ** On [conv] *)
Section conv.
  Context `{!nintpGS Σ}.

  (** Use [convd] *)
  Lemma convd_use {P Q} : convd P Q ⊢ ⟦ P ⟧ -∗ ⟦ Q ⟧.
  Proof.
    iIntros "c". iDestruct nderiv_sound as "→". iApply ("→" with "c").
  Qed.

  Context `{!nDeriv ih δ}.

  (** Introduce [conv] *)
  Lemma conv_intro P Q : (∀ δ', ⟦ P ⟧(δ') -∗ ⟦ Q ⟧(δ')) ⊢ conv δ P Q.
  Proof.
    iIntros "→". iApply (Deriv_intro (δ:=δ))=>/=. iIntros. by iApply "→".
  Qed.
  Lemma conv_refl P : ⊢ conv δ P P.
  Proof. rewrite -conv_intro. by iIntros "% ?". Qed.

  (** Modify [conv] *)
  Lemma conv_trans P Q R : conv δ P Q -∗ conv δ Q R -∗ conv δ P R.
  Proof.
    iIntros "PQ QR". iApply (Deriv_map2 (δ:=δ) with "[] PQ QR")=>/=.
    iIntros "% _ _ PQ QR P". iDestruct ("PQ" with "P") as "Q". by iApply "QR".
  Qed.
End conv.

(** ** On borrowing *)

Section borrow.
  Context `{!nintpGS Σ, !nDeriv ih δ}.

  (** Modify tokens with [conv] *)
  Lemma borc_conv {α P Q} :
    □ conv δ P Q -∗ □ conv δ Q P -∗ borc δ α P -∗ borc δ α Q.
  Proof.
    iIntros "#? #? [%[#?[#? c]]]". iExists _. iFrame "c".
    iSplit; iModIntro; by iApply conv_trans.
  Qed.
  Lemma bor_conv {α P Q} :
    □ conv δ P Q -∗ □ conv δ Q P -∗ bor δ α P -∗ bor δ α Q.
  Proof.
    iIntros "#? #? [%[#?[#? b]]]". iExists _. iFrame "b".
    iSplit; iModIntro; by iApply conv_trans.
  Qed.
  Lemma obor_conv {α q P Q} :
    □ conv δ P Q -∗ □ conv δ Q P -∗ obor δ α q P -∗ obor δ α q Q.
  Proof.
    iIntros "#? #? [%[#?[#? o]]]". iExists _. iFrame "o".
    iSplit; iModIntro; by iApply conv_trans.
  Qed.
  Lemma lend_conv {α P Q} : □ conv δ P Q -∗ lend δ α P -∗ lend δ α Q.
  Proof.
    iIntros "#? [%[#? l]]". iExists _. iFrame "l". iModIntro.
    by iApply conv_trans.
  Qed.
  Lemma fbor_conv {α Φ Ψ} :
    □ (∀ q, conv δ (Φ q) (Ψ q)) -∗ □ (∀ q, conv δ (Ψ q) (Φ q)) -∗
    fbor δ α Φ -∗ fbor δ α Ψ.
  Proof. iIntros "_ _ []". Qed.

  (** Modify tokens with lifetime inclusion *)
  Lemma borc_lft {α α' P} : α' ⊑□ α -∗ borc δ α P -∗ borc δ α' P.
  Proof.
    iIntros "⊑ [%[?[? c]]]". iDestruct (bor_ctok_lft with "⊑ c") as "c".
    iExists _. iFrame.
  Qed.
  Lemma bor_lft {α α' P} : α' ⊑□ α -∗ bor δ α P -∗ bor δ α' P.
  Proof.
    iIntros "⊑ [%[?[? b]]]". iDestruct (bor_tok_lft with "⊑ b") as "b".
    iExists _. iFrame.
  Qed.
  Lemma bor_olft {α α' q r P} :
    α' ⊑□ α -∗ (q.[α] -∗ r.[α']) -∗ obor δ α q P -∗ obor δ α' r P.
  Proof.
    iIntros "⊑ → [%[?[? o]]]". iDestruct (obor_tok_lft with "⊑ → o") as "o".
    iExists _. iFrame.
  Qed.
  Lemma lend_lft {α α' P} : α ⊑□ α' -∗ lend δ α P -∗ lend δ α' P.
  Proof.
    iIntros "⊑ [%[? l]]". iDestruct (lend_tok_lft with "⊑ l") as "l".
    iExists _. iFrame.
  Qed.
  Lemma fbor_lft {α α' Φ} : α' ⊑□ α -∗ fbor δ α Φ -∗ fbor δ α' Φ.
  Proof. iIntros "_ []". Qed.

  (** Other conversion *)
  Lemma borc_bor {α P} : borc δ α P ⊢ bor δ α P.
  Proof. iIntros "[% c]". rewrite bor_ctok_tok. by iExists _. Qed.
  Lemma borc_fake {α} (P : nPropS (;ᵞ)) : [†α] ⊢ borc δ α (↑ˡ P).
  Proof.
    iIntros "†". iExists _. rewrite bor_ctok_fake. iFrame "†".
    iSplitR; iModIntro; iApply conv_refl.
  Qed.
  Lemma bor_fake {α} (P : nPropS (;ᵞ)) : [†α] ⊢ bor δ α (↑ˡ P).
  Proof. by rewrite borc_fake borc_bor. Qed.
End borrow.

Section borrow.
  Context `{!nintpGS Σ}.

  (** Create borrowers and lenders *)
  Lemma borc_lend_new_list α (Pl Ql : list (nPropS (;ᵞ))) :
    ([∗ list] P ∈ Pl, ⟦ P ⟧) -∗
    ([†α] -∗ ([∗ list] P ∈ Pl, ⟦ P ⟧) =[proph_wsat]=∗ [∗ list] Q ∈ Ql, ⟦ Q ⟧)
    =[borrow_wsatd]=∗
      ([∗ list] P ∈ Pl, borcd α (↑ˡ P)) ∗ [∗ list] Q ∈ Ql, lendd α (↑ˡ Q).
  Proof.
    iIntros "Pl →Ql". setoid_rewrite <-nintpS_nintp.
    iMod (bor_lend_tok_new_list with "Pl [→Ql]") as "[bl ll]".
    { iIntros "#† ?". by iApply "→Ql". }
    iModIntro. iSplitL "bl"; iStopProof; do 3 f_equiv; iIntros "?"; iExists _.
    - by do 2 (iSplit; [iModIntro; by iApply conv_refl|]).
    - by iSplit; [iModIntro; by iApply conv_refl|].
  Qed.
  (** Simply create a borrower and a lender *)
  Lemma borc_lend_new α (P : nPropS (;ᵞ)) :
    ⟦ P ⟧ -∗ ([†α] -∗ ⟦ P ⟧ =[proph_wsat]=∗ ⟦ P ⟧) =[borrow_wsatd]=∗
      borcd α (↑ˡ P) ∗ lendd α (↑ˡ P).
  Proof.
    iIntros "P". iMod (borc_lend_new_list α [P] [P] with "[P] []")
      as "[[$_][$_]]"; by [iFrame|iIntros|].
  Qed.

  (** Extend a lender *)
  Lemma lend_split {α P} (Ql : list (nPropS (;ᵞ))) :
    lendd α P -∗
    (⟦ P ⟧ =[proph_wsat]=∗ [∗ list] Q ∈ Ql, ⟦ Q ⟧) =[borrow_wsatd]=∗
      [∗ list] Q ∈ Ql, lendd α (↑ˡ Q).
  Proof.
    iIntros "[%P'[#→P l]] →Ql". rewrite convd_use.
    iMod (lend_tok_split with "l [→P →Ql]") as "ll"=>/=.
    { rewrite nintpS_nintp_nlarge. setoid_rewrite nintpS_nintp. iIntros "P'".
      iDestruct ("→P" with "P'") as "P". by iMod ("→Ql" with "P"). }
    iModIntro. iApply (big_sepL_impl with "ll"). iIntros "!> %% _ l".
    iExists _. iFrame "l". iModIntro. iApply conv_refl.
  Qed.

  (** Retrive from [lend] *)
  Lemma lend_retrieve {α P} :
    [†α] -∗ lendd α P =[proph_wsat ∗ borrow_wsatd]=∗ ⟦ P ⟧.
  Proof.
    iIntros "† [%[#→ l]]". rewrite convd_use -modw_bupdw.
    iMod (lend_tok_retrieve with "† l") as "Q". iModIntro.
    rewrite nintpS_nintp_nlarge. by iApply "→".
  Qed.

  (** Open a closed borrower *)
  Lemma borc_open {q α P} :
    q.[α] -∗ borcd α P =[borrow_wsatd]=∗ obord α q P ∗ ⟦ P ⟧.
  Proof.
    iIntros "α [%Q[PQ[#QP c]]]". iMod (bor_ctok_open with "α c") as "[o Q]".
    iModIntro. rewrite nintpS_nintp_nlarge.
    iDestruct (convd_use with "QP Q") as "$". iExists _. by iFrame.
  Qed.
  (** Open a borrower *)
  Lemma bor_open {q α P} :
    q.[α] -∗ bord α P =[proph_wsat ∗ borrow_wsatd]=∗ obord α q P ∗ ⟦ P ⟧.
  Proof.
    iIntros "α [%Q[PQ[#QP b]]]". rewrite -modw_bupdw.
    iMod (bor_tok_open with "α b") as "[o Q]". iModIntro.
    rewrite nintpS_nintp_nlarge. iDestruct (convd_use with "QP Q") as "$".
    iExists _. by iFrame.
  Qed.

  (** Destruct [obord]s *)
  Local Lemma obor_list {α qPl} :
    ([∗ list] '(q, P)' ∈ qPl, obord α q P) -∗ ∃ qRl, ⌜qRl.*1' = qPl.*1'⌝ ∗
      ([∗ list] '(q, R)' ∈ qRl, obor_tok α q R) ∗
      (([∗ list] P ∈ qPl.*2', ⟦ P ⟧) -∗ [∗ list] R ∈ qRl.*2', ⟦ ↑ˡ R ⟧).
  Proof.
    elim: qPl=>/=.
    { iIntros. iExists []=>/=. do 2 (iSplit; [done|]). by iIntros. }
    iIntros ([q P] qPl IH) "[[%R[#→[_ o]]] qPl]". rewrite convd_use.
    iDestruct (IH with "qPl") as (qRl ?) "[ol →']".
    iExists ((q, R)' :: qRl)=>/=. iFrame "o ol". iSplit.
    { iPureIntro. by f_equal. } iIntros "[P Pl]".
    iDestruct ("→" with "P") as "$". iApply ("→'" with "Pl").
  Qed.
  (** Merge and subdivide borrowers *)
  Lemma obor_merge_subdiv {α} qPl (Ql : list (nPropS (;ᵞ))) :
    ([∗ list] '(q, P)' ∈ qPl, obord α q P) -∗ ([∗ list] Q ∈ Ql, ⟦ Q ⟧) -∗
    ([†α] -∗ ([∗ list] Q ∈ Ql, ⟦ Q ⟧)
      =[proph_wsat]=∗ [∗ list] P ∈ qPl.*2', ⟦ P ⟧) =[borrow_wsatd]=∗
      ([∗ list] q ∈ qPl.*1', q.[α]) ∗ ([∗ list] Q ∈ Ql, borcd α (↑ˡ Q)).
  Proof.
    setoid_rewrite <-nintpS_nintp. iIntros "ol Ql →Pl".
    iDestruct (obor_list with "ol") as (?<-) "[ol →]".
    iMod (obor_tok_merge_subdiv _ Ql with "ol Ql [→ →Pl]") as "[$ cl]".
    { iIntros "† Ql". iMod ("→Pl" with "† Ql") as "Pl". iModIntro.
      setoid_rewrite nintpS_nintp_nlarge. by iApply "→". }
    iModIntro. iStopProof; do 3 f_equiv. iIntros "c". iExists _. iFrame "c".
    iSplit; iModIntro; by iApply conv_refl.
  Qed.
  (** Subdivide borrowers *)
  Lemma obor_subdiv {α q P} (Ql : list (nPropS (;ᵞ))) :
    obord α q P -∗ ([∗ list] Q ∈ Ql, ⟦ Q ⟧) -∗
    ([†α] -∗ ([∗ list] Q ∈ Ql, ⟦ Q ⟧) =[proph_wsat]=∗ ⟦ P ⟧) =[borrow_wsatd]=∗
      q.[α] ∗ ([∗ list] Q ∈ Ql, borcd α (↑ˡ Q)).
  Proof.
    iIntros "o Ql →P".
    iMod (obor_merge_subdiv [(_,_)'] with "[o] Ql [→P]") as "[[$ _]$]"=>/=;
      by [iFrame|rewrite bi.sep_emp|].
  Qed.
  (** Simply close a borrower *)
  Lemma obor_close {q α P} :
    obord α q P -∗ ⟦ P ⟧ =[borrow_wsatd]=∗ q.[α] ∗ borcd α P.
  Proof.
    iIntros "[%Q[#PQ[QP o]]] P". iDestruct (convd_use with "PQ P") as "Q".
    rewrite -nintpS_nintp_nlarge.
    iMod (obor_tok_close (intp:=λ Q, ⟦ Q ⟧ˢ) with "o Q") as "[$ c]". iModIntro.
    iExists _. by iFrame.
  Qed.

  (** Reborrow a borrower *)
  Lemma obor_reborrow {α q P} β :
    obord α q P -∗ ⟦ P ⟧ =[borrow_wsatd]=∗
      q.[α] ∗ borcd (α ⊓ β) P ∗ ([†β] -∗ bord α P).
  Proof.
    iIntros "[%Q[#PQ[#QP o]]] P". iDestruct (convd_use with "PQ P") as "Q".
    rewrite -nintpS_nintp_nlarge.
    iMod (obor_tok_reborrow (intp:=λ Q, ⟦ Q ⟧ˢ) with "o Q") as "[$[c →o]]".
    iModIntro. iSplitL "c".
    - iExists _. iFrame "c". by iSplit.
    - iIntros "†". iExists _. iDestruct ("→o" with "†") as "$". by iSplit.
  Qed.
  Lemma borc_reborrow {α q P} β :
    q.[α] -∗ borcd α P =[borrow_wsatd]=∗
      q.[α] ∗ borcd (α ⊓ β) P ∗ ([†β] -∗ bord α P).
  Proof.
    iIntros "α c". iMod (borc_open with "α c") as "[o P]".
    by iMod (obor_reborrow with "o P").
  Qed.
  Lemma bor_reborrow {E α q P} β :
    q.[α] -∗ bord α P =[borrow_wsatd ∗ proph_wsat]{E}=∗
      q.[α] ∗ borcd (α ⊓ β) P ∗ ([†β] -∗ bord α P).
  Proof.
    iIntros "α b". iMod (bor_open with "α b") as "[o P]".
    by iMod (obor_reborrow with "o P").
  Qed.
End borrow.

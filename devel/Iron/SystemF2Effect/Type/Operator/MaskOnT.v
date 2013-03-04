
Require Import Iron.SystemF2Effect.Type.Operator.LiftTT.
Require Import Iron.SystemF2Effect.Type.Operator.SubstTT.
Require Import Iron.SystemF2Effect.Type.KiJudge.
Require Import Iron.SystemF2Effect.Type.Exp.


(* Mask effects on the given region, 
   replacing with the bottom effect. *)
Fixpoint maskOnT (p : ty -> bool) (e : ty) : ty
 := match e with
    |  TVar tc        => e
    |  TForall k t1   => e
    |  TApp t1 t2     => e
    |  TSum t1 t2     => TSum (maskOnT p t1) (maskOnT p t2)
    |  TBot k         => e

    |  TCon0 tc       => e

    |  TCon1 tc t1
    => if p e     then TBot KEffect
                  else e

    |  TCon2 tc t1 t2 => e
    
    |  TCap  tc       => e
    end.
Arguments maskOnT p e : simpl nomatch.


Definition isEffectTyCon (tc : tycon1) : bool
 := match tc with
    | TyConRead             => true
    | TyConWrite            => true
    | TyConAlloc            => true
    end.


Definition isTVar        (n : nat) (t : ty) : bool
 := match t with
    | TVar n'               => beq_nat n n'
    | _                     => false
    end.

Definition isTCapRegion  (n : nat) (t : ty) : bool
 := match t with
    | TCap (TyCapRegion n') => beq_nat n n'
    | _                     => false
    end.


Definition isEffectOnVar (n : nat) (t : ty) : bool
 := match t with
    | TCon1 tc t1 => andb (isEffectTyCon tc) (isTVar n t1)
    | _           => false
    end.

Definition isEffectOnCap (n : nat) (t : ty) : bool
 := match t with 
    | TCon1 tc t1 => andb (isEffectTyCon tc) (isTCapRegion n t1)
    | _           => false
    end.


Definition maskOnVarT    (n : nat) (e : ty) : ty
 := maskOnT (isEffectOnVar n) e.
Hint Unfold maskOnVarT.

Definition maskOnCapT    (n : nat) (e : ty) : ty
 := maskOnT (isEffectOnCap n) e.
Hint Unfold maskOnCapT.


(********************************************************************)
Lemma maskOnT_kind
 :  forall ke sp t k p
 ,  KIND ke sp t k 
 -> KIND ke sp (maskOnT p t) k.
Proof.
 intros. gen ke sp k.
 induction t; intros; inverts_kind; simpl; eauto.

 - Case "TCon1".
   unfold maskOnT. 
   split_if.
   + destruct t; snorm.
      inverts H4. auto.
      inverts H4. auto.
      inverts H4. auto.
   + destruct t; snorm;
      inverts H4; eapply KiCon1; simpl; eauto.

 - Case "TCon2".
   destruct tc.
   snorm. inverts H2.
   spec IHt1 H5.
   spec IHt2 H7.
   eapply KiCon2. 
    destruct t1. snorm. eauto. eauto.
Qed.


Lemma maskOnVarT_substTT
 :  forall d d' t1 t2
 ,  isEffectOnVar d t2 = false
 -> maskOnVarT d (substTT (1 + d' + d) t2 t1)
 =  substTT (1 + d' + d) (maskOnVarT d t2) (maskOnVarT d t1).
Proof.
 admit.

 (* broken. Change first premise so that t2 does not contain (TVar d) *)

 (*
 intros. gen d d' t2.
 induction t1; intros;
  try (solve [repeat snorm; f_equal]).
 *)
Qed.


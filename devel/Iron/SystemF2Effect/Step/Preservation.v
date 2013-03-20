
Require Export Iron.SystemF2Effect.Step.TypeC.


(* When a well typed expression transitions to the next state
   then its type is preserved. *)
Theorem preservation
 :  forall se sp sp' ss ss' fs fs' x x' t e
 ,  WfFS   se sp ss fs 
 -> TYPEC  nil nil se sp fs  x   t  e
 -> STEPF  ss  sp fs  x ss' sp' fs' x'
 -> (exists se' e'
            ,  extends se' se
            /\ WfFS         se' sp' ss' fs'
            /\ SubsVisibleT nil sp e e'
            /\ TYPEC nil nil se' sp' fs' x' t e').
Proof.
 intros se sp sp' ss ss' fs fs' x x' t e.
 intros HH HC HS. 
 gen t e.
 induction HS; intros.

 (* Pure evaluation. *)
 Case "SfStep". 
 { inverts_typec. 
   exists se. 
   exists e.
   rip.
   - apply subsT_visible_refl.
     eauto.
   - eapply TcExp; eauto.
     eapply stepp_preservation; eauto.
     inverts HH. rip.
 }

 (* Push let context. *)
 Case "SfLetPush".
 { exists se.
   exists e.
   rip. 
   - unfold WfFS in *. rip.
     unfold STOREP in *. rip.
     eapply H3.
     inverts H2.
     + nope.
     + auto.
   - eapply subsT_visible_refl. 
     inverts HC; eauto.
   - inverts HC.
     inverts H0.
     eapply TcExp 
      with (t1 := t) (e1 := e0) (e2 := TSum e3 e2).
      + eapply EqTrans.
         eapply EqSumAssoc; eauto.
         auto.
      + auto.
      + eapply TfConsLet; eauto.
        * inverts HH. rip.
 }

 (* Pop let context and substitute. *)
 Case "SfLetPop".
 { exists se.
   exists e.
   rip.
   - unfold WfFS in *. rip.
     unfold STOREP in *. rip.
   - eapply subsT_visible_refl.
     inverts HC; eauto.
   - inverts HC.
     inverts H1.
     eapply TcExp  
      with (t1 := t3) (e1 := e0) (e2 := e3).
      + inverts H0.
        subst.
        eapply EqTrans.
        * eapply equivT_sum_left. eauto.
          have (KindT nil sp e0 KEffect).
          have (KindT nil sp e3 KEffect).
          eauto.
        * auto.
      + eapply subst_val_exp. 
        * eauto.
        * inverts H0. auto.
      + eauto.
 } 

 (* Create a new region. *)
 Case "SfRegionNew".
 { inverts_typec.
   set (r := TCap (TyCapRegion p)).
   exists se.
   exists (TSum (substTT 0 r e0) (substTT 0 r e2)).

   have (sumkind KEffect).

   have (KindT (nil :> KRegion) sp e0 KEffect).

   have (KindT nil sp e1 KEffect)
    by  (eapply equivT_kind_left; eauto).
   have (ClosedT e1).

   have (KindT nil sp e2 KEffect)
    by  (eapply equivT_kind_left; eauto).
   have (ClosedT e2).

   rip.

   (* Effect of result is subsumed by previous. *)
   - eapply SbTrans
      with (t2 := TSum (substTT 0 r e1) (substTT 0 r e2)).

     + eapply SbEquiv.
        rrwrite (substTT 0 r e1 = e1); auto.
        rrwrite (substTT 0 r e2 = e2); auto.
        eapply EqSym.
         eapply equivT_kind_right; eauto.
         eauto.
        auto.

     + eapply subsT_sum_merge; fold maskOnT.
       * eauto.

       (* Push e0 through region phase change relation. *)  
       * have    (ClosedT r) by (subst r; eauto).
         rrwrite (substTT 0 r e1 = e1).

         admit.                                            (* need maskOnVar/maskOnCap link *)

(*       Probably don't need this stuff.
         assert (substTT 0 r e0 = liftTT 1 0 (substTT 0 r e0)) as HS.
         { assert (WfT 1 e0).
           { have HK: (KindT (nil :> KRegion) sp e0 KEffect).
             have HE: (WfT  (length (nil :> KRegion)) e0) 
              by (eapply kind_wfT; eauto).
             simpl in HE.
             trivial.
           }
           have (ClosedT (substTT 0 r e0)) by (eapply substTT_closing; eauto).
           eapply substTT_liftTT_wfT1; eauto.
         }
         rewrite HS. clear HS.
*)        

       (* Push e2 though region phase change relation. *)
       * have    (ClosedT r)  by (subst r; eauto).
         rrwrite (substTT 0 r e2 = e2).
         eapply maskOnT_subsT. eauto.

   (* Result expression is well typed. *)
   - rrwrite (substTT 0 r e2 = e2).
     eapply TcExp 
       with (sp := sp :> SRegion p) 
            (t1 := substTT 0 r t0)
            (e1 := substTT 0 r e0)
            (e2 := substTT 0 r e2); auto.

     (* Type of result is equivlent to before *)
     + rrwrite (substTT 0 r e2 = e2).
       eapply EqRefl.
        eapply KiSum; auto.
         * eapply subst_type_type. eauto.
           subst r. eauto.
         * eapply kind_stprops_cons. auto.

     (* Type is preserved after substituting region handle. *)
     + have HTE: (nil = substTE 0 r nil).
       rewrite HTE.

       have HSE: (se  = substTE 0 r se)
        by (inverts HH; symmetry; auto).
       rewrite HSE.

       eapply subst_type_exp with (k2 := KRegion).
       * rrwrite (liftTE 0 nil = nil).
         rrwrite (liftTE 0 se  = se) by (inverts HH; auto).
         auto.
       * subst r. auto.

     (* New frame stack is well typed. *)
     + eapply TfConsUse.

       (* New region handle is not in the existing frame stack. *)
       * unfold not. intros.

         have (In (SRegion p) sp)
          by (eapply wfFS_fuse_sregion; eauto).

         have (not (In (SRegion (allocRegion sp)) sp)).
         have (In (SRegion p) sp).
         rewrite H in H14. tauto.

       * rrwrite (substTT 0 r e2 = e2).
         have    (ClosedT t0)           by admit.          (* ok, t0 does not mention ^0 via lowerTT *)
         rrwrite (substTT 0 r t0 = t0).
         rrwrite (t1 = t0) by (eapply lowerTT_closedT; eauto).
         eauto.
 }

 (* Pop a region from ths stack. *)
 Case "SfRegionPop".
 { inverts_typec.

   (* We can only pop if there is at least on region in the store. *)
   destruct sp.

   (* No regions in store. *)
   - inverts HH. rip. 
     unfold STOREP in *.
     spec H4 p.
     have (In (FUse p) (fs :> FUse p)).
      rip. nope.

   (* At least one region in store. *)
   - destruct s.
     exists se.
     exists e2.
     rip.
     (* Frame stack is still well formed after popping the top FUse frame *)
     + eapply wfFS_stack_pop; eauto.

     (* New effect subsumes old one. *)
     + eapply subsT_subsVisibleT.
       have HE: (EquivT nil (sp :> SRegion n) e2 e KEffect).
       eauto.

     (* Resulting configuation is well typed. *)
     + eapply TcExp 
         with (sp := sp :> SRegion n)
              (e1 := TBot KEffect)
              (e2 := e2); eauto.

       eapply EqSym; eauto.
 }

 (* Allocate a reference. *)
 Case "SfStoreAlloc".
 { inverts HC.
   inverts H0.
   exists (TRef   (TCap (TyCapRegion r1)) t2 <: se).
   exists e2.
   rip.
   - unfold WfFS in *.
     rip. eauto.
   - eapply EqSym in H.
      eapply subsT_subsVisibleT; eauto.
      eauto. eauto.
   - eapply TcExp
      with (t1 := TRef (TCap (TyCapRegion r1)) t2)
           (e1 := TBot KEffect)
           (e2 := e2).
     + eapply EqSym.
        * eauto. 
        * eapply KiSum; eauto.
        * eapply equivT_sum_left; eauto.
     + eapply TxVal.
       eapply TvLoc.
        have    (length se = length ss) as HL.
        rrwrite (length ss = length se).
        eauto. eauto.
     + eauto.
 }
      
 (* Read from a reference. *)
 Case "SfStoreRead".
 { inverts HC.
   exists se.
   exists e2. 
   rip.
   - eapply EqSym in H0.
      eapply subsT_subsVisibleT; eauto.
      eauto. eauto.
   - eapply TcExp
      with (t1 := t1)
           (e1 := TBot KEffect)
           (e2 := e2).
     + eapply EqSym; eauto.
     + inverts H1.
       inverts H12.
       eapply TxVal.
        inverts HH. rip.
        eapply storet_get_typev; eauto.
     + eauto.
 }

 (* Write to a reference. *)
 Case "SfStoreWrite".
 { inverts HC.
   exists se.
   exists e2.
   rip.
   - inverts_type.
     eapply store_update_wffs; eauto.
   - eapply EqSym in H.
      eapply subsT_subsVisibleT; eauto.
       eauto. eauto.
   - eapply TcExp
      with (t1 := t1)
           (e1 := TBot KEffect)
           (e2 := e2).
     + eapply EqSym; eauto.
     + inverts_type.
       eapply TxVal.
        inverts HH. rip.
     + eauto.
 }
Qed.


-- A concrete implementation of dyadic numbers
-- and a proof that they are good for AppRationals.
{-# OPTIONS --erasure #-}

module Implementations.Dyadic where

{-# FOREIGN AGDA2HS
import qualified Prelude
import Prelude (Integer, Bool(..), id)

import Tools.ErasureProduct
import Operations.Decidable
import Operations.ShiftL
import Implementations.Int
import Implementations.Rational
import Algebra.Ring
import Algebra.MetricSpace
import RealTheory.AppRationals
#-}

open import Agda.Builtin.Unit
open import Agda.Builtin.Bool
open import Agda.Builtin.Equality
open import Agda.Builtin.Nat using (Nat; zero; suc)
open import Agda.Builtin.Int using (Int; pos; negsuc)
open import Haskell.Prim.Tuple
open import Haskell.Prim using (id; if_then_else_; IsTrue)

open import Tools.Cheat

open import Implementations.Nat
open import Implementations.Int
open import Implementations.Rational
open import Algebra.Setoid
open import Algebra.Ring
open import Operations.Abs
open import Operations.Cast
open import Operations.ShiftL
open import Operations.Pow
open import Operations.Decidable
open import Algebra.Order
open import RealTheory.AppRationals
open import Algebra.MetricSpace
open import Tools.ErasureProduct

-- For the sake of simplicity, we now use the concrete Int type.
-- It can be interpreted as mant * 2 ^ expo.
record Dyadic : Set where
  constructor _:|^_
  field
    mant expo : Int
open Dyadic public
infix 10 _:|^_
{-# COMPILE AGDA2HS Dyadic #-}

twoPowInt : Int -> Rational
twoPowInt n = shift (MkFrac (pos 1) (pos 1) tt) n
{-# COMPILE AGDA2HS twoPowInt #-}

dToQSlow : Dyadic -> Rational
dToQSlow d = MkFrac (mant d) (pos 1) tt * twoPowInt (expo d)
{-# COMPILE AGDA2HS dToQSlow #-}

-- Bringing two dyadics to the same exponent
-- while retaining the values.
-- This will be needed for deciding order.
private
  compare : (Int -> Int -> Bool) -> Dyadic -> Dyadic -> Bool
  compare _##_ (m1 :|^ e1) (m2 :|^ e2) with (e1 <# e2)
  ... | true = m1 ## shift m2 (e2 - e1)
  ... | false = shift m1 (e1 - e2) ## m2
  {-# FOREIGN AGDA2HS
  compare :: (Int -> Int -> Bool) -> Dyadic -> Dyadic -> Bool
  compare f (m1 :|^ e1) (m2 :|^ e2)
    = if e1 <# e2
      then f m1 (shift m2 (e2 - e1))
      else f (shift m1 (e1 - e2)) m2
  #-}

  dEq dLe dLt : Dyadic -> Dyadic -> Bool
  dEq = compare _≃#_
  dLe = compare _≤#_
  dLt = compare _<#_
  {-# COMPILE AGDA2HS dEq #-}
  {-# COMPILE AGDA2HS dLe #-}
  {-# COMPILE AGDA2HS dLt #-}

{-
@0 simplifyCorrect : ∀(d : Dyadic) -> simplify d ≃ d
simplifyCorrect = ?
-}

instance
  -- We define the Set equality by converting both sides to rationals.
  -- TODO: prove this is equivalent to the efficient version.
  setoidDyadic : Setoid Dyadic
  Setoid._≃_ setoidDyadic x y = dToQSlow x ≃ dToQSlow y
  Setoid.≃-refl setoidDyadic {x} = ≃-refl {x = num (dToQSlow x) * den (dToQSlow x)}
  Setoid.≃-sym setoidDyadic {x} {y} = ≃-sym {x = dToQSlow x} {y = dToQSlow y}
  Setoid.≃-trans setoidDyadic {x} {y} {z} = ≃-trans {x = dToQSlow x} {y = dToQSlow y} {z = dToQSlow z}
  {-# COMPILE AGDA2HS setoidDyadic #-}

  strongSetoidDyadic : StrongSetoid Dyadic
  StrongSetoid.super strongSetoidDyadic = setoidDyadic
  StrongSetoid._><_ strongSetoidDyadic x y = dToQSlow x >< dToQSlow y
  StrongSetoid.><-irrefl strongSetoidDyadic {x = x} {y = y} = ><-irrefl {x = dToQSlow x} {y = dToQSlow y}
  StrongSetoid.><-sym strongSetoidDyadic {x = x} {y = y} = ><-sym {x = dToQSlow x} {y = dToQSlow y}
  StrongSetoid.><-cotrans strongSetoidDyadic {x = x} {y = y} neq z = ><-cotrans {x = dToQSlow x} {y = dToQSlow y} neq (dToQSlow z)
  StrongSetoid.><-tight-apart strongSetoidDyadic {x = x} {y = y} = ><-tight-apart {x = dToQSlow x} {y = dToQSlow y}
  {-# COMPILE AGDA2HS strongSetoidDyadic #-}

  trivialApartDyadic : TrivialApart Dyadic
  TrivialApart.super trivialApartDyadic = strongSetoidDyadic
  TrivialApart.trivialApart trivialApartDyadic x y = id , id
  {-# COMPILE AGDA2HS trivialApartDyadic #-}

  -- But this is the efficient one.
  decSetoidDyadic : DecSetoid Dyadic
  DecSetoid.setoid decSetoidDyadic = setoidDyadic
  DecSetoid._≃#_ decSetoidDyadic = dEq
  DecSetoid.≃#-correct decSetoidDyadic = cheat
  {-# COMPILE AGDA2HS decSetoidDyadic #-}

  semiRingDyadic : SemiRing Dyadic
  SemiRing.super semiRingDyadic = setoidDyadic
  -- Uh... what about an absolute value? Can that be used somehow?
  (semiRingDyadic SemiRing.+ mantx :|^ expox) (manty :|^ expoy) =
    if expox ≤# expoy
      then (mantx + shift manty (expoy + negate expox))
                   :|^ expox
      else (shift mantx (expox + negate expoy) + manty)
                   :|^ expoy
  (semiRingDyadic SemiRing.* mantx :|^ expox) (manty :|^ expoy)
                   = (mantx * manty) :|^ (expox + expoy)
  -- Uh; these are going to be pretty hard to work with.
  SemiRing.+-proper semiRingDyadic eq = cheat
  SemiRing.+-assoc semiRingDyadic = cheat
  SemiRing.*-proper semiRingDyadic = cheat
  SemiRing.*-assoc semiRingDyadic = cheat
  SemiRing.null semiRingDyadic = null :|^ null
  SemiRing.one semiRingDyadic = one :|^ null
  SemiRing.NonZero semiRingDyadic x = NonZero (mant x)
  SemiRing.NonZeroCorrect semiRingDyadic x = cheat
  SemiRing.NonZeroOne semiRingDyadic = tt
  SemiRing.+-identityˡ semiRingDyadic = cheat
  SemiRing.+-identityʳ semiRingDyadic = cheat
  SemiRing.*-identityˡ semiRingDyadic x = cheat
  SemiRing.*-identityʳ semiRingDyadic = cheat
  SemiRing.+-comm semiRingDyadic = cheat
  SemiRing.*-comm semiRingDyadic = cheat
  SemiRing.*-nullˡ semiRingDyadic = cheat
  SemiRing.*-nullʳ semiRingDyadic = cheat
  SemiRing.*-distribˡ-+ semiRingDyadic = cheat
  SemiRing.*-distribʳ-+ semiRingDyadic = cheat
  {-# COMPILE AGDA2HS semiRingDyadic #-}

  ringDyadic : Ring Dyadic
  Ring.super ringDyadic = semiRingDyadic
  Ring.negate ringDyadic (mantx :|^ expox) = negate mantx :|^ expox
  Ring.+-inverseˡ ringDyadic = cheat
  Ring.+-inverseʳ ringDyadic = cheat
  {-# COMPILE AGDA2HS ringDyadic #-}

  leDyadic : Le Dyadic
  Le._≤_ leDyadic x y = dToQSlow x ≤ dToQSlow y
  {-# COMPILE AGDA2HS leDyadic #-}

  decLeDyadic : DecLe Dyadic
  DecLe.le decLeDyadic = leDyadic
  DecLe._≤#_ decLeDyadic = dLe
  DecLe.≤#-correct decLeDyadic x y = cheat
  {-# COMPILE AGDA2HS decLeDyadic #-}

  partialOrderDyadic : PartialOrder Dyadic
  PartialOrder.le partialOrderDyadic = leDyadic
  PartialOrder.setoid partialOrderDyadic = setoidDyadic
  PartialOrder.≤-proper partialOrderDyadic x x' y y' eqx eqy = ≤-proper (dToQSlow x) (dToQSlow x') (dToQSlow y) (dToQSlow y') eqx eqy
  {-# COMPILE AGDA2HS partialOrderDyadic #-}

  ltDyadic : Lt Dyadic
  Lt._<_ ltDyadic x y = dToQSlow x < dToQSlow y
  {-# COMPILE AGDA2HS ltDyadic #-}

  decLtDyadic : DecLt Dyadic
  DecLt.lt decLtDyadic = ltDyadic
  DecLt._<#_ decLtDyadic = dLt
  DecLt.<#-correct decLtDyadic x y = cheat
  {-# COMPILE AGDA2HS decLtDyadic #-}
  
  pseudoOrderDyadic : PseudoOrder Dyadic
  PseudoOrder.strongSetoid pseudoOrderDyadic = strongSetoidDyadic
  PseudoOrder.lt pseudoOrderDyadic = ltDyadic
  PseudoOrder.<-asym pseudoOrderDyadic {x} {y} = <-asym {x = dToQSlow x} {y = dToQSlow y}
  PseudoOrder.<-cotrans pseudoOrderDyadic {x} {y} neq z = <-cotrans {x = dToQSlow x} {y = dToQSlow y} neq (dToQSlow z)
  PseudoOrder.<-total pseudoOrderDyadic x y = <-total (dToQSlow x) (dToQSlow y)
  {-# COMPILE AGDA2HS pseudoOrderDyadic #-}

  shiftLDyadic : ShiftL Dyadic
  ShiftL.semiringa shiftLDyadic = semiRingDyadic
  ShiftL.shiftl shiftLDyadic x n = mant x :|^ (pos n + expo x)
  ShiftL.shiftlProper shiftLDyadic = cheat
  ShiftL.shiftlNull shiftLDyadic = cheat
  ShiftL.shiftlSuc shiftLDyadic = cheat
  {-# COMPILE AGDA2HS shiftLDyadic #-}

  shiftDyadic : Shift Dyadic
  Shift.super shiftDyadic = shiftLDyadic
  Shift.shift shiftDyadic x n = mant x :|^ (n + expo x)
  Shift.shiftProper shiftDyadic = cheat
  Shift.shiftEquivalent shiftDyadic = cheat
  Shift.shiftLeftThenRight shiftDyadic = cheat
  {-# COMPILE AGDA2HS shiftDyadic #-}

  exactShiftDyadic : ExactShift Dyadic
  ExactShift.super exactShiftDyadic = shiftDyadic
  ExactShift.shiftRightThenLeft exactShiftDyadic = cheat
  {-# COMPILE AGDA2HS exactShiftDyadic #-}

  natPowDyadic : Pow Dyadic Nat
  Pow._^_ natPowDyadic x n = (mant x ^ n) :|^ ((pos n) * expo x)
  Pow.powProper natPowDyadic eqx refl = cheat
  Pow.powNull natPowDyadic x = cheat
  Pow.powSuc natPowDyadic x n = cheat
  {-# COMPILE AGDA2HS natPowDyadic #-}

  castDyadicRational : Cast Dyadic Rational
  Cast.cast castDyadicRational x = cast {Int} {Rational} (mant x) * shift (one {Rational}) (expo x)
  {-# COMPILE AGDA2HS castDyadicRational #-}

  castIntDyadic : Cast Int Dyadic
  Cast.cast castIntDyadic k = k :|^ null
  {-# COMPILE AGDA2HS castIntDyadic #-}

  absDyadic : Abs Dyadic
  Abs.ring absDyadic = ringDyadic
  Abs.le absDyadic = leDyadic
  Abs.abs absDyadic x = abs (mant x) :|^ expo x
  Abs.absCorrect absDyadic x = cheat , cheat
  {-# COMPILE AGDA2HS absDyadic #-}

  metricSpaceDyadic : MetricSpace Dyadic
  MetricSpace.setoid metricSpaceDyadic = setoidDyadic
  MetricSpace.ball metricSpaceDyadic ε x y = ball ε (dToQSlow x) (dToQSlow y)
  MetricSpace.ballReflexive metricSpaceDyadic ε x x' eq
      = ballReflexive ε (dToQSlow x) (dToQSlow x') eq
  MetricSpace.ballSym metricSpaceDyadic ε x y x≤y
      = ballSym ε (dToQSlow x) (dToQSlow y) x≤y
  MetricSpace.ballTriangle metricSpaceDyadic ε₁ ε₂ x y z x≤y y≤z
      = ballTriangle ε₁ ε₂ (dToQSlow x) (dToQSlow y) (dToQSlow z) x≤y y≤z
  MetricSpace.ballClosed metricSpaceDyadic ε x y f
      = ballClosed ε (dToQSlow x) (dToQSlow y) f
  MetricSpace.ballEq metricSpaceDyadic x y f = ballEq (dToQSlow x) (dToQSlow y) f
  {-# COMPILE AGDA2HS metricSpaceDyadic #-}

  {-# TERMINATING #-}
  prelengthSpaceDyadic : PrelengthSpace Dyadic
  PrelengthSpace.metricSpace prelengthSpaceDyadic = metricSpaceDyadic
  PrelengthSpace.prelength prelengthSpaceDyadic     eps
                                                    d1
                                                    d2
                                                    x y
                                                    ε<δ₁+δ₂
                                                    bεxy
  -- We'll use an iterative method: we always add the lowest 2-power
  -- we can to approximate x+δ₁ (or x-δ₁).
      = go x goal (x ≤# y) currPrec steps :&: (cheat , cheat)
     where
     goal : Rational
     goal = if x ≤# y
            then dToQSlow x + proj₁ d1
            else dToQSlow x + negate (proj₁ d1)
     approx : PosRational -> Int   -- an exponent of 2 for which q<=2^k
     approx q = pos (goApprox (proj₁ q) 0)
       where
       goApprox : Rational -> Nat -> Nat
       goApprox q n = if q ≤# one then n
                        else goApprox (shift q (hsFromIntegral (negsuc 0))) (1 + n)
     currPrec : Int
     currPrec = approx d1
     desiredPrec : Int
     desiredPrec = approx (proj₁ d1 + proj₁ d2 + negate (proj₁ eps)
                             :&: cheat)
     steps : Nat
     steps = if currPrec ≤# desiredPrec then 0 else natAbs (currPrec + negate desiredPrec)
     
     go : (d : Dyadic) (q : Rational) (isAbove : Bool)
             (currentPrecision : Int) (remainingSteps : Nat) -> Dyadic
            -- ^ this is the exponent of 2
            -- and remainingSteps means how many times we need to subtract one from it
     go d _ _ _ zero = d
     go d q isAbove currPrec (suc n) =
             if (abs ((dToQSlow d) + negate q) ≤# shift one (negsuc 0 + currPrec))
             then go d q isAbove (negsuc 0 + currPrec) n
             else go (d + step isAbove currPrec) q isAbove (negsuc 0 + currPrec) n
       where
       step : Bool -> Int -> Dyadic
       step true  currPrec = pos 1    :|^ (negsuc 0 + currPrec)
       step false currPrec = negsuc 0 :|^ (negsuc 0 + currPrec)
  -- Again suc...
  {-# FOREIGN AGDA2HS
  instance PrelengthSpace Dyadic where
    prelength eps d1 d2 x y = (go x goal (x ≤# y) currPrec steps :&:)
      where
        goal :: Rational
        goal
          = if x ≤# y then dToQSlow x + proj₁ d1 else
              dToQSlow x + negate (proj₁ d1)
        approx :: PosRational -> Integer
        approx q = pos (goApprox (proj₁ q) 0)
          where
            goApprox :: Rational -> Natural -> Natural
            goApprox q n
              = if q ≤# one then n else goApprox (shift q (negsuc 0)) (1 + n)
        currPrec :: Integer
        currPrec = approx d1
        desiredPrec :: Integer
        desiredPrec = approx (proj₁ d1 + proj₁ d2 + negate (proj₁ eps) :&:)
        steps :: Natural
        steps
          = if currPrec ≤# desiredPrec then 0 else
              natAbs (currPrec + negate desiredPrec)
        go :: Dyadic -> Rational -> Bool -> Integer -> Natural -> Dyadic
        go d _ _ _ 0 = d
        go d q isAbove currPrec sn =
                if (abs ((dToQSlow d) + negate q) ≤# shift one (negate 1 + currPrec))
                then go d q isAbove (negate 1 + currPrec) (sn Prelude.- 1)
                else go (d + step isAbove currPrec) q isAbove (negate 1 + currPrec) (sn Prelude.- 1)
          where
          step :: Bool -> Int -> Dyadic
          step True  currPrec = 1         :|^ (negate 1 + currPrec)
          step False currPrec = negate 1  :|^ (negate 1 + currPrec)
  #-}


  -- And now...
  appRationalsDyadic : AppRationals Dyadic
  AppRationals.partialOrder appRationalsDyadic = partialOrderDyadic
  AppRationals.pseudoOrder appRationalsDyadic = pseudoOrderDyadic
  AppRationals.decSetoid appRationalsDyadic = decSetoidDyadic
  AppRationals.strongSetoid appRationalsDyadic = strongSetoidDyadic
  AppRationals.trivialApart appRationalsDyadic = trivialApartDyadic
  AppRationals.absAq appRationalsDyadic = absDyadic
  AppRationals.exactShift appRationalsDyadic = exactShiftDyadic
  AppRationals.natPow appRationalsDyadic = natPowDyadic
  AppRationals.castAqRational appRationalsDyadic = castDyadicRational
  AppRationals.castIntAq appRationalsDyadic = castIntDyadic
  AppRationals.prelengthAq appRationalsDyadic = prelengthSpaceDyadic


  AppRationals.aqToQOrderEmbed appRationalsDyadic = ((λ _ _ eq -> eq) , λ _ _ le -> le) , ((λ _ _ eq -> eq) , λ _ _ le -> le)
  AppRationals.aqToQStrictOrderEmbed appRationalsDyadic = ((λ _ _ eq -> eq) , id) , id
  setoidMorphism (SemiRingMorphism.preserves-+ (AppRationals.aqToQSemiRingMorphism appRationalsDyadic)) = λ _ _ eq -> eq
  preservesOp (SemiRingMorphism.preserves-+ (AppRationals.aqToQSemiRingMorphism appRationalsDyadic)) x y = cheat -- here, we could use the Rational instance
  setoidMorphism (SemiRingMorphism.preserves-* (AppRationals.aqToQSemiRingMorphism appRationalsDyadic)) = λ _ _ eq -> eq
  preservesOp (SemiRingMorphism.preserves-* (AppRationals.aqToQSemiRingMorphism appRationalsDyadic)) x y = cheat
  SemiRingMorphism.preserves-null (AppRationals.aqToQSemiRingMorphism appRationalsDyadic) = refl
  SemiRingMorphism.preserves-one (AppRationals.aqToQSemiRingMorphism appRationalsDyadic) = refl
  AppRationals.aqNonZeroToNonZero appRationalsDyadic {pos (suc n) :|^ expo₁} NonZerox = cheat
  AppRationals.aqNonZeroToNonZero appRationalsDyadic {negsuc n :|^ expo₁} NonZerox = cheat

  -- https://github.com/coq-community/corn/blob/c08a0418f97a04ea7a6cdc3a930561cc8fc84d82/reals/faster/ARbigD.v#L265
  -- (shift (mant x) (- (k-1) + expo x - expo y)) `quot` mant y :|^ (k-1)
  AppRationals.appDiv appRationalsDyadic x y NonZeroy k
      = intQuot (shift (mant x) (negate k + pos 1 + expo x + negate (expo y))) (mant y) {NonZeroy} :|^ (k - pos 1)
  AppRationals.appDivCorrect appRationalsDyadic = cheat

  -- Actually, we wouldn't have to shift if we shifted leftwards, would we?
  AppRationals.appApprox appRationalsDyadic x k = shift (mant x) (expo x - k + pos 1) :|^ (k - pos 1)
  AppRationals.appApproxCorrect appRationalsDyadic = cheat

  setoidMorphism (SemiRingMorphism.preserves-+ (AppRationals.intToAqSemiRingMorphism appRationalsDyadic)) _ _ refl = refl
  preservesOp (SemiRingMorphism.preserves-+ (AppRationals.intToAqSemiRingMorphism appRationalsDyadic)) _ _ = cheat
  setoidMorphism (SemiRingMorphism.preserves-* (AppRationals.intToAqSemiRingMorphism appRationalsDyadic)) _ _ refl = refl
  preservesOp (SemiRingMorphism.preserves-* (AppRationals.intToAqSemiRingMorphism appRationalsDyadic)) _ _ = cheat
  SemiRingMorphism.preserves-null (AppRationals.intToAqSemiRingMorphism appRationalsDyadic) = refl
  SemiRingMorphism.preserves-one (AppRationals.intToAqSemiRingMorphism appRationalsDyadic) = refl

  AppRationals.log2Floor appRationalsDyadic (m :|^ k) 0<x = pos (natLog2Floor (natAbs m) {cheat}) + k
  -- AppRationals.log2Floor appRationalsDyadic (negsuc n :|^ k) 0<x = {!!} -- we should derive a contradiction here
  AppRationals.log2FloorCorrect appRationalsDyadic = cheat

  {-# COMPILE AGDA2HS appRationalsDyadic #-}

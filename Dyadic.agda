-- A concrete implementation of dyadic numbers
-- and a proof that they are good for AppRationals.

module Dyadic where

open import Agda.Builtin.Unit
open import Agda.Builtin.Bool
open import Agda.Builtin.Equality
open import Agda.Builtin.Nat using (Nat; zero; suc)
open import Agda.Builtin.Int using (Int; pos; negsuc)
open import Haskell.Prim.Tuple
open import Haskell.Prim using (id; if_then_else_)

open import Cheat

open import Nat
open import Int
open import Rational
open import Setoid
open import Ring
open import Operations
open import Cast
open import Decidable
open import Order
open import AppRationals
open import MetricSpace
open import ErasureProduct

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
twoPowInt n = shiftl one n

dToQSlow : Dyadic -> Rational
dToQSlow d = MkFrac (mant d) one tt * twoPowInt (expo d)

instance
  -- We define equality by converting both sides to rationals.
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

  semiRingDyadic : SemiRing Dyadic
  SemiRing.super semiRingDyadic = setoidDyadic
  -- Uh... what about an absolute value? Can that be used somehow?
  (semiRingDyadic SemiRing.+ mantx :|^ expox) (manty :|^ expoy) with expox ≤# expoy in isLe
  ... | true = (mantx + shiftl manty (expoy + negate expox))
                   :|^ expox
  ... | false = (shiftl mantx (expox + negate expoy) + manty)
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
  DecLe._≤#_ decLeDyadic x y = dToQSlow x ≤# dToQSlow y
  DecLe.≤#-correct decLeDyadic x y = ≤#-correct (dToQSlow x) (dToQSlow y)
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
  DecLt._<#_ decLtDyadic x y = dToQSlow x <# dToQSlow y
  DecLt.<#-correct decLtDyadic x y = <#-correct (dToQSlow x) (dToQSlow y)
  {-# COMPILE AGDA2HS decLtDyadic #-}
  
  pseudoOrderDyadic : PseudoOrder Dyadic
  PseudoOrder.strongSetoid pseudoOrderDyadic = strongSetoidDyadic
  PseudoOrder.lt pseudoOrderDyadic = ltDyadic
  PseudoOrder.<-asym pseudoOrderDyadic {x} {y} = <-asym {x = dToQSlow x} {y = dToQSlow y}
  PseudoOrder.<-cotrans pseudoOrderDyadic {x} {y} neq z = <-cotrans {x = dToQSlow x} {y = dToQSlow y} neq (dToQSlow z)
  PseudoOrder.<-total pseudoOrderDyadic x y = <-total (dToQSlow x) (dToQSlow y)
  {-# COMPILE AGDA2HS pseudoOrderDyadic #-}

  shiftLDyadic : ShiftL Dyadic Int
  ShiftL.semiringa shiftLDyadic = semiRingDyadic
  ShiftL.semiringb shiftLDyadic = semiRingInt
  ShiftL.shiftl shiftLDyadic x n = mant x :|^ (n + expo x)
  ShiftL.shiftlProper shiftLDyadic x x' y y' eqx refl = cheat
  ShiftL.shiftlNull shiftLDyadic = cheat
  ShiftL.shiftlSuc shiftLDyadic = cheat
  {-# COMPILE AGDA2HS shiftLDyadic #-}

  natPowDyadic : Pow Dyadic Nat
  Pow._^_ natPowDyadic x n = (mant x ^ n) :|^ ((pos n) * expo x)
  Pow.powProper natPowDyadic eqx refl = cheat
  Pow.powNull natPowDyadic x = cheat
  Pow.powSuc natPowDyadic x n = cheat
  {-# COMPILE AGDA2HS natPowDyadic #-}

  castDyadicRational : Cast Dyadic Rational
  Cast.cast castDyadicRational x = cast {Int} {Rational} (mant x) * shiftl (one {Rational}) (expo x)
  {-# COMPILE AGDA2HS castDyadicRational #-}

  castIntDyadic : Cast Int Dyadic
  Cast.cast castIntDyadic k = k :|^ null
  {-# COMPILE AGDA2HS castIntDyadic #-}

  -- And now...
  appRationalsDyadic : AppRationals Dyadic
  AppRationals.ring appRationalsDyadic = ringDyadic
  AppRationals.partialOrder appRationalsDyadic = partialOrderDyadic
  AppRationals.pseudoOrder appRationalsDyadic = pseudoOrderDyadic
  AppRationals.strongSetoid appRationalsDyadic = strongSetoidDyadic
  AppRationals.trivialApart appRationalsDyadic = trivialApartDyadic
  AppRationals.shiftL appRationalsDyadic = shiftLDyadic
  AppRationals.natPow appRationalsDyadic = natPowDyadic
  AppRationals.castAqRational appRationalsDyadic = castDyadicRational
  AppRationals.castIntAq appRationalsDyadic = castIntDyadic


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
  -- (shiftl (mant x) (-(k-1) + expo x - expo y)) `quot` mant y
  --      :|^ (k - 1)
  AppRationals.appDiv appRationalsDyadic x y (pos zero) {NonZeroy}
      = (shiftl (mant x) (pos 1 + expo x + negate (expo y)) intDiv (mant y)) {NonZeroy} :|^ (negsuc zero)
  AppRationals.appDiv appRationalsDyadic x y (pos (suc zero)) {NonZeroy}
      = (shiftl (mant x) (expo x + negate (expo y)) intDiv mant y) {NonZeroy} :|^ pos zero
  AppRationals.appDiv appRationalsDyadic x y (pos (suc (suc k))) {NonZeroy}
      = (shiftl (mant x) (negsuc k + expo x + negate (expo y)) intDiv mant y) {NonZeroy} :|^ pos (suc k)
  AppRationals.appDiv appRationalsDyadic x y (negsuc k) {NonZeroy}
      = (shiftl (mant x) (pos (suc (suc k)) + expo x + negate (expo y)) intDiv mant y) {NonZeroy} :|^ negsuc (suc k)
  AppRationals.appDivCorrect appRationalsDyadic = cheat

  -- shiftl (mant x) (-(k - 1) + expo x) :|^ (k - 1)
  AppRationals.appApprox appRationalsDyadic x (pos zero) = shiftl (mant x) (one + expo x) :|^ (negsuc zero)
  AppRationals.appApprox appRationalsDyadic x (pos (suc zero)) = shiftl (mant x) (expo x) :|^ pos zero
  AppRationals.appApprox appRationalsDyadic x (pos (suc (suc k))) = shiftl (mant x) (negsuc k + expo x) :|^ pos (suc k)
  AppRationals.appApprox appRationalsDyadic x (negsuc k) = shiftl (mant x) (pos (suc (suc k)) + expo x) :|^ (negsuc (suc k))
  AppRationals.appApproxCorrect appRationalsDyadic = cheat

  setoidMorphism (SemiRingMorphism.preserves-+ (AppRationals.intToAqSemiRingMorphism appRationalsDyadic)) _ _ refl = refl
  preservesOp (SemiRingMorphism.preserves-+ (AppRationals.intToAqSemiRingMorphism appRationalsDyadic)) _ _ = cheat
  setoidMorphism (SemiRingMorphism.preserves-* (AppRationals.intToAqSemiRingMorphism appRationalsDyadic)) _ _ refl = refl
  preservesOp (SemiRingMorphism.preserves-* (AppRationals.intToAqSemiRingMorphism appRationalsDyadic)) _ _ = refl
  SemiRingMorphism.preserves-null (AppRationals.intToAqSemiRingMorphism appRationalsDyadic) = refl
  SemiRingMorphism.preserves-one (AppRationals.intToAqSemiRingMorphism appRationalsDyadic) = refl

  {-# FOREIGN AGDA2HS
  -- We'll have to rewrite this in Haskell.
  instance AppRationals Dyadic where
    appDiv x y k  = (shiftl (mant x) (negate (k - 1) + expo x - expo y)) `quot` mant y :|^ (k - 1)
    appApprox x k = shiftl (mant x) (-(k - 1) + expo x) :|^ (k - 1)
  #-}

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
                        else goApprox (shiftl q (negsuc 0)) (suc n)
     currPrec : Int
     currPrec = approx d1
     desiredPrec : Int
     desiredPrec = approx (proj₁ d1 + proj₁ d2 + negate (proj₁ eps)
                             :&: cheat)
     steps : Nat
     steps = if currPrec ≤# desiredPrec then zero else natAbs (currPrec + negate desiredPrec)
     
     go : (d : Dyadic) (q : Rational) (isAbove : Bool)
             (currentPrecision : Int) (remainingSteps : Nat) -> Dyadic
            -- ^ this is the exponent of 2
            -- and remainingSteps means how many times we need to subtract one from it
     go d _ _ _ zero = d
     go d q isAbove currPrec (suc n) =
             if (abs ((dToQSlow d) + negate q) ≤# shiftl one (negsuc 0 + currPrec))
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
              = if q ≤# one then n else goApprox (shiftl q (negsuc 0)) (suc n)
        currPrec :: Integer
        currPrec = approx d1
        desiredPrec :: Integer
        desiredPrec = approx (proj₁ d1 + proj₁ d2 + negate (proj₁ eps) :&:)
        steps :: Natural
        steps
          = if currPrec ≤# desiredPrec then zero else
              natAbs (currPrec + negate desiredPrec)
        go :: Dyadic -> Rational -> Bool -> Integer -> Natural -> Dyadic
        go d _ _ _ 0 = d
        go d q isAbove currPrec sn =
                if (abs ((dToQSlow d) + negate q) ≤# shiftl one (negate 1 + currPrec))
                then go d q isAbove (negate 1 + currPrec) (sn - 1)
                else go (d + step isAbove currPrec) q isAbove (negate 1 + currPrec) (sn - 1)
          where
          step :: Bool -> Int -> Dyadic
          step true  currPrec = 1         :|^ (negate 1 + currPrec)
          step false currPrec = negate 1  :|^ (negate 1 + currPrec)
  #-}

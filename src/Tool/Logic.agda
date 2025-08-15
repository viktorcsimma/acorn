-- Some shortenings that don't already exist
-- in the agda2hs library.
{-# OPTIONS --erasure #-}
module Tool.Logic where

open import Agda.Primitive
open import Haskell.Prim.Tuple

-- I don't erase this for now;
-- maybe there are some proofs needing those witnesses.
-- But then, Haskell tuples only work with Set₀.
infixr 2 _↔_
_↔_ : Set -> Set -> Set
A ↔ B = (A -> B) × (B -> A)


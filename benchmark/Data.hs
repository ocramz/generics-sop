{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE RankNTypes #-}
module Data where

import Control.Applicative
import qualified GHC.Generics as GHC
import Generics.SOP
import Generics.SOP.TH
import qualified Generics.SOP.Type.Metadata as T
import Test.QuickCheck
import Test.QuickCheck.Gen
import Test.QuickCheck.Random
import Test.QuickCheck.Arbitrary (Arbitrary(..))
import Generic.Random


data GenericContext
  = THC -- Template Haskell hand written combinator
  | TH  -- Template Haskell
  | Der -- Derived
  | HW  -- Hand written
  | GHC -- GHC Generics

data TreeF (a :: GenericContext) = LeafF Int | NodeF (TreeF a) (TreeF a)
  deriving (GHC.Generic, Show)

instance Arbitrary (TreeF a) where
  arbitrary = genericArbitraryU'

newtype TreeDer = TreeDer (TreeF 'Der) deriving (GHC.Generic)
newtype TreeTH  = TreeTH  (TreeF 'TH)  deriving (GHC.Generic)
newtype TreeTHC = TreeTHC (TreeF 'THC) deriving (GHC.Generic)
newtype TreeHW  = TreeHW  (TreeF 'HW)  deriving (GHC.Generic)
newtype TreeGHC = TreeGHC (TreeF 'GHC) deriving (GHC.Generic)

instance Generic TreeDer

deriveGeneric ''TreeTH
deriveGeneric ''TreeTHC

-- Generic show, kind of
gshow :: (Generic a, All2 Show (Code a)) => a -> String
gshow x = gshowS (from x)

gshowS :: (All2 Show xss) => SOP I xss -> String
gshowS (SOP (Z xs))  = gshowP xs
gshowS (SOP (S xss)) = gshowS (SOP xss)

gshowP :: (All Show xs) => NP I xs -> String
gshowP Nil         = ""
gshowP (I x :* xs) = show x ++ (gshowP xs)

-- Combinator version
gshow' :: (Generic a, All2 Show (Code a)) => a -> String
gshow' =
    concat
  . hcollapse
  . hcmap (Proxy :: Proxy Show) (mapIK show)
  . from

instance Show TreeDer where show = gshow
instance Show TreeTHC where show = gshow'
instance Show TreeTH  where show = gshow

instance Show TreeHW where
  show (TreeHW t) = showHW t where
    showHW (LeafF x)   = show   x
    showHW (NodeF l r) = showHW l ++ showHW r

sample :: Int -> Gen a -> [a]
sample m g = [ gen n (n * n) g | n <- [0 .. m] ]
  where
    gen :: Int -> Int -> Gen a -> a
    gen p s (MkGen g) = g (mkQCGen p) s

treeF :: forall (a :: GenericContext) . TreeF a
treeF = NodeF (LeafF 1) (LeafF 2)

treeDer :: TreeDer
treeDer = TreeDer treeF

treeTH :: TreeTH
treeTH  = TreeTH  treeF

treeTHC :: TreeTHC
treeTHC = TreeTHC treeF

treeHW :: TreeHW
treeHW  = TreeHW  treeF

treeGHC :: TreeGHC
treeGHC = TreeGHC treeF
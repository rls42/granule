{-# LANGUAGE InstanceSigs #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE DeriveFunctor #-}

module Language.Granule.Syntax.Pattern where

import GHC.Generics (Generic)

import Language.Granule.Syntax.Helpers
import Language.Granule.Syntax.FirstParameter
import Language.Granule.Syntax.Identifiers
import Language.Granule.Syntax.Span


-- | Language.Granule.Syntax of patterns
data Pattern a
  = PVar Span a Id                -- ^ Variable patterns
  | PWild Span a                  -- ^ Wildcard (underscore) pattern
  | PBox Span a (Pattern a)       -- ^ Box patterns
  | PInt Span a Int               -- ^ Numeric patterns
  | PFloat Span a Double          -- ^ Float pattern
  | PConstr Span a Id [Pattern a] -- ^ Constructor pattern
  deriving (Eq, Show, Generic, Functor)

-- | First parameter of patterns is their span
instance FirstParameter (Pattern a) Span

-- | Variables bound by patterns
boundVars :: Pattern a -> [Id]
boundVars (PVar _ _ v)     = [v]
boundVars PWild {}       = []
boundVars (PBox _ _ p)     = boundVars p
boundVars PInt {}        = []
boundVars PFloat {}      = []
boundVars (PConstr _ _ _ ps) = concatMap boundVars ps

-- >>> runFreshener (PVar ((0,0),(0,0)) (Id "x" "x"))
-- PVar ((0,0),(0,0)) (Id "x" "x_0")

-- | Freshening for patterns
instance Freshenable (Pattern a) where

  freshen :: Pattern a -> Freshener (Pattern a)
  freshen (PVar s a var) = do
      var' <- freshIdentifierBase Value var
      return $ PVar s a var'

  freshen (PBox s a p) = do
      p' <- freshen p
      return $ PBox s a p'

  freshen (PConstr s a name ps) = do
      ps <- mapM freshen ps
      return (PConstr s a name ps)

  freshen p@PWild {} = return p
  freshen p@PInt {} = return p
  freshen p@PFloat {} = return p

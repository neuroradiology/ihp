{-# LANGUAGE AllowAmbiguousTypes #-}

module IHP.LoginSupport.Helper.Controller
( currentUser
, currentUserOrNothing
, currentUserId
, ensureIsUser
, HasNewSessionUrl
, currentAdmin
, currentAdminOrNothing
, currentAdminId
, ensureIsAdmin
, login
, sessionKey
, logout
, CurrentUserRecord
, CurrentAdminRecord
, module IHP.AuthSupport.Authorization
, module IHP.AuthSupport.Authentication
) where

import IHP.ControllerPrelude
import IHP.LoginSupport.Types
import IHP.Controller.RequestContext
import qualified IHP.Controller.Session as Session
import IHP.FlashMessages.ControllerFunctions
import qualified IHP.ModelSupport as ModelSupport
import IHP.ControllerSupport
import IHP.FrameworkConfig
import System.IO.Unsafe (unsafePerformIO)
import Control.Monad.Fail
import IHP.AuthSupport.Authorization
import IHP.AuthSupport.Authentication
import IHP.Controller.Context

type family CurrentUserRecord
type family CurrentAdminRecord

{-# INLINE currentUser #-}
currentUser :: forall user. (?context :: ControllerContext, HasNewSessionUrl user, Typeable user, user ~ CurrentUserRecord) => user
currentUser = fromMaybe (redirectToLogin (newSessionUrl (Proxy @user))) currentUserOrNothing

{-# INLINE currentUserOrNothing #-}
currentUserOrNothing :: forall user. (?context :: ControllerContext, HasNewSessionUrl user, Typeable user, user ~ CurrentUserRecord) => (Maybe user)
currentUserOrNothing = case unsafePerformIO (maybeFromContext @(Maybe user)) of
    Just user -> user
    Nothing -> error "currentUserOrNothing: initAuthentication @User has not been called in initContext inside FrontController of this application"

{-# INLINE currentUserId #-}
currentUserId :: forall user userId. (?context :: ControllerContext, HasNewSessionUrl user, HasField "id" user userId, Typeable user, user ~ CurrentUserRecord) => userId
currentUserId = currentUser @user |> get #id

{-# INLINE ensureIsUser #-}
ensureIsUser :: forall user userId. (?context :: ControllerContext, HasNewSessionUrl user, HasField "id" user userId, Typeable user, user ~ CurrentUserRecord) => IO ()
ensureIsUser =
    case currentUserOrNothing @user of
        Just _ -> pure ()
        Nothing -> redirectToLoginWithMessage (newSessionUrl (Proxy :: Proxy user))

{-# INLINE currentAdmin #-}
currentAdmin :: forall admin. (?context :: ControllerContext, HasNewSessionUrl admin, Typeable admin) => admin
currentAdmin = fromMaybe (redirectToLogin (newSessionUrl (Proxy @admin))) currentAdminOrNothing

{-# INLINE currentAdminOrNothing #-}
currentAdminOrNothing :: forall admin. (?context :: ControllerContext, HasNewSessionUrl admin, Typeable admin) => (Maybe admin)
currentAdminOrNothing = case unsafePerformIO (maybeFromContext @(Maybe admin)) of
    Just admin -> admin
    Nothing -> error "currentAdminOrNothing: initAuthentication @Admin has not been called in initContext inside FrontController of this application"

{-# INLINE currentAdminId #-}
currentAdminId :: forall admin adminId. (?context :: ControllerContext, HasNewSessionUrl admin, HasField "id" admin adminId, Typeable admin) => adminId
currentAdminId = currentAdmin @admin |> get #id

{-# INLINE ensureIsAdmin #-}
ensureIsAdmin :: forall admin adminId. (?context :: ControllerContext, HasNewSessionUrl admin, Typeable admin) => IO ()
ensureIsAdmin =
    case currentAdminOrNothing @admin of
        Just _ -> pure ()
        Nothing -> redirectToLoginWithMessage (newSessionUrl (Proxy :: Proxy admin))

-- | Log's in an entity
-- Examples:
-- ```
-- let user :: User = ... in login user
-- let admin :: Admin = ... in login admin
-- ```
{-# INLINE login #-}
login :: forall user id. (?context :: ControllerContext, KnownSymbol (ModelSupport.GetModelName user), HasField "id" user id, Show id) => user -> IO ()
login user = Session.setSession (sessionKey @user) (tshow (get #id user))

-- Log's out an entity
{-# INLINE logout #-}
logout :: forall user id. (?context :: ControllerContext, KnownSymbol (ModelSupport.GetModelName user), HasField "id" user id, Show id) => user -> IO ()
logout user = Session.setSession (sessionKey @user) ""

{-# INLINE sessionKey #-}
sessionKey :: forall user. (KnownSymbol (ModelSupport.GetModelName user)) => Text
sessionKey = "login." <> ModelSupport.getModelName @user

redirectToLoginWithMessage :: (?context :: ControllerContext) => Text -> IO ()
redirectToLoginWithMessage newSessionPath = do 
    setSuccessMessage "Please log in to access this page"
    setSession "IHP.LoginSupport.redirectAfterLogin" (cs getRequestPathAndQuery)
    redirectToPath newSessionPath
    error "Unreachable"


redirectToLogin :: (?context :: ControllerContext) => Text -> a
redirectToLogin newSessionPath = unsafePerformIO $ do
    redirectToPath newSessionPath
    error "Unreachable"


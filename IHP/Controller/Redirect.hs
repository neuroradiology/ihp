{-|
Module: IHP.Controller.Redirect
Description: redirect helpers
Copyright: (c) digitally induced GmbH, 2020
-}
module IHP.Controller.Redirect (redirectTo, redirectToPath, redirectToUrl) where

import IHP.Prelude
import qualified Network.Wai.Util
import Network.URI (parseURI)
import IHP.Controller.RequestContext
import IHP.RouterSupport (HasPath (pathTo))
import IHP.FrameworkConfig
import qualified Network.Wai as Wai
import Data.String.Conversions (cs)
import Data.Maybe (fromJust)
import Network.HTTP.Types (status200, status302)
import GHC.Records

import IHP.Controller.Context
import IHP.ControllerSupport

-- | Redirects to an action
-- 
-- __Example:__
-- 
-- > redirectTo ShowProjectAction { projectId = get #id project }
--
-- Use 'redirectToPath' if you want to redirect to a non-action url.
{-# INLINE redirectTo #-}
redirectTo :: (?context :: ControllerContext, HasPath action) => action -> IO ()
redirectTo action = redirectToPath (pathTo action)

-- TODO: redirectTo user

-- | Redirects to a path (given as a string)
--
-- __Example:__
-- 
-- > redirectToPath "/blog/wp-login.php"
--
-- Use 'redirectTo' if you want to redirect to a controller action.
{-# INLINE redirectToPath #-}
redirectToPath :: (?context :: ControllerContext) => Text -> IO ()
redirectToPath path = redirectToUrl (fromConfig baseUrl <> path)

-- | Redirects to a url (given as a string)
-- 
-- __Example:__
--
-- > redirectToUrl "https://example.com/hello-world.html"
--
-- Use 'redirectToPath' if you want to redirect to a relative path like "/hello-world.html"
{-# INLINE redirectToUrl #-}
redirectToUrl :: (?context :: ControllerContext) => Text -> IO ()
redirectToUrl url = do
    let RequestContext { respond } = ?context |> get #requestContext
    let !parsedUrl = fromMaybe 
            (error ("redirectToPath: Unable to parse url: " <> show url))
            (parseURI (cs url))
    let !redirectResponse = fromMaybe
            (error "redirectToPath: Unable to construct redirect response")
            (Network.Wai.Util.redirect status302 [] parsedUrl)
    respondAndExit redirectResponse

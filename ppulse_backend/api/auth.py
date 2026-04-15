"""
Custom JWT authentication that respects per-user token versioning.

When an admin force-logs-out a user (or resets their password), we bump
`User.token_version`. Any access token issued with the old version will fail
authentication on the next request, effectively invalidating every existing
session for that account — even though the JWT itself hasn't expired.
"""

from rest_framework_simplejwt.authentication import JWTAuthentication
from rest_framework_simplejwt.exceptions import InvalidToken


class VersionedJWTAuthentication(JWTAuthentication):
    """JWT auth that compares the token's `tv` claim against User.token_version."""

    def get_user(self, validated_token):
        user = super().get_user(validated_token)
        try:
            token_tv = int(validated_token.get('tv', 0) or 0)
        except (TypeError, ValueError):
            token_tv = 0
        if int(getattr(user, 'token_version', 0) or 0) != token_tv:
            raise InvalidToken('Token has been revoked. Please log in again.')
        return user

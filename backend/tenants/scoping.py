"""Shared helpers for restricting data to the tenants a user belongs to.
Used by both the Django admin (TenantScopedAdmin) and the DRF API
(TenantScopedViewSetMixin) so the row-visibility rule lives in one place.
"""


def tenant_ids_for_user(user):
    """IDs of tenants this user is a member of. Superusers get None, meaning
    "no restriction" — callers should treat None as "skip filtering"."""
    if user.is_superuser:
        return None
    return list(user.memberships.values_list("tenant_id", flat=True))


def is_tenant_member(user, tenant_id):
    if user.is_superuser:
        return True
    return user.memberships.filter(tenant_id=tenant_id).exists()

from django.conf import settings
from django.db import models


class Tenant(models.Model):
    """A single organization/workspace. All finance data belongs to exactly
    one Tenant, and a user can only see data for tenants they're a member of.
    """

    name = models.CharField(max_length=120)
    slug = models.SlugField(max_length=140, unique=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["name"]

    def __str__(self):
        return self.name


class Membership(models.Model):
    ROLE_OWNER = "owner"
    ROLE_ADMIN = "admin"
    ROLE_MEMBER = "member"
    ROLE_CHOICES = [
        (ROLE_OWNER, "Owner"),
        (ROLE_ADMIN, "Admin"),
        (ROLE_MEMBER, "Member"),
    ]

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="memberships"
    )
    tenant = models.ForeignKey(Tenant, on_delete=models.CASCADE, related_name="memberships")
    role = models.CharField(max_length=10, choices=ROLE_CHOICES, default=ROLE_MEMBER)
    # Comma-separated page keys this member may open when role == "member".
    # Owners/admins implicitly have access to every page regardless of this.
    allowed_pages = models.CharField(max_length=200, blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = [("user", "tenant")]
        ordering = ["tenant__name", "user__username"]

    def __str__(self):
        return f"{self.user} @ {self.tenant} ({self.role})"

    @property
    def is_admin(self):
        return self.role in (self.ROLE_OWNER, self.ROLE_ADMIN)

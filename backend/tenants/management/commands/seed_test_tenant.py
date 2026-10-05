from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand

from tenants.models import Membership, Tenant

User = get_user_model()


class Command(BaseCommand):
    """Idempotent test-data bootstrap, safe to run on every deploy. Creates
    one Tenant and two test users (a full admin and a page-restricted
    member) so the Flutter app has something to log into out of the box.
    Does nothing once these already exist — rotate the passwords via
    /admin/ or the app's own "change password" once real users take over.
    """

    help = "Create a test Tenant with an admin and a restricted member user, if they don't exist yet."

    TENANT_SLUG = "kosh"
    TENANT_NAME = "Kosh Finance"

    def handle(self, *args, **options):
        tenant, tenant_created = Tenant.objects.get_or_create(
            slug=self.TENANT_SLUG, defaults={"name": self.TENANT_NAME}
        )
        if tenant_created:
            self.stdout.write(self.style.SUCCESS(f"Created tenant '{tenant.name}'."))
        else:
            self.stdout.write(f"Tenant '{tenant.name}' already exists — skipping.")

        self._ensure_member(tenant, "test_admin", "kosh-test-admin-1", Membership.ROLE_OWNER, "")
        self._ensure_member(
            tenant, "test_member", "kosh-test-member-1", Membership.ROLE_MEMBER, "dashboard,business"
        )

    def _ensure_member(self, tenant, username, password, role, allowed_pages):
        user, user_created = User.objects.get_or_create(username=username)
        if user_created:
            user.set_password(password)
            user.save()
            self.stdout.write(self.style.SUCCESS(f"Created user '{username}'."))

        membership, membership_created = Membership.objects.get_or_create(
            user=user, tenant=tenant, defaults={"role": role, "allowed_pages": allowed_pages}
        )
        if membership_created:
            self.stdout.write(self.style.SUCCESS(f"Added '{username}' to '{tenant.name}' as {role}."))
        else:
            self.stdout.write(f"'{username}' is already a member of '{tenant.name}' — skipping.")

from django.core.management.base import BaseCommand, CommandError

from finance.models import (
    Business,
    BusinessExpense,
    BusinessRevenue,
    Customer,
    CustomerCheckin,
    EmploymentExpense,
    EmploymentIncome,
    IncomeSource,
    InvestmentEntry,
    RevenueTarget,
)
from tenants.models import Tenant

from . import _budget_data as data


class Command(BaseCommand):
    """Loads the historical Oct Kosh Budget.xlsx data into one tenant.
    Idempotent: skips entirely if that tenant already has any
    EmploymentIncome rows, so running this twice doesn't duplicate data.
    """

    help = "Load the Oct Kosh Budget.xlsx dataset into a tenant (default slug: kosh)."

    def add_arguments(self, parser):
        parser.add_argument(
            "--tenant-slug",
            default="kosh",
            help="Slug of the tenant to load data into (default: kosh).",
        )

    def handle(self, *args, **options):
        slug = options["tenant_slug"]
        try:
            tenant = Tenant.objects.get(slug=slug)
        except Tenant.DoesNotExist:
            raise CommandError(f"No tenant with slug '{slug}' — create it first (e.g. via seed_test_tenant).")

        if EmploymentIncome.objects.filter(tenant=tenant).exists():
            self.stdout.write(f"'{tenant.name}' already has employment income rows — skipping.")
            return

        source, _ = IncomeSource.objects.get_or_create(tenant=tenant, name="Employment")

        business_names = set()
        for row in data.seedBusinessRevenue + data.seedBusinessExpense:
            business_names.add(row["business"])
        businesses = {}
        for name in business_names:
            businesses[name], _ = Business.objects.get_or_create(tenant=tenant, name=name)

        EmploymentIncome.objects.bulk_create(
            EmploymentIncome(
                tenant=tenant,
                source=source,
                year=row["year"],
                month=row["month"],
                type=row["type"],
                expected=row["expected"],
                actual=row["actual"],
            )
            for row in data.seedEmploymentIncome
        )

        EmploymentExpense.objects.bulk_create(
            EmploymentExpense(
                tenant=tenant,
                year=row["year"],
                month=row["month"],
                item=row["item"],
                estimated=row["estimated"],
                actual=row["actual"],
            )
            for row in data.seedEmploymentExpense
        )

        BusinessRevenue.objects.bulk_create(
            BusinessRevenue(
                tenant=tenant,
                business=businesses[row["business"]],
                year=row["year"],
                month=row["month"],
                expected=row["expected"],
                actual=row["actual"],
            )
            for row in data.seedBusinessRevenue
        )

        BusinessExpense.objects.bulk_create(
            BusinessExpense(
                tenant=tenant,
                business=businesses[row["business"]],
                year=row["year"],
                month=row["month"],
                item=row["item"],
                estimated=row["estimated"],
                actual=row["actual"],
            )
            for row in data.seedBusinessExpense
        )

        InvestmentEntry.objects.bulk_create(
            InvestmentEntry(
                tenant=tenant,
                year=row["year"],
                month=row["month"],
                closing_value=row["closingValue"],
                total_interest=row["totalInterest"],
                current_month_income=row["currentMonthIncome"],
            )
            for row in data.seedInvestments
        )

        RevenueTarget.objects.bulk_create(
            RevenueTarget(
                tenant=tenant,
                month=row["month"],
                target=row["target"],
                actual=row["actual"],
            )
            for row in data.seedRevenueTargets
        )

        for row in data.seedCustomers:
            customer = Customer.objects.create(
                tenant=tenant,
                name=row["name"],
                phone=row["phone"] or "",
                category=row["category"] or "",
                avg_spending=row["avgSpending"],
            )
            CustomerCheckin.objects.bulk_create(
                CustomerCheckin(
                    customer=customer,
                    month=chk["month"],
                    week=chk["week"],
                    status=chk["status"],
                )
                for chk in row["checkins"]
            )

        self.stdout.write(self.style.SUCCESS(
            f"Loaded budget data into '{tenant.name}': "
            f"{len(data.seedEmploymentIncome)} income, {len(data.seedEmploymentExpense)} expense, "
            f"{len(data.seedBusinessRevenue)} biz revenue, {len(data.seedBusinessExpense)} biz expense, "
            f"{len(data.seedInvestments)} investments, {len(data.seedCustomers)} customers, "
            f"{len(data.seedRevenueTargets)} targets, {len(businesses)} businesses."
        ))

from django.db import models

from tenants.models import Tenant

MONTH_CHOICES = [
    ("Jan", "Jan"), ("Feb", "Feb"), ("Mar", "Mar"), ("Apr", "Apr"),
    ("May", "May"), ("Jun", "Jun"), ("Jul", "Jul"), ("Aug", "Aug"),
    ("Sep", "Sep"), ("Oct", "Oct"), ("Nov", "Nov"), ("Dec", "Dec"),
]


class IncomeSource(models.Model):
    tenant = models.ForeignKey(Tenant, on_delete=models.CASCADE, related_name="income_sources")
    name = models.CharField(max_length=80)

    class Meta:
        unique_together = [("tenant", "name")]
        ordering = ["name"]

    def __str__(self):
        return self.name


class Business(models.Model):
    tenant = models.ForeignKey(Tenant, on_delete=models.CASCADE, related_name="businesses")
    name = models.CharField(max_length=120)

    class Meta:
        unique_together = [("tenant", "name")]
        ordering = ["name"]
        verbose_name_plural = "businesses"

    def __str__(self):
        return self.name


class EmploymentIncome(models.Model):
    tenant = models.ForeignKey(Tenant, on_delete=models.CASCADE, related_name="employment_income")
    source = models.ForeignKey(IncomeSource, on_delete=models.PROTECT, related_name="income_entries")
    year = models.PositiveSmallIntegerField()
    month = models.CharField(max_length=3, choices=MONTH_CHOICES)
    type = models.CharField(max_length=80)
    expected = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    actual = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)

    class Meta:
        ordering = ["-year", "month"]
        verbose_name_plural = "employment income"

    def __str__(self):
        return f"{self.source} · {self.type} ({self.month} {self.year})"


class EmploymentExpense(models.Model):
    tenant = models.ForeignKey(Tenant, on_delete=models.CASCADE, related_name="employment_expenses")
    year = models.PositiveSmallIntegerField()
    month = models.CharField(max_length=3, choices=MONTH_CHOICES)
    item = models.CharField(max_length=80)
    estimated = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    actual = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)

    class Meta:
        ordering = ["-year", "month"]

    def __str__(self):
        return f"{self.item} ({self.month} {self.year})"


class BusinessRevenue(models.Model):
    tenant = models.ForeignKey(Tenant, on_delete=models.CASCADE, related_name="business_revenue")
    business = models.ForeignKey(Business, on_delete=models.CASCADE, related_name="revenue_entries")
    year = models.PositiveSmallIntegerField()
    month = models.CharField(max_length=3, choices=MONTH_CHOICES)
    expected = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    actual = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)

    class Meta:
        ordering = ["-year", "month"]
        verbose_name_plural = "business revenue"

    def __str__(self):
        return f"{self.business} revenue ({self.month} {self.year})"


class BusinessExpense(models.Model):
    tenant = models.ForeignKey(Tenant, on_delete=models.CASCADE, related_name="business_expenses")
    business = models.ForeignKey(Business, on_delete=models.CASCADE, related_name="expense_entries")
    year = models.PositiveSmallIntegerField()
    month = models.CharField(max_length=3, choices=MONTH_CHOICES)
    item = models.CharField(max_length=80)
    estimated = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    actual = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)

    class Meta:
        ordering = ["-year", "month"]

    def __str__(self):
        return f"{self.business} · {self.item} ({self.month} {self.year})"


class DailySale(models.Model):
    tenant = models.ForeignKey(Tenant, on_delete=models.CASCADE, related_name="daily_sales")
    business = models.ForeignKey(Business, on_delete=models.CASCADE, related_name="daily_sales")
    date = models.DateField()
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    note = models.CharField(max_length=200, blank=True)

    class Meta:
        ordering = ["-date"]

    def __str__(self):
        return f"{self.business} {self.date} {self.amount}"


class InvestmentEntry(models.Model):
    tenant = models.ForeignKey(Tenant, on_delete=models.CASCADE, related_name="investments")
    year = models.PositiveSmallIntegerField()
    month = models.CharField(max_length=3, choices=MONTH_CHOICES)
    closing_value = models.DecimalField(max_digits=14, decimal_places=2, null=True, blank=True)
    total_interest = models.DecimalField(max_digits=14, decimal_places=2, null=True, blank=True)
    current_month_income = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)

    class Meta:
        ordering = ["-year", "month"]
        verbose_name_plural = "investment entries"

    def __str__(self):
        return f"Investments {self.month} {self.year}"


class Customer(models.Model):
    tenant = models.ForeignKey(Tenant, on_delete=models.CASCADE, related_name="customers")
    name = models.CharField(max_length=120)
    phone = models.CharField(max_length=30, blank=True)
    category = models.CharField(max_length=80, blank=True)
    avg_spending = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)

    class Meta:
        ordering = ["name"]

    def __str__(self):
        return self.name


class CustomerCheckin(models.Model):
    STATUS_VISITED = "visited"
    STATUS_MISSED = "missed"
    STATUS_CHOICES = [(STATUS_VISITED, "Visited"), (STATUS_MISSED, "Missed")]

    customer = models.ForeignKey(Customer, on_delete=models.CASCADE, related_name="checkins")
    month = models.CharField(max_length=3, choices=MONTH_CHOICES)
    week = models.PositiveSmallIntegerField()
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, blank=True, null=True)

    class Meta:
        unique_together = [("customer", "month", "week")]
        ordering = ["month", "week"]

    def __str__(self):
        return f"{self.customer} {self.month} W{self.week}"

    @property
    def tenant_id(self):
        return self.customer.tenant_id


class RevenueTarget(models.Model):
    tenant = models.ForeignKey(Tenant, on_delete=models.CASCADE, related_name="revenue_targets")
    month = models.CharField(max_length=3, choices=MONTH_CHOICES)
    target = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    actual = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)

    class Meta:
        ordering = ["month"]

    def __str__(self):
        return f"Target {self.month}"

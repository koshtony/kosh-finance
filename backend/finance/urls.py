from rest_framework.routers import DefaultRouter

from . import api

router = DefaultRouter()
router.register("income-sources", api.IncomeSourceViewSet, basename="income-source")
router.register("businesses", api.BusinessViewSet, basename="business")
router.register("employment-income", api.EmploymentIncomeViewSet, basename="employment-income")
router.register("employment-expenses", api.EmploymentExpenseViewSet, basename="employment-expense")
router.register("business-revenue", api.BusinessRevenueViewSet, basename="business-revenue")
router.register("business-expenses", api.BusinessExpenseViewSet, basename="business-expense")
router.register("daily-sales", api.DailySaleViewSet, basename="daily-sale")
router.register("investments", api.InvestmentEntryViewSet, basename="investment")
router.register("customers", api.CustomerViewSet, basename="customer")
router.register("customer-checkins", api.CustomerCheckinViewSet, basename="customer-checkin")
router.register("revenue-targets", api.RevenueTargetViewSet, basename="revenue-target")

urlpatterns = router.urls

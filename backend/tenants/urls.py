from rest_framework.routers import DefaultRouter

from . import api

router = DefaultRouter()
router.register("members", api.MemberViewSet, basename="member")

urlpatterns = router.urls

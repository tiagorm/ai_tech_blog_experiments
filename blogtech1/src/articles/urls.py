from django.urls import path
from . import views

urlpatterns = [
    path("", views.home, name="home"),
    path("about/", views.about, name="about"),
    path("articles/", views.article_list, name="article_list"),
    path("<slug:slug>/", views.article_detail, name="article_detail"),
]

from django.shortcuts import render, get_object_or_404
from .models import Article
import markdown
from django.utils.safestring import mark_safe
from django.db.models.functions import TruncMonth
from django.db.models import Q

def home(request):
    all_articles = Article.objects.order_by('-created_at')
    latest_article = all_articles.first()
    articles = all_articles[1:] if latest_article else []
    return render(request, "articles/home.html", {"latest_article": latest_article, "articles": articles})

def article_detail(request, slug):
    article = get_object_or_404(Article, slug=slug)
    html_content = mark_safe(markdown.markdown(article.content, extensions=['fenced_code', 'codehilite']))
    return render(request, "articles/detail.html", {"article": article, "html_content": html_content})

def about(request):
    return render(request, "articles/about.html")

def article_list(request):
    query = request.GET.get('q', '')
    year = request.GET.get('year', '')
    month = request.GET.get('month', '')
    articles = Article.objects.order_by('-created_at')
    if query:
        articles = articles.filter(Q(title__icontains=query) | Q(content__icontains=query))
    if year:
        articles = articles.filter(created_at__year=year)
    if month:
        articles = articles.filter(created_at__month=month)
    # For filter dropdowns
    years = Article.objects.dates('created_at', 'year', order='DESC')
    months = Article.objects.dates('created_at', 'month', order='DESC')
    return render(request, "articles/article_list.html", {
        "articles": articles,
        "query": query,
        "year": year,
        "month": month,
        "years": years,
        "months": months,
    })

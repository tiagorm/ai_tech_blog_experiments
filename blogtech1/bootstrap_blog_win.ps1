# PowerShell script to bootstrap a minimal Django blog on Windows, with project under 'src'

$ErrorActionPreference = 'Stop'

$SRC_DIR = "src"
$PROJECT_NAME = "blogtech1"
$APP_NAME = "articles"

Write-Host "Creating virtual environment..."
python -m venv venv_blogtech1
.\venv_blogtech1\Scripts\Activate.ps1

Write-Host "Installing dependencies..."
pip install django markdown pygments

Write-Host "Creating src directory..."
New-Item -ItemType Directory -Force -Path $SRC_DIR | Out-Null
Set-Location $SRC_DIR

Write-Host "Starting Django project..."
django-admin startproject $PROJECT_NAME .
python manage.py startapp $APP_NAME

Write-Host "Adding 'articles' app to INSTALLED_APPS..."
(Get-Content $PROJECT_NAME\settings.py) -replace '(INSTALLED_APPS = \[)', "`$1`r`n    '$APP_NAME'," | Set-Content $PROJECT_NAME\settings.py

Write-Host "Creating Article model..."
@"
from django.db import models

class Article(models.Model):
    title = models.CharField(max_length=200)
    slug = models.SlugField(unique=True)
    content = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.title
"@ | Set-Content $APP_NAME\models.py

Write-Host "Registering Article model in admin..."
@"
from django.contrib import admin
from .models import Article

@admin.register(Article)
class ArticleAdmin(admin.ModelAdmin):
    prepopulated_fields = {"slug": ("title",)}
    list_display = ("title", "created_at")
    search_fields = ("title", "content")
"@ | Set-Content $APP_NAME\admin.py

Write-Host "Creating basic views and URLs..."
@"
from django.shortcuts import render, get_object_or_404
from .models import Article
import markdown
from django.utils.safestring import mark_safe

def home(request):
    articles = Article.objects.order_by('-created_at')
    return render(request, "articles/home.html", {"articles": articles})

def article_detail(request, slug):
    article = get_object_or_404(Article, slug=slug)
    html_content = mark_safe(markdown.markdown(article.content, extensions=['fenced_code', 'codehilite']))
    return render(request, "articles/detail.html", {"article": article, "html_content": html_content})

def about(request):
    return render(request, "articles/about.html")
"@ | Set-Content $APP_NAME\views.py

@"
from django.urls import path
from . import views

urlpatterns = [
    path("", views.home, name="home"),
    path("about/", views.about, name="about"),
    path("<slug:slug>/", views.article_detail, name="article_detail"),
]
"@ | Set-Content $APP_NAME\urls.py

Write-Host "Adding app URLs to project..."
$urlsPath = "$PROJECT_NAME\urls.py"
(Get-Content $urlsPath) -replace 'from django.urls import path', "from django.urls import path`r`nfrom django.urls import include" | Set-Content $urlsPath
(Get-Content $urlsPath) -replace '(urlpatterns = \[)', "`$1`r`n    path('', include('$APP_NAME.urls'))," | Set-Content $urlsPath

Write-Host "Creating templates..."
$templatesPath = "$APP_NAME\templates\articles"
New-Item -ItemType Directory -Force -Path $templatesPath | Out-Null

@"
<!DOCTYPE html>
<html>
<head>
    <title>AI & ML Engineering Blog</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.7.0/styles/github.min.css">
    <style>
        body { font-family: 'Segoe UI', sans-serif; background: #fafbfc; color: #222; margin: 0; padding: 0; }
        .container { max-width: 700px; margin: 40px auto; padding: 20px; background: #fff; border-radius: 8px; }
        h1 { font-size: 2.5em; margin-bottom: 0.2em; }
        a { color: #007acc; text-decoration: none; }
        a:hover { text-decoration: underline; }
        .article-list { list-style: none; padding: 0; }
        .article-list li { margin-bottom: 1.5em; }
        .date { color: #888; font-size: 0.9em; }
        nav { margin-bottom: 2em; }
    </style>
</head>
<body>
    <div class="container">
        <nav>
            <a href="/">Home</a> | <a href="/about/">About</a>
        </nav>
        <h1>AI & ML Engineering Blog</h1>
        <ul class="article-list">
            {% for article in articles %}
            <li>
                <a href="/{{ article.slug }}/"><strong>{{ article.title }}</strong></a>
                <div class="date">{{ article.created_at|date:"F j, Y" }}</div>
            </li>
            {% empty %}
            <li>No articles yet.</li>
            {% endfor %}
        </ul>
    </div>
</body>
</html>
"@ | Set-Content $templatesPath\home.html

@"
<!DOCTYPE html>
<html>
<head>
    <title>{{ article.title }} - AI & ML Engineering Blog</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.7.0/styles/github.min.css">
    <style>
        body { font-family: 'Segoe UI', sans-serif; background: #fafbfc; color: #222; margin: 0; padding: 0; }
        .container { max-width: 700px; margin: 40px auto; padding: 20px; background: #fff; border-radius: 8px; }
        h1 { font-size: 2.2em; }
        nav { margin-bottom: 2em; }
        pre { background: #f6f8fa; padding: 1em; border-radius: 5px; overflow-x: auto; }
        code { font-family: 'Fira Mono', monospace; }
        .date { color: #888; font-size: 0.9em; }
    </style>
</head>
<body>
    <div class="container">
        <nav>
            <a href="/">Home</a> | <a href="/about/">About</a>
        </nav>
        <h1>{{ article.title }}</h1>
        <div class="date">{{ article.created_at|date:"F j, Y" }}</div>
        <div>
            {{ html_content|safe }}
        </div>
    </div>
</body>
</html>
"@ | Set-Content $templatesPath\detail.html

@"
<!DOCTYPE html>
<html>
<head>
    <title>About - AI & ML Engineering Blog</title>
    <style>
        body { font-family: 'Segoe UI', sans-serif; background: #fafbfc; color: #222; margin: 0; padding: 0; }
        .container { max-width: 700px; margin: 40px auto; padding: 20px; background: #fff; border-radius: 8px; }
        nav { margin-bottom: 2em; }
    </style>
</head>
<body>
    <div class="container">
        <nav>
            <a href="/">Home</a> | <a href="/about/">About</a>
        </nav>
        <h1>About</h1>
        <p>This blog shares insights, tutorials, and engineering stories about Artificial Intelligence and Machine Learning. Written by an engineer passionate about building intelligent systems.</p>
    </div>
</body>
</html>
"@ | Set-Content $templatesPath\about.html

Write-Host "Making migrations and migrating database..."
python manage.py makemigrations
python manage.py migrate

Write-Host "Creating superuser (for admin access)..."
Write-Host "You will be prompted to enter username, email, and password."
python manage.py createsuperuser

Write-Host "Bootstrap complete! You can now run the server with:"
Write-Host "cd src; ..\venv_blogtech1\Scripts\Activate.ps1 && python manage.py runserver"

Write-Host "To add example articles, log in to /admin/ and create a few posts!"

Set-Location .. 
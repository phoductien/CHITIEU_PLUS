document.addEventListener('DOMContentLoaded', () => {
    // --- Internationalization (i18n) ---
    let translations = {};
    const langSelector = document.getElementById('language-selector');
    
    async function loadTranslations() {
        try {
            const response = await fetch('translations.json');
            translations = await response.json();
            const savedLang = localStorage.getItem('language') || 'vi';
            setLanguage(savedLang);
            if (langSelector) langSelector.value = savedLang;
        } catch (error) {
            console.error('Error loading translations:', error);
        }
    }

    function setLanguage(lang) {
        document.querySelectorAll('[data-i18n]').forEach(el => {
            const key = el.getAttribute('data-i18n');
            if (translations[lang] && translations[lang][key]) {
                el.innerHTML = translations[lang][key];
            }
        });
        document.documentElement.setAttribute('lang', lang);
        localStorage.setItem('language', lang);
    }

    if (langSelector) {
        langSelector.addEventListener('change', (e) => {
            setLanguage(e.target.value);
        });
    }

    loadTranslations();

    // --- Theme Management ---
    const themeToggle = document.getElementById('theme-toggle');
    const body = document.body;
    
    const currentTheme = localStorage.getItem('theme');
    if (currentTheme === 'light') body.classList.add('light-mode');

    themeToggle.addEventListener('click', () => {
        body.classList.toggle('light-mode');
        localStorage.setItem('theme', body.classList.contains('light-mode') ? 'light' : 'dark');
    });

    // --- Cinematic Intro ---
    window.addEventListener('load', () => {
        const intro = document.getElementById('intro-overlay');
        setTimeout(() => {
            if (intro) {
                intro.classList.add('fade-out');
                setTimeout(() => {
                    intro.style.display = 'none';
                    document.body.classList.remove('no-scroll');
                    // Initialize scroll observer after intro
                    initScrollObserver();
                }, 1000);
            }
        }, 2000);
    });

    // --- Header Scroll Effect ---
    const header = document.querySelector('.header');
    window.addEventListener('scroll', () => {
        if (window.scrollY > 50) header.classList.add('scrolled');
        else header.classList.remove('scrolled');
    });

    // --- Mobile Menu Toggle ---
    const mobileMenuBtn = document.getElementById('mobile-menu-btn');
    const navLinks = document.querySelector('.nav-links');

    if (mobileMenuBtn && navLinks) {
        mobileMenuBtn.addEventListener('click', () => {
            navLinks.classList.toggle('active');
            const icon = mobileMenuBtn.querySelector('i');
            icon.setAttribute('data-lucide', navLinks.classList.contains('active') ? 'x' : 'menu');
            lucide.createIcons();
        });

        navLinks.querySelectorAll('a').forEach(link => {
            link.addEventListener('click', () => {
                navLinks.classList.remove('active');
                mobileMenuBtn.querySelector('i').setAttribute('data-lucide', 'menu');
                lucide.createIcons();
            });
        });
    }

    // --- Scroll Animations ---
    function initScrollObserver() {
        const observerOptions = { threshold: 0.1, rootMargin: '0px 0px -50px 0px' };
        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) entry.target.classList.add('visible');
            });
        }, observerOptions);

        document.querySelectorAll('section, .feature-card, .price-card, .hero-content, .hero-mockup').forEach(el => {
            observer.observe(el);
        });
    }
});

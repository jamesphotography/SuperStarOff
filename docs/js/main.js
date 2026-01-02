// 导航栏滚动效果
let lastScrollY = window.scrollY;
const navbar = document.querySelector('.navbar');

window.addEventListener('scroll', () => {
    if (window.scrollY > 100) {
        navbar.style.background = 'rgba(10, 14, 39, 0.98)';
        navbar.style.boxShadow = '0 4px 20px rgba(0, 0, 0, 0.3)';
    } else {
        navbar.style.background = 'rgba(10, 14, 39, 0.95)';
        navbar.style.boxShadow = '0 4px 6px rgba(0, 0, 0, 0.1)';
    }
    lastScrollY = window.scrollY;
});

// 移动端导航菜单切换
const navToggle = document.querySelector('.nav-toggle');
const navMenu = document.querySelector('.nav-menu');

if (navToggle) {
    navToggle.addEventListener('click', () => {
        navMenu.classList.toggle('active');
        const icon = navToggle.querySelector('i');
        if (navMenu.classList.contains('active')) {
            icon.classList.remove('fa-bars');
            icon.classList.add('fa-times');
        } else {
            icon.classList.remove('fa-times');
            icon.classList.add('fa-bars');
        }
    });
}

// 点击导航链接关闭移动端菜单
const navLinks = document.querySelectorAll('.nav-menu a');
navLinks.forEach(link => {
    link.addEventListener('click', () => {
        if (window.innerWidth <= 768) {
            navMenu.classList.remove('active');
            const icon = navToggle.querySelector('i');
            icon.classList.remove('fa-times');
            icon.classList.add('fa-bars');
        }
    });
});

// 平滑滚动
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        const href = this.getAttribute('href');
        if (href === '#' || href === '#download-btn') return;

        e.preventDefault();
        const target = document.querySelector(href);
        if (target) {
            const offsetTop = target.offsetTop - 80;
            window.scrollTo({
                top: offsetTop,
                behavior: 'smooth'
            });
        }
    });
});

// 返回顶部按钮
const backToTopBtn = document.getElementById('back-to-top');

window.addEventListener('scroll', () => {
    if (window.scrollY > 500) {
        backToTopBtn.classList.add('show');
    } else {
        backToTopBtn.classList.remove('show');
    }
});

if (backToTopBtn) {
    backToTopBtn.addEventListener('click', () => {
        window.scrollTo({
            top: 0,
            behavior: 'smooth'
        });
    });
}

// 下载按钮点击统计（可选）
const downloadBtns = document.querySelectorAll('.btn-primary[target="_blank"]');
downloadBtns.forEach(btn => {
    btn.addEventListener('click', () => {
        const href = btn.getAttribute('href');
        if (href.includes('drive.google.com')) {
            console.log('用户点击了 Google Drive 下载');
        } else if (href.includes('pan.baidu.com')) {
            console.log('用户点击了百度网盘下载');
        }
        // 可以在这里添加统计代码，如 Google Analytics
    });
});

// 语言切换（预留功能）
const langSwitch = document.getElementById('lang-switch');
if (langSwitch) {
    langSwitch.addEventListener('click', (e) => {
        e.preventDefault();
        alert('🌐 English version is coming soon!\n英文版本即将推出！');
    });
}

// 添加滚动动画
const observerOptions = {
    threshold: 0.1,
    rootMargin: '0px 0px -100px 0px'
};

const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.style.opacity = '1';
            entry.target.style.transform = 'translateY(0)';
        }
    });
}, observerOptions);

// 观察需要动画的元素
const animateElements = document.querySelectorAll(
    '.feature-card, .perf-card, .download-card, .guide-step, .faq-item, .contact-card, .gallery-item'
);

animateElements.forEach(el => {
    el.style.opacity = '0';
    el.style.transform = 'translateY(30px)';
    el.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
    observer.observe(el);
});

// 性能数字倒计时动画
const animateCountdown = (element, target, duration = 2000) => {
    let current = target;
    const decrement = target / (duration / 50);

    element.textContent = target;

    const timer = setInterval(() => {
        current -= decrement;
        if (current <= 0) {
            current = 0;
            clearInterval(timer);
            // 倒计时完成后从0数到目标值
            setTimeout(() => {
                animateCountUp(element, target, 1000);
            }, 100);
        }
        element.textContent = Math.floor(current);
    }, 50);
};

// 正向计数动画
const animateCountUp = (element, target, duration = 1000) => {
    let current = 0;
    const increment = target / (duration / 16);

    const timer = setInterval(() => {
        current += increment;
        if (current >= target) {
            current = target;
            clearInterval(timer);
        }
        element.textContent = Math.floor(current);
    }, 16);
};

// 当性能卡片进入视野时触发倒计时动画
const perfObserver = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            const numberElement = entry.target.querySelector('.perf-number');
            if (numberElement && !numberElement.classList.contains('animated')) {
                numberElement.classList.add('animated');
                const target = parseInt(numberElement.textContent);
                if (!isNaN(target)) {
                    animateCountdown(numberElement, target, 2000);
                }
            }
        }
    });
}, observerOptions);

document.querySelectorAll('.perf-card').forEach(card => {
    perfObserver.observe(card);
});

// 复制下载链接（预留功能）
const copyToClipboard = (text) => {
    const textarea = document.createElement('textarea');
    textarea.value = text;
    textarea.style.position = 'fixed';
    textarea.style.opacity = '0';
    document.body.appendChild(textarea);
    textarea.select();
    document.execCommand('copy');
    document.body.removeChild(textarea);
};

// 添加键盘快捷键
document.addEventListener('keydown', (e) => {
    // Ctrl/Cmd + K 打开搜索（预留）
    if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
        e.preventDefault();
        // 可以添加搜索功能
    }

    // ESC 关闭移动端菜单
    if (e.key === 'Escape' && navMenu.classList.contains('active')) {
        navMenu.classList.remove('active');
        const icon = navToggle.querySelector('i');
        icon.classList.remove('fa-times');
        icon.classList.add('fa-bars');
    }
});

// 图片懒加载
if ('loading' in HTMLImageElement.prototype) {
    const images = document.querySelectorAll('img[loading="lazy"]');
    images.forEach(img => {
        img.src = img.dataset.src;
    });
} else {
    // 降级方案：使用 Intersection Observer
    const imageObserver = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const img = entry.target;
                if (img.dataset.src) {
                    img.src = img.dataset.src;
                    imageObserver.unobserve(img);
                }
            }
        });
    });

    document.querySelectorAll('img[data-src]').forEach(img => {
        imageObserver.observe(img);
    });
}

// 页面加载完成后的初始化
window.addEventListener('load', () => {
    // 添加加载完成的类
    document.body.classList.add('loaded');

    // 控制台输出
    console.log('%c慧眼去星 SuperStarOff', 'font-size: 20px; font-weight: bold; color: #4a90e2;');
    console.log('%cAI驱动的专业天文图像星点去除工具', 'font-size: 14px; color: #b8c1ec;');
    console.log('%cGitHub: https://github.com/jamesphotography/SuperStarOff', 'font-size: 12px; color: #7b68ee;');
});

// 检测暗色模式偏好（预留）
const prefersDarkScheme = window.matchMedia('(prefers-color-scheme: dark)');
if (prefersDarkScheme.matches) {
    // 已经是暗色主题
    document.body.classList.add('dark-theme');
}

// 监听系统主题变化
prefersDarkScheme.addEventListener('change', (e) => {
    if (e.matches) {
        document.body.classList.add('dark-theme');
    } else {
        document.body.classList.remove('dark-theme');
    }
});

// 添加页面可见性检测
document.addEventListener('visibilitychange', () => {
    if (document.hidden) {
        // 页面不可见时暂停动画等
        console.log('Page hidden');
    } else {
        // 页面可见时恢复
        console.log('Page visible');
    }
});

// 错误处理
window.addEventListener('error', (e) => {
    console.error('发生错误:', e.message);
});

// 性能监控（开发用）
if (window.performance && window.performance.timing) {
    window.addEventListener('load', () => {
        setTimeout(() => {
            const perfData = window.performance.timing;
            const pageLoadTime = perfData.loadEventEnd - perfData.navigationStart;
            console.log(`页面加载时间: ${pageLoadTime}ms`);
        }, 0);
    });
}

// 图片灯箱功能
function openLightbox(imageSrc, caption) {
    const lightbox = document.getElementById('lightbox');
    const lightboxImg = document.getElementById('lightbox-img');
    const lightboxCaption = document.getElementById('lightbox-caption');

    lightbox.classList.add('active');
    lightboxImg.src = imageSrc;
    lightboxCaption.textContent = caption;

    // 防止背景滚动
    document.body.style.overflow = 'hidden';
}

function closeLightbox() {
    const lightbox = document.getElementById('lightbox');
    lightbox.classList.remove('active');

    // 恢复背景滚动
    document.body.style.overflow = '';
}

// ESC 键关闭灯箱
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        const lightbox = document.getElementById('lightbox');
        if (lightbox.classList.contains('active')) {
            closeLightbox();
        }
    }
});

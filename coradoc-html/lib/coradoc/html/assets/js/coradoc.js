/**
 * Coradoc Interactive Features
 * Modern JavaScript for enhanced HTML output
 * Version: 2.0
 */

(function() {
  'use strict';

  // ========================================================================
  // Theme Management
  // ========================================================================

  const ThemeManager = {
    STORAGE_KEY: 'coradoc-theme',
    THEMES: ['light', 'dark'],

    init() {
      this.applyInitialTheme();
      this.attachToggleListener();
      this.listenToSystemChanges();
    },

    detectInitialTheme() {
      const stored = localStorage.getItem(this.STORAGE_KEY);
      if (stored && this.THEMES.includes(stored)) {
        return stored;
      }
      return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
    },

    applyInitialTheme() {
      const theme = this.detectInitialTheme();
      this.applyTheme(theme, false);
    },

    async applyTheme(theme, animate = true) {
      if (!this.THEMES.includes(theme)) return;

      const applyThemeChange = () => {
        document.documentElement.setAttribute('data-theme', theme);
        localStorage.setItem(this.STORAGE_KEY, theme);
        this.updateToggleButton(theme);
      };

      if (animate && document.startViewTransition) {
        await document.startViewTransition(applyThemeChange).finished;
      } else {
        applyThemeChange();
      }
    },

    toggleTheme() {
      const current = document.documentElement.getAttribute('data-theme') || 'light';
      const next = current === 'light' ? 'dark' : 'light';
      this.applyTheme(next);
    },

    attachToggleListener() {
      const button = document.getElementById('theme-toggle');
      if (button) {
        // Update initial icon based on current theme
        const currentTheme = this.detectInitialTheme();
        const icon = button.querySelector('.theme-toggle-icon');
        if (icon) {
          icon.textContent = this.getIconForTheme(currentTheme);
        }
        // Attach click event listener
        button.addEventListener('click', () => this.toggleTheme());
      }
    },

    updateToggleButton(theme) {
      const button = document.getElementById('theme-toggle');
      if (button) {
        const icon = button.querySelector('.theme-toggle-icon');
        if (icon) {
          icon.textContent = this.getIconForTheme(theme);
        }
      }
    },

    getIconForTheme(theme) {
      return theme === 'dark' ? '☀️' : '🌙';
    },

    listenToSystemChanges() {
      const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
      mediaQuery.addEventListener('change', (e) => {
        if (!localStorage.getItem(this.STORAGE_KEY)) {
          this.applyTheme(e.matches ? 'dark' : 'light');
        }
      });
    }
  };

  // ========================================================================
  // Interactive Table of Contents
  // ========================================================================

  const TOCManager = {
    toc: null,
    sections: [],
    observer: null,

    init() {
      this.toc = document.getElementById('toc');
      if (!this.toc) return;

      this.findSections();
      this.setupIntersectionObserver();
      this.setupSmoothScrolling();
      this.setupCollapsible();
    },

    findSections() {
      const selectors = ['section[id]', 'h2[id]', 'h3[id]', 'h4[id]', 'h5[id]', 'h6[id]'];
      this.sections = Array.from(document.querySelectorAll(selectors.join(', ')));
    },

    setupIntersectionObserver() {
      if (!('IntersectionObserver' in window)) return;

      const options = {
        rootMargin: '-80px 0px -80% 0px',
        threshold: 0
      };

      this.observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
          if (entry.isIntersecting) {
            this.highlightTOCItem(entry.target.id);
          }
        });
      }, options);

      this.sections.forEach(section => this.observer.observe(section));
    },

    highlightTOCItem(id) {
      if (!this.toc) return;

      const links = this.toc.querySelectorAll('a');
      links.forEach(link => {
        const isActive = link.getAttribute('href') === `#${id}`;
        link.classList.toggle('active', isActive);

        if (isActive) {
          link.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
        }
      });
    },

    setupSmoothScrolling() {
      if (!this.toc) return;

      this.toc.querySelectorAll('a[href^="#"]').forEach(link => {
        link.addEventListener('click', (e) => {
          e.preventDefault();
          const targetId = link.getAttribute('href').slice(1);
          const target = document.getElementById(targetId);

          if (target) {
            target.scrollIntoView({ behavior: 'smooth', block: 'start' });
            history.pushState(null, '', `#${targetId}`);
          }
        });
      });
    },

    setupCollapsible() {
      if (!this.toc) return;

      const nestedLists = this.toc.querySelectorAll('ul ul');
      nestedLists.forEach(list => {
        const parentLi = list.parentElement;
        const parentLink = parentLi.querySelector('a');

        if (parentLink) {
          const toggle = document.createElement('span');
          toggle.className = 'toc-toggle';
          toggle.textContent = '▼';
          toggle.style.cursor = 'pointer';
          toggle.style.marginRight = '0.5em';
          toggle.style.fontSize = '0.8em';
          toggle.style.transition = 'transform 0.2s';

          toggle.addEventListener('click', (e) => {
            e.stopPropagation();
            list.style.display = list.style.display === 'none' ? '' : 'none';
            toggle.style.transform = list.style.display === 'none' ? 'rotate(-90deg)' : '';
          });

          parentLink.insertBefore(toggle, parentLink.firstChild);
        }
      });
    }
  };

  // ========================================================================
  // Reading Progress Indicator
  // ========================================================================

  const ProgressIndicator = {
    init() {
      this.createProgressBar();
      this.updateProgress();
      window.addEventListener('scroll', () => this.updateProgress(), { passive: true });
    },

    createProgressBar() {
      const progress = document.createElement('div');
      progress.id = 'reading-progress';
      progress.style.cssText = `
        position: fixed;
        top: 0;
        left: 0;
        width: 0%;
        height: 3px;
        background: linear-gradient(90deg, #00ff9f, #00d9ff);
        z-index: 9999;
        transition: width 0.1s ease-out;
      `;
      document.body.appendChild(progress);
    },

    updateProgress() {
      const progress = document.getElementById('reading-progress');
      if (!progress) return;

      const windowHeight = window.innerHeight;
      const documentHeight = document.documentElement.scrollHeight - windowHeight;
      const scrolled = window.scrollY;
      const percentage = (scrolled / documentHeight) * 100;

      progress.style.width = `${Math.min(percentage, 100)}%`;
    }
  };

  // ========================================================================
  // Code Block Enhancements
  // ========================================================================

  const CodeBlockManager = {
    init() {
      this.addCopyButtons();
      this.addLineNumbers();
    },

    addCopyButtons() {
      document.querySelectorAll('pre').forEach(pre => {
        const button = document.createElement('button');
        button.className = 'copy-button';
        button.textContent = 'Copy';
        button.style.cssText = `
          position: absolute;
          top: 0.5rem;
          right: 0.5rem;
          padding: 0.25rem 0.5rem;
          font-size: 0.75rem;
          background: rgba(255, 255, 255, 0.1);
          border: 1px solid rgba(255, 255, 255, 0.2);
          border-radius: 4px;
          cursor: pointer;
          opacity: 0;
          transition: opacity 0.2s;
        `;

        pre.style.position = 'relative';
        pre.addEventListener('mouseenter', () => button.style.opacity = '1');
        pre.addEventListener('mouseleave', () => button.style.opacity = '0');

        button.addEventListener('click', async () => {
          const code = pre.querySelector('code')?.textContent || pre.textContent;
          try {
            await navigator.clipboard.writeText(code);
            button.textContent = 'Copied!';
            setTimeout(() => button.textContent = 'Copy', 2000);
          } catch (err) {
            button.textContent = 'Failed';
            setTimeout(() => button.textContent = 'Copy', 2000);
          }
        });

        pre.appendChild(button);
      });
    },

    addLineNumbers() {
      document.querySelectorAll('pre.line-numbers code').forEach(code => {
        const lines = code.textContent.split('\n');
        const lineNumbers = lines.map((_, i) => i + 1).join('\n');

        const numbersEl = document.createElement('span');
        numbersEl.className = 'line-numbers-rows';
        numbersEl.textContent = lineNumbers;
        numbersEl.style.cssText = `
          position: absolute;
          left: 0;
          top: 0;
          padding: 1rem 0.5rem;
          text-align: right;
          user-select: none;
          opacity: 0.5;
          font-family: monospace;
        `;

        code.parentElement.style.paddingLeft = '3rem';
        code.parentElement.insertBefore(numbersEl, code);
      });
    }
  };

  // ========================================================================
  // Keyboard Shortcuts
  // ========================================================================

  const KeyboardShortcuts = {
    init() {
      document.addEventListener('keydown', (e) => {
        if (e.ctrlKey || e.metaKey) {
          switch(e.key) {
            case 'd':
              e.preventDefault();
              ThemeManager.toggleTheme();
              break;
          }
        }
      });
    }
  };

  // ========================================================================
  // Lazy Loading Images
  // ========================================================================

  const LazyLoader = {
    init() {
      if (!('IntersectionObserver' in window)) return;

      const images = document.querySelectorAll('img[data-src]');
      const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
          if (entry.isIntersecting) {
            const img = entry.target;
            img.src = img.dataset.src;
            img.removeAttribute('data-src');
            observer.unobserve(img);
          }
        });
      });

      images.forEach(img => observer.observe(img));
    }
  };

  // ========================================================================
  // Initialize All Features
  // ========================================================================

  function initialize() {
    // Wait for DOM to be ready
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', initializeFeatures);
    } else {
      initializeFeatures();
    }
  }

  function initializeFeatures() {
    ThemeManager.init();
    TOCManager.init();
    ProgressIndicator.init();
    CodeBlockManager.init();
    KeyboardShortcuts.init();
    LazyLoader.init();
  }

  // Start initialization
  initialize();

})();

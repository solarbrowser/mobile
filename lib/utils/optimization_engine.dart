import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class OptimizationEngine {
  static const int MAX_ACTIVE_TABS = 5;
  static const Duration TAB_SUSPEND_TIMEOUT = Duration(minutes: 5);
  
  final WebViewController? controller;
  final Map<String, Timer> _tabTimers = {};
  final Map<String, bool> _suspendedTabs = {};

  // Regular constructor
  OptimizationEngine([this.controller]);

  // Initialize optimization engine
  Future<void> initialize() async {
    if (controller != null) {
      await _injectOptimizationScripts();
      _setupTabManagement();
    }
  }

  // Inject core optimization scripts
  Future<void> _injectOptimizationScripts() async {
    if (controller == null) return;
    
    await controller!.runJavaScript('''
      // Core optimization script
      (() => {
        // Viewport optimization
        class ViewportOptimizer {
          constructor() {
            this.observer = null;
            this.visibleElements = new Set();
            this.setupIntersectionObserver();
            this.setupMutationObserver();
          }

          setupIntersectionObserver() {
            // Enhanced intersection observer with priority loading
            this.observer = new IntersectionObserver((entries) => {
              entries.forEach(entry => {
                if (entry.isIntersecting) {
                  this.visibleElements.add(entry.target);
                  // Calculate priority based on viewport position
                  const priority = this.calculatePriority(entry);
                  this.optimizeElement(entry.target, priority);
                } else {
                  this.visibleElements.delete(entry.target);
                  this.deoptimizeElement(entry.target);
                }
              });
            }, {
              rootMargin: '200px 0px', // Increased margin for smoother loading
              threshold: [0, 0.1, 0.5, 1.0] // Multiple thresholds for better control
            });

            // Observe all elements with priority
            document.querySelectorAll('*').forEach(el => {
              if (this.shouldObserve(el)) {
                this.observer.observe(el);
              }
            });
          }

          setupMutationObserver() {
            new MutationObserver((mutations) => {
              mutations.forEach(mutation => {
                mutation.addedNodes.forEach(node => {
                  if (node.nodeType === 1) {
                    this.observer.observe(node);
                    node.querySelectorAll('*').forEach(el => this.observer.observe(el));
                  }
                });
              });
            }).observe(document.body, {
              childList: true,
              subtree: true
            });
          }

          calculatePriority(entry) {
            const viewportHeight = window.innerHeight;
            const elementTop = entry.boundingClientRect.top;
            
            // Higher priority for elements closer to viewport center
            const distanceFromCenter = Math.abs(elementTop - viewportHeight / 2);
            const priority = 1 - (distanceFromCenter / viewportHeight);
            
            return Math.max(0, Math.min(1, priority));
          }

          shouldObserve(element) {
            // Only observe elements that impact performance
            return element.tagName === 'IMG' ||
                   element.tagName === 'VIDEO' ||
                   element.tagName === 'IFRAME' ||
                   element.classList.contains('animate') ||
                   window.getComputedStyle(element).willChange !== 'auto';
          }

          optimizeElement(element, priority) {
            if (element instanceof HTMLImageElement) {
              this.optimizeImage(element);
            } else if (element instanceof HTMLVideoElement) {
              this.optimizeVideo(element);
            }

            // Apply hardware acceleration based on priority
            if (priority > 0.8) {
              element.style.transform = 'translateZ(0)';
              element.style.willChange = 'transform';
              element.style.backfaceVisibility = 'hidden';
            } else {
              element.style.willChange = 'auto';
            }

            // Optimize animations
            if (element.classList.contains('animate')) {
              this.optimizeAnimation(element, priority);
            }
          }

          optimizeImage(img) {
            // Get device pixel ratio and viewport size
            const dpr = window.devicePixelRatio || 1;
            const viewportWidth = window.innerWidth;
            const viewportHeight = window.innerHeight;

            // Calculate optimal size
            const maxWidth = viewportWidth * dpr;
            const maxHeight = viewportHeight * dpr;

            // Only load optimized version if original is larger
            if (img.naturalWidth > maxWidth || img.naturalHeight > maxHeight) {
              const originalSrc = img.src;
              img.src = this.getOptimizedImageUrl(originalSrc, maxWidth, maxHeight);
            }

            // Apply advanced image optimizations
            img.loading = 'lazy';
            img.decoding = 'async';
            img.fetchPriority = 'low';
            
            // Add LQIP (Low Quality Image Placeholder)
            if (!img.dataset.lqip) {
              const canvas = document.createElement('canvas');
              const ctx = canvas.getContext('2d');
              canvas.width = img.width / 10;
              canvas.height = img.height / 10;
              ctx.filter = 'blur(5px)';
              ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
              img.dataset.lqip = canvas.toDataURL();
              img.style.backgroundImage = 'url(' + img.dataset.lqip + ')';
              img.style.backgroundSize = 'cover';
              img.style.backgroundPosition = 'center';
            }

            // Add connection-aware loading
            if ('connection' in navigator) {
              const connection = navigator.connection;
              if (connection.saveData) {
                img.loading = 'lazy';
                img.fetchPriority = 'low';
              } else if (connection.effectiveType === '4g') {
                img.fetchPriority = 'high';
              }
            }

            // Add WebP support check and conversion
            if ('createImageBitmap' in window) {
              fetch(img.src)
                .then(response => response.blob())
                .then(blob => {
                  createImageBitmap(blob)
                    .then(bitmap => {
                      const canvas = document.createElement('canvas');
                      canvas.width = bitmap.width;
                      canvas.height = bitmap.height;
                      const ctx = canvas.getContext('2d');
                      ctx.drawImage(bitmap, 0, 0);
                      img.src = canvas.toDataURL('image/webp', 0.8);
                    });
                });
            }
          }

          optimizeVideo(video) {
            video.preload = 'metadata';
            video.loading = 'lazy';
          }

          getOptimizedImageUrl(originalUrl, maxWidth, maxHeight) {
            // Add image optimization parameters to URL
            return 'https://imageopt.com/resize?url=' + encodeURIComponent(originalUrl) + '&w=' + maxWidth + '&h=' + maxHeight;
          }

          optimizeAnimation(element, priority) {
            // Reduce animation complexity for low priority elements
            if (priority < 0.5) {
              element.style.animationDuration = '0.5s';
              element.style.animationTimingFunction = 'linear';
            }
            
            // Use requestAnimationFrame for smooth animations
            let lastKnownScrollPosition = window.scrollY;
            let ticking = false;

            document.addEventListener('scroll', () => {
              lastKnownScrollPosition = window.scrollY;
              if (!ticking) {
                window.requestAnimationFrame(() => {
                  this.updateAnimation(element, lastKnownScrollPosition);
                  ticking = false;
                });
                ticking = true;
              }
            });
          }

          updateAnimation(element, scrollPos) {
            // Optimize animation based on scroll position
            const rect = element.getBoundingClientRect();
            const viewportHeight = window.innerHeight;
            
            if (rect.top < viewportHeight && rect.bottom > 0) {
              const progress = (viewportHeight - rect.top) / viewportHeight;
              element.style.opacity = Math.min(1, Math.max(0.3, progress));
            }
          }

          deoptimizeElement(element) {
            if (!this.visibleElements.has(element)) {
              element.style.willChange = 'auto';
              if (element instanceof HTMLMediaElement) {
                element.pause();
              }
            }
          }
        }

        // Initialize viewport optimizer
        window.viewportOptimizer = new ViewportOptimizer();

        // RAM Management
        class RAMOptimizer {
          constructor() {
            this.gcInterval = 30000;
            this.memoryLimit = 0.8;
            this.setupPeriodicGC();
            this.setupMemoryMonitoring();
          }

          setupMemoryMonitoring() {
            // Monitor memory usage continuously
            setInterval(() => {
              if (window.performance && window.performance.memory) {
                const usage = window.performance.memory.usedJSHeapSize / 
                            window.performance.memory.jsHeapSizeLimit;
                
                if (usage > this.memoryLimit) {
                  this.aggressiveCleanup();
                } else if (usage > this.memoryLimit * 0.7) {
                  this.clearCaches();
                }
              }
            }, 5000);
          }

          aggressiveCleanup() {
            this.clearCaches();
            
            // Clear DOM elements not in viewport
            document.querySelectorAll('*').forEach(el => {
              if (!window.viewportOptimizer.visibleElements.has(el)) {
                if (el instanceof HTMLImageElement) {
                  el.src = '';
                  el.srcset = '';
                } else if (el instanceof HTMLVideoElement) {
                  el.pause();
                  el.src = '';
                  el.load();
                } else if (el instanceof HTMLIFrameElement) {
                  el.src = 'about:blank';
                }
              }
            });

            // Clear unused event listeners
            this.clearEventListeners();
            
            // Force garbage collection if available
            if (window.gc) {
              try {
                window.gc();
              } catch (e) {}
            }
          }

          clearEventListeners() {
            const elements = document.querySelectorAll('*');
            elements.forEach(el => {
              const clone = el.cloneNode(true);
              el.parentNode?.replaceChild(clone, el);
            });
          }

          setupPeriodicGC() {
            setInterval(() => {
              this.forceGC();
              this.optimizeDOM();
            }, this.gcInterval);
          }

          optimizeDOM() {
            // Remove duplicate event listeners
            this.clearEventListeners();

            // Remove hidden elements from DOM
            const elements = document.querySelectorAll('*');
            elements.forEach(el => {
              if (getComputedStyle(el).display === 'none' || 
                  getComputedStyle(el).visibility === 'hidden') {
                el.remove();
              }
            });

            // Optimize CSS animations
            document.querySelectorAll('.animate').forEach(el => {
              if (!window.viewportOptimizer.visibleElements.has(el)) {
                el.style.animationPlayState = 'paused';
              }
            });

            // Debounce scroll and resize events
            if (!window._optimizedEvents) {
              window._optimizedEvents = true;
              const debounce = (fn, delay) => {
                let timer = null;
                return function (...args) {
                  if (timer) clearTimeout(timer);
                  timer = setTimeout(() => {
                    fn.apply(this, args);
                    timer = null;
                  }, delay);
                };
              };

              const originalAddEventListener = window.addEventListener;
              window.addEventListener = function (type, fn, options) {
                if (type === 'scroll' || type === 'resize') {
                  originalAddEventListener.call(this, type, debounce(fn, 100), options);
                } else {
                  originalAddEventListener.call(this, type, fn, options);
                }
              };
            }

            // Use passive event listeners where possible
            document.addEventListener('touchstart', () => {}, { passive: true });
            document.addEventListener('touchmove', () => {}, { passive: true });
            document.addEventListener('wheel', () => {}, { passive: true });

            // Optimize font loading
            if ('fonts' in document) {
              document.fonts.ready.then(() => {
                document.documentElement.classList.add('fonts-loaded');
              });
            }

            // Use requestIdleCallback for non-critical operations
            if ('requestIdleCallback' in window) {
              requestIdleCallback(() => {
                this.optimizeNonCriticalElements();
              });
            }
          }

          optimizeNonCriticalElements() {
            // Defer loading of non-critical images
            document.querySelectorAll('img[data-src]').forEach(img => {
              if (!window.viewportOptimizer.visibleElements.has(img)) {
                const observer = new IntersectionObserver(entries => {
                  entries.forEach(entry => {
                    if (entry.isIntersecting) {
                      img.src = img.dataset.src;
                      observer.unobserve(img);
                    }
                  });
                });
                observer.observe(img);
              }
            });

            // Optimize iframes
            document.querySelectorAll('iframe').forEach(iframe => {
              if (!window.viewportOptimizer.visibleElements.has(iframe)) {
                iframe.loading = 'lazy';
                if (iframe.src.includes('youtube.com')) {
                  iframe.src = iframe.src.replace('youtube.com', 'youtube-nocookie.com');
                }
              }
            });
          }

          forceGC() {
            // Clear unused objects
            if (window.performance && window.performance.memory) {
              if (window.performance.memory.usedJSHeapSize > 
                  window.performance.memory.jsHeapSizeLimit * 0.8) {
                // Memory usage is high, clear caches
                this.clearCaches();
              }
            }
          }

          clearCaches() {
            // Clear image cache
            const images = document.getElementsByTagName('img');
            for (let img of images) {
              if (!window.viewportOptimizer.visibleElements.has(img)) {
                img.src = '';
              }
            }

            // Clear video cache
            const videos = document.getElementsByTagName('video');
            for (let video of videos) {
              if (!window.viewportOptimizer.visibleElements.has(video)) {
                video.pause();
                video.removeAttribute('src');
                video.load();
              }
            }

            // Clear other caches
            if ('caches' in window) {
              caches.keys().then(names => {
                names.forEach(name => {
                  caches.delete(name);
                });
              });
            }
          }
        }

        // Initialize RAM optimizer
        window.ramOptimizer = new RAMOptimizer();

        // ADRCMV Extension Handler
        class ADRCMVHandler {
          constructor() {
            this.setupMutationObserver();
          }

          setupMutationObserver() {
            new MutationObserver((mutations) => {
              mutations.forEach(mutation => {
                mutation.addedNodes.forEach(node => {
                  if (node.nodeType === 1) {
                    this.processNode(node);
                  }
                });
              });
            }).observe(document.body, {
              childList: true,
              subtree: true
            });
          }

          processNode(node) {
            // Remove unnecessary elements
            const unnecessarySelectors = [
              'script:not([type="application/json"])',
              'link[rel="prefetch"]',
              'link[rel="prerender"]',
              'style:not([data-critical])',
              'iframe:not([data-critical])',
              'noscript'
            ];

            unnecessarySelectors.forEach(selector => {
              if (node.matches && node.matches(selector)) {
                node.remove();
              }
            });

            // Optimize remaining elements
            if (node instanceof HTMLImageElement) {
              window.viewportOptimizer.optimizeImage(node);
            } else if (node instanceof HTMLVideoElement) {
              window.viewportOptimizer.optimizeVideo(node);
            }
          }

          static processADRCMV(content) {
            // Process .adrcmv file content
            const doc = new DOMParser().parseFromString(content, 'text/html');
            
            // Remove unnecessary elements
            const unnecessarySelectors = [
              'script:not([type="application/json"])',
              'link[rel="prefetch"]',
              'link[rel="prerender"]',
              'style:not([data-critical])',
              'iframe:not([data-critical])',
              'noscript'
            ];

            unnecessarySelectors.forEach(selector => {
              doc.querySelectorAll(selector).forEach(el => el.remove());
            });

            // Optimize images
            doc.querySelectorAll('img').forEach(img => {
              img.loading = 'lazy';
              img.decoding = 'async';
            });

            // Optimize videos
            doc.querySelectorAll('video').forEach(video => {
              video.preload = 'metadata';
              video.loading = 'lazy';
            });

            return doc.documentElement.outerHTML;
          }
        }

        // Initialize ADRCMV handler
        window.adrcmvHandler = new ADRCMVHandler();

        // Image optimization
        class ImageOptimizer {
          constructor() {
            this.observer = new IntersectionObserver(this.handleIntersection.bind(this), {
              rootMargin: '50px 0px',
              threshold: 0.01
            });
            this.setupMutationObserver();
          }

          setupMutationObserver() {
            new MutationObserver((mutations) => {
              mutations.forEach(mutation => {
                mutation.addedNodes.forEach(node => {
                  if (node.nodeName === 'IMG') {
                    this.optimizeImage(node);
                  }
                });
              });
            }).observe(document.body, { 
              childList: true, 
              subtree: true 
            });
          }

          handleIntersection(entries) {
            entries.forEach(entry => {
              if (entry.isIntersecting && entry.target instanceof HTMLImageElement) {
                this.optimizeImage(entry.target);
              }
            });
          }

          optimizeImage(img) {
            if (img.hasAttribute('data-optimized')) return;
            
            const viewportWidth = window.innerWidth;
            const viewportHeight = window.innerHeight;
            const maxDimension = Math.max(480, Math.min(viewportWidth, viewportHeight));
            
            // Save original source
            if (!img.hasAttribute('data-original-src')) {
              img.setAttribute('data-original-src', img.src);
            }

            // Set loading attribute for better performance
            img.loading = 'lazy';
            img.decoding = 'async';

            // Optimize image dimensions
            if (img.naturalWidth > maxDimension || img.naturalHeight > maxDimension) {
              const aspectRatio = img.naturalWidth / img.naturalHeight;
              let newWidth, newHeight;

              if (aspectRatio > 1) {
                newWidth = maxDimension;
                newHeight = maxDimension / aspectRatio;
              } else {
                newHeight = maxDimension;
                newWidth = maxDimension * aspectRatio;
              }

              img.style.width = newWidth + 'px';
              img.style.height = newHeight + 'px';
              
              // Create optimized version using canvas
              const canvas = document.createElement('canvas');
              const ctx = canvas.getContext('2d');
              canvas.width = newWidth;
              canvas.height = newHeight;
              
              // Draw image with smoothing
              ctx.imageSmoothingEnabled = true;
              ctx.imageSmoothingQuality = 'high';
              ctx.drawImage(img, 0, 0, newWidth, newHeight);
              
              // Convert to WebP if supported
              if (canvas.toDataURL('image/webp').indexOf('data:image/webp') === 0) {
                img.src = canvas.toDataURL('image/webp', 0.8);
              } else {
                img.src = canvas.toDataURL('image/jpeg', 0.8);
              }
            }

            img.setAttribute('data-optimized', 'true');
          }

          observe(img) {
            this.observer.observe(img);
          }
        }

        // Initialize image optimizer
        window.imageOptimizer = new ImageOptimizer();

        // Optimize all existing images
        document.querySelectorAll('img').forEach(img => {
          window.imageOptimizer.optimizeImage(img);
        });
      })();
    ''');
  }

  // Setup tab management
  void _setupTabManagement() {
    // Start timer for current tab
    _startTabTimer(controller?.hashCode.toString() ?? '');
  }

  // Start timer for tab suspension
  void _startTabTimer(String tabId) {
    _tabTimers[tabId]?.cancel();
    _tabTimers[tabId] = Timer(TAB_SUSPEND_TIMEOUT, () => _suspendTab(tabId));
  }

  // Suspend inactive tab
  Future<void> _suspendTab(String tabId) async {
    if (!_suspendedTabs.containsKey(tabId)) {
      _suspendedTabs[tabId] = true;
      if (controller != null) {
        await controller!.runJavaScript('''
          // Suspend tab resources
          document.querySelectorAll('img, video, iframe').forEach(el => {
            if (el instanceof HTMLMediaElement) {
              el.pause();
            }
            el.src = '';
          });
          window.ramOptimizer.clearCaches();
        ''');
      }
    }
  }

  // Resume suspended tab
  Future<void> resumeTab(String tabId) async {
    if (_suspendedTabs[tabId] == true) {
      _suspendedTabs[tabId] = false;
      if (controller != null) {
        await controller!.reload();
      }
      _startTabTimer(tabId);
    }
  }

  // Process .adrcmv file
  Future<String> processADRCMVFile(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final content = utf8.decode(response.bodyBytes);
        
        // Process content through JavaScript ADRCMV handler
        if (controller != null) {
          final processedContent = await controller!.runJavaScriptReturningResult(
            'ADRCMVHandler.processADRCMV(`${content}`)'
          );
          return processedContent.toString();
        }
        return content;
      }
      throw Exception('Failed to load ADRCMV file');
    } catch (e) {
      print('Error processing ADRCMV file: $e');
      rethrow;
    }
  }

  // Handle navigation to optimize page load
  Future<void> onPageStartLoad(String url) async {
    if (controller != null) {
      await controller!.runJavaScript('''
        // Initialize ViewportOptimizer
        window.ViewportOptimizer = class {
          constructor() {
            this.observer = null;
            this.init();
          }

          init() {
            try {
              // Wait for document to be ready
              if (document.readyState === 'loading') {
                document.addEventListener('DOMContentLoaded', () => this.setupObserver());
              } else {
                this.setupObserver();
              }
            } catch (e) {
              console.error('ViewportOptimizer init error:', e);
            }
          }

          setupObserver() {
            try {
              // Ensure we have a valid document body
              if (!document.body) return;
              
              this.observer = new MutationObserver((mutations) => {
                mutations.forEach((mutation) => {
                  if (mutation.type === 'childList') {
                    this.optimizeAddedNodes(mutation.addedNodes);
                  }
                });
              });

              this.observer.observe(document.body, {
                childList: true,
                subtree: true
              });

              // Initial optimization
              this.optimizeVisibleContent();
            } catch (e) {
              console.error('ViewportOptimizer setup error:', e);
            }
          }

          optimizeAddedNodes(nodes) {
            nodes.forEach(node => {
              if (node.nodeType === Node.ELEMENT_NODE) {
                this.optimizeElement(node);
              }
            });
          }

          optimizeElement(element) {
            if (element.tagName === 'IMG') {
              this.optimizeImage(element);
            } else if (element.tagName === 'VIDEO') {
              this.optimizeVideo(element);
            }
          }

          optimizeImage(img) {
            if (!img.loading) {
              img.loading = 'lazy';
            }
            if (!img.decoding) {
              img.decoding = 'async';
            }
          }

          optimizeVideo(video) {
            video.preload = 'metadata';
            video.autoplay = false;
          }

          optimizeVisibleContent() {
            const elements = document.querySelectorAll('img, video');
            elements.forEach(element => this.optimizeElement(element));
          }
        }

        // Initialize PerformanceOptimizer
        window.PerformanceOptimizer = class {
          constructor() {
            this.init();
          }

          init() {
            // Optimize favicons
            this.handleFavicons();
            
            // Optimize performance
            this.optimizePerformance();
            
            // Handle scroll performance
            this.setupScrollOptimization();
          }

          handleFavicons() {
            const links = document.querySelectorAll('link[rel*="icon"]');
            links.forEach(link => {
              const newLink = link.cloneNode();
              newLink.onerror = () => {
                // On error, try data URL fallback
                newLink.href = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';
              };
              link.parentNode.replaceChild(newLink, link);
            });
          }

          optimizePerformance() {
            // Optimize CSS animations
            this.optimizeCSSAnimations();
            
            // Optimize event listeners
            this.optimizeEventListeners();
            
            // Optimize DOM updates
            this.optimizeDOMUpdates();
          }

          optimizeCSSAnimations() {
            const style = document.createElement('style');
            style.textContent = `
              * {
                animation-duration: 0.001s !important;
                animation-delay: 0s !important;
                transition-duration: 0.001s !important;
              }
            `;
            document.head.appendChild(style);
            
            // Re-enable animations after initial load
            setTimeout(() => {
              document.head.removeChild(style);
            }, 1000);
          }

          optimizeEventListeners() {
            // Use passive event listeners
            const supportsPassive = false;
            try {
              window.addEventListener("test", null, { 
                get passive() { supportsPassive = true; return true; }
              });
            } catch(e) {}
            
            if (supportsPassive) {
              const wheelOpts = { passive: true };
              window.addEventListener('wheel', () => {}, wheelOpts);
              window.addEventListener('touchstart', () => {}, wheelOpts);
            }
          }

          optimizeDOMUpdates() {
            // Batch DOM updates
            if (window.requestAnimationFrame) {
              let scheduled = false;
              const updates = [];
              
              window.batchUpdate = (fn) => {
                updates.push(fn);
                if (!scheduled) {
                  scheduled = true;
                  requestAnimationFrame(() => {
                    const fns = updates.splice(0);
                    fns.forEach(f => f());
                    scheduled = false;
                  });
                }
              };
            }
          }

          setupScrollOptimization() {
            let ticking = false;
            window.addEventListener('scroll', () => {
              if (!ticking) {
                window.requestAnimationFrame(() => {
                  // Optimize visible elements
                  if (window.viewportOptimizer) {
                    window.viewportOptimizer.optimizeVisibleContent();
                  }
                  ticking = false;
                });
                ticking = true;
              }
            }, { passive: true });
          }
        }

        // Initialize optimizers
        window.viewportOptimizer = new ViewportOptimizer();
        window.performanceOptimizer = new PerformanceOptimizer();
      ''');
    }
  }

  // Handle page finish loading
  Future<void> onPageFinishLoad(String url) async {
    if (controller != null) {
      await controller!.runJavaScript('''
        try {
          if (window.viewportOptimizer) {
            window.viewportOptimizer.optimizeVisibleContent();
          }
        } catch (e) {
          console.error('Error optimizing content:', e);
        }
      ''');
    }
  }

  // Clean up resources
  void dispose() {
    _tabTimers.forEach((_, timer) => timer.cancel());
    _tabTimers.clear();
    _suspendedTabs.clear();
  }

  // Suspend tab
  Future<void> suspendTab(String tabId) async {
    await _suspendTab(tabId);
  }
} 
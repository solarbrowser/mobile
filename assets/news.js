// Solar Browser News System
// This file handles news rendering for the Solar Browser homepage

// Initialize news system when the document is loaded
document.addEventListener('DOMContentLoaded', function() {
  console.log('📰 News.js loaded and initialized');
  requestNewsFromFlutter();
});

// Request news data from Flutter
function requestNewsFromFlutter() {
  console.log('📰 Requesting news from Flutter');
  try {
    if (window.NewsRequester) {
      window.NewsRequester.postMessage('fetchNews');
      console.log('📰 News request sent to Flutter via NewsRequester');
    } else {
      console.log('📰 NewsRequester not available');
      showNewsError('News system not available');
    }
  } catch (e) {
    console.error('📰 Error requesting news:', e);
    showNewsError('Failed to request news');
  }
}

// Display news items
function displayNews(newsData) {
  console.log('📰 displayNews called with', newsData ? newsData.length : 0, 'items');
  
  // Get the news container
  const container = document.getElementById('newsContainer');
  if (!container) {
    console.error('📰 News container not found');
    return;
  }
  
  // Clear any existing content
  container.innerHTML = '';
  
  // Check if we have news data
  if (!newsData || newsData.length === 0) {
    container.innerHTML = '<div class="news-item"><div class="news-item-title">No news available</div><div class="news-item-summary">There are no news articles to display at this time.</div></div>';
    return;
  }
  
  // Add each news item to the container
  newsData.forEach(function(item, index) {
    console.log(`📰 Rendering news item ${index + 1}/${newsData.length}: ${item.title}`);
    
    // Create news item container
    const newsItem = document.createElement('div');
    newsItem.className = 'news-item';
    
    // Make the item clickable if it has a URL
    if (item.url) {
      newsItem.onclick = function() {
        console.log('📰 News item clicked, opening URL:', item.url);
        window.location.href = item.url;
      };
    }
    
    // Create cover image if available
    if (item.coverUrl) {
      console.log('📰 News item has cover image:', item.coverUrl);
      const image = document.createElement('img');
      image.className = 'news-item-image';
      image.src = item.coverUrl;
      image.alt = item.title;
      image.onerror = function() {
        console.log('📰 Failed to load image, removing element');
        this.style.display = 'none';
      };
      newsItem.appendChild(image);
    }
    
    // Create news title
    const title = document.createElement('div');
    title.className = 'news-item-title';
    title.textContent = item.title || 'Untitled News';
    newsItem.appendChild(title);
    
    // Create news content - use full content if available
    const content = document.createElement('div');
    content.className = 'news-item-summary';
    content.textContent = item.content || item.summary || '';
    newsItem.appendChild(content);
    
    // Create publication date
    const date = document.createElement('div');
    date.className = 'news-item-date';
    date.textContent = new Date(item.publishedAt || Date.now()).toLocaleDateString();
    newsItem.appendChild(date);
    
    // Add the complete news item to the container
    container.appendChild(newsItem);
  });
  
  console.log('📰 All news items rendered successfully');
}

// Show error message when news can't be loaded
function showNewsError(message) {
  console.log('📰 Showing news error:', message);
  
  const container = document.getElementById('newsContainer');
  if (container) {
    container.innerHTML = `
      <div class="news-item">
        <div class="news-item-title">Error loading news</div>
        <div class="news-item-summary">${message}</div>
        <button onclick="requestNewsFromFlutter()" class="news-retry-button">Try Again</button>
      </div>
    `;
  }
}

// Add some custom styling for news items
document.addEventListener('DOMContentLoaded', function() {
  const style = document.createElement('style');
  style.textContent = `
    .news-item-image {
      width: 100%;
      height: auto;
      border-radius: 8px;
      margin-bottom: 12px;
    }
    
    .news-item-summary {
      white-space: pre-wrap;
      max-height: none;
      overflow: visible;
    }
    
    .news-retry-button {
      background: #667eea;
      color: white;
      border: none;
      padding: 8px 16px;
      border-radius: 20px;
      margin-top: 10px;
      cursor: pointer;
    }
    
    .news-retry-button:hover {
      background: #5a6edb;
    }
  `;
  document.head.appendChild(style);
});

// Make functions globally available
window.displayNews = displayNews;
window.showNewsError = showNewsError;
window.requestNewsFromFlutter = requestNewsFromFlutter;

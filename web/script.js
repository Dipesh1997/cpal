// Global variables
let colors = {};
let filteredColors = {};
let favoriteColorNumbers = new Set();
let currentCategory = 'light';
let currentPrefix = 'All';
let loadedItemsCount = {
    light: 999999,
    medium: 999999,
    dark: 999999,
    opus: 20
};
let opusCategories = ['All'];
let categorizedOpusColors = {};
let isLoading = true;

// DOM Elements
const colorsGrid = document.getElementById('colors-grid');
const loadingIndicator = document.getElementById('loading-indicator');
const searchInput = document.getElementById('search-input');
const tabButtons = document.querySelectorAll('.tab-button');
const opusSubtabs = document.getElementById('opus-subtabs');
const colorDetailModal = document.getElementById('color-detail-modal');
const modalColorName = document.getElementById('modal-color-name');
const modalPageNumber = document.getElementById('modal-page-number');
const modalFavoriteButton = document.getElementById('modal-favorite-button');
const modalCloseButton = document.getElementById('modal-close-button');
const modalColorDisplay = document.getElementById('modal-color-display');
const modalColorNameDisplay = document.getElementById('modal-color-name-display');
const modalColorDetails = document.getElementById('modal-color-details');
const favoritesButton = document.getElementById('favorites-button');
const favoritesModal = document.getElementById('favorites-modal');
const favoritesCloseButton = document.getElementById('favorites-close-button');
const favoritesGrid = document.getElementById('favorites-grid');
const noFavorites = document.getElementById('no-favorites');

// Initialize the app
document.addEventListener('DOMContentLoaded', init);

async function init() {
    // Show splash screen
    const splashScreen = document.createElement('div');
    splashScreen.className = 'splash-screen';
    
    const iconImg = document.createElement('img');
    iconImg.src = 'assets/icon.png';
    iconImg.alt = 'Color Palette';
    
    const spinner = document.createElement('div');
    spinner.className = 'splash-spinner';
    
    splashScreen.appendChild(iconImg);
    splashScreen.appendChild(spinner);
    document.body.appendChild(splashScreen);
    
    showLoading();
    await Promise.all([
        loadColors(),
        loadFavorites()
    ]);
    setupEventListeners();
    hideLoading();
    renderColors();
    
    // Hide splash screen
    setTimeout(() => {
        splashScreen.style.opacity = '0';
        setTimeout(() => {
            document.body.removeChild(splashScreen);
        }, 500);
    }, 1000);
}

// Load colors from the external colors-data.js file
async function loadColors() {
    try {
        // colorsData is defined in colors-data.js and available globally
        colors = colorsData;
        console.log("Colors loaded successfully:", Object.keys(colors));
        
        // Pre-process colors
        filteredColors = Object.fromEntries(
            Object.entries(colors).map(([key, value]) => [key, [...value]])
        );
        
        // Categorize Opus colors
        categorizeOpusColors();
    } catch (error) {
        console.error('Error loading colors:', error);
        // Show error message to user
        colorsGrid.innerHTML = `<div class="no-content" style="grid-column: 1/-1">
            <p>Error loading colors. Please check console for details.</p>
            <p>${error.message}</p>
        </div>`;
    }
}

// Load favorites from localStorage
function loadFavorites() {
    const savedFavorites = localStorage.getItem('favorites');
    if (savedFavorites) {
        favoriteColorNumbers = new Set(JSON.parse(savedFavorites));
    }
}

// Save favorites to localStorage
function saveFavorites() {
    localStorage.setItem('favorites', JSON.stringify([...favoriteColorNumbers]));
}

// Toggle favorite status for a color
function toggleFavorite(colorNumber) {
    if (favoriteColorNumbers.has(colorNumber)) {
        favoriteColorNumbers.delete(colorNumber);
    } else {
        favoriteColorNumbers.add(colorNumber);
    }
    saveFavorites();
}

// Categorize Opus colors by first two letters of color number
function categorizeOpusColors() {
    const opusColors = filteredColors.opus || [];
    categorizedOpusColors = { 'All': opusColors };
    
    const prefixMap = {};
    
    for (const color of opusColors) {
        const colorNumber = color.number.toString();
        if (colorNumber.length >= 2) {
            const prefix = colorNumber.substring(0, 2).toUpperCase();
            
            if (!prefixMap[prefix]) {
                prefixMap[prefix] = [];
            }
            prefixMap[prefix].push(color);
        }
    }
    
    // Sort prefixes
    const sortedPrefixes = Object.keys(prefixMap).sort();
    for (const prefix of sortedPrefixes) {
        categorizedOpusColors[prefix] = prefixMap[prefix];
    }
    
    opusCategories = ['All', ...sortedPrefixes];
    
    // Create subtabs for Opus
    createOpusSubtabs();
}

// Create subtabs for Opus category
function createOpusSubtabs() {
    const subtabsContainer = document.querySelector('.subtabs');
    subtabsContainer.innerHTML = '';
    
    opusCategories.forEach(prefix => {
        const button = document.createElement('button');
        button.className = 'subtab-button';
        button.textContent = prefix;
        button.dataset.prefix = prefix;
        
        if (prefix === 'BB') {
            button.classList.add('active');
            currentPrefix = 'BB';
        } else if (prefix === 'All' && !opusCategories.includes('BB')) {
            button.classList.add('active');
        }
        
        button.addEventListener('click', () => {
            document.querySelectorAll('.subtab-button').forEach(btn => {
                btn.classList.remove('active');
            });
            button.classList.add('active');
            currentPrefix = prefix;
            renderColors();
        });
        
        subtabsContainer.appendChild(button);
    });
}

// Set up event listeners
function setupEventListeners() {
    // Tab buttons
    tabButtons.forEach(button => {
        button.addEventListener('click', () => {
            tabButtons.forEach(btn => btn.classList.remove('active'));
            button.classList.add('active');
            currentCategory = button.dataset.category;
            
            // Show/hide opus subtabs
            if (currentCategory === 'opus') {
                opusSubtabs.style.display = 'block';
                // Reset to only show first 20 items when switching to opus tab
                loadedItemsCount.opus = 20;
            } else {
                opusSubtabs.style.display = 'none';
            }
            
            renderColors();
        });
    });
    
    // Search input
    searchInput.addEventListener('input', () => {
        filterColors(searchInput.value);
    });
    
    // Scroll event for lazy loading
    window.addEventListener('scroll', () => {
        if (currentCategory === 'opus' && 
            window.innerHeight + window.scrollY >= document.body.offsetHeight - 100) {
            loadMoreItems();
        }
    });
    
    // Modal close button
    modalCloseButton.addEventListener('click', () => {
        colorDetailModal.style.display = 'none';
    });
    
    // Favorites button
    favoritesButton.addEventListener('click', () => {
        closeAllModals();
        renderFavorites();
        favoritesModal.style.display = 'block';
    });
    
    // Favorites close button
    favoritesCloseButton.addEventListener('click', () => {
        favoritesModal.style.display = 'none';
    });
    
    // Modal favorite button
    modalFavoriteButton.addEventListener('click', () => {
        const colorNumber = modalFavoriteButton.dataset.colorNumber;
        toggleFavorite(colorNumber);
        updateFavoriteButton(modalFavoriteButton, colorNumber);
        
        // Update the card in the grid if it exists
        const cards = document.querySelectorAll('.color-card');
        cards.forEach(card => {
            if (card.dataset.colorNumber === colorNumber) {
                updateCardFavoriteStatus(card, colorNumber);
            }
        });
    });
    
    // Close modals when clicking outside
    window.addEventListener('click', (event) => {
        if (event.target === colorDetailModal) {
            colorDetailModal.style.display = 'none';
        }
        if (event.target === favoritesModal) {
            favoritesModal.style.display = 'none';
        }
    });
    
    // Add ESC key handler to close modals
    document.addEventListener('keydown', (event) => {
        if (event.key === 'Escape') {
            closeAllModals();
        }
    });
}

// Filter colors based on search query
function filterColors(query) {
    if (!query) {
        // Reset to original colors
        filteredColors = Object.fromEntries(
            Object.entries(colors).map(([key, value]) => [key, [...value]])
        );
    } else {
        query = query.toLowerCase();
        
        filteredColors = Object.fromEntries(
            Object.entries(colors).map(([category, categoryColors]) => {
                const filtered = categoryColors.filter(color => 
                    color.name.toLowerCase().includes(query) || 
                    color.number.toString().toLowerCase().includes(query)
                );
                return [category, filtered];
            })
        );
    }
    
    // Recategorize Opus colors if needed
    if (currentCategory === 'opus') {
        categorizeOpusColors();
    }
    
    renderColors();
}

// Load more items for lazy loading
function loadMoreItems() {
    loadedItemsCount[currentCategory] += 20;
    renderColors();
}

// Render colors based on current category and filters
function renderColors() {
    colorsGrid.innerHTML = '';
    
    let colorsToRender = [];
    
    if (currentCategory === 'opus') {
        colorsToRender = categorizedOpusColors[currentPrefix] || [];
    } else {
        colorsToRender = filteredColors[currentCategory] || [];
    }
    
    if (colorsToRender.length === 0) {
        colorsGrid.innerHTML = '<div class="no-content"><p>No colors found</p></div>';
        return;
    }
    
    // Group colors by page
    const colorsByPage = {};
    for (const color of colorsToRender) {
        const page = color.page || 1;
        if (!colorsByPage[page]) {
            colorsByPage[page] = [];
        }
        colorsByPage[page].push(color);
    }
    
    // Sort pages
    const sortedPages = Object.keys(colorsByPage).map(Number).sort((a, b) => a - b);
    
    // Limit items for lazy loading
    let totalItems = 0;
    const pagesToShow = [];
    const itemsToShow = loadedItemsCount[currentCategory];
    
    for (const page of sortedPages) {
        const pageItemCount = colorsByPage[page].length;
        if (totalItems + pageItemCount <= itemsToShow) {
            pagesToShow.push(page);
            totalItems += pageItemCount;
        } else {
            if (totalItems < itemsToShow) {
                pagesToShow.push(page);
            }
            break;
        }
    }
    
    // Render pages
    for (const page of pagesToShow) {
        // Add page header
        const pageHeader = document.createElement('h3');
        pageHeader.className = 'page-header';
        pageHeader.textContent = `Page ${page}`;
        pageHeader.style.gridColumn = '1 / -1';
        colorsGrid.appendChild(pageHeader);
        
        // Add colors for this page
        let colorsToShow = colorsByPage[page];
        
        // For the last page, we might need to limit
        if (page === pagesToShow[pagesToShow.length - 1] && totalItems > itemsToShow) {
            const remainingItems = itemsToShow - (totalItems - colorsToShow.length);
            colorsToShow = colorsToShow.slice(0, remainingItems);
        }
        
        for (const color of colorsToShow) {
            const card = createColorCard(color);
            colorsGrid.appendChild(card);
        }
    }
    
    // Add loading indicator if there are more items
    if (currentCategory === 'opus' && totalItems < colorsToRender.length) {
        const loadingDiv = document.createElement('div');
        loadingDiv.className = 'loading-indicator';
        loadingDiv.style.gridColumn = '1 / -1';
        loadingDiv.innerHTML = '<div class="spinner"></div>';
        colorsGrid.appendChild(loadingDiv);
    }
}

// Create a color card element
function createColorCard(color) {
    const card = document.createElement('div');
    card.className = 'color-card';
    card.style.backgroundColor = hexToColor(color.value);
    card.dataset.colorNumber = color.number;
    
    const nameElement = document.createElement('div');
    nameElement.className = 'color-name';
    nameElement.textContent = color.name;
    card.appendChild(nameElement);
    
    // Add click event to show detail modal
    card.addEventListener('click', () => {
        showColorDetail(color);
    });
    
    return card;
}

// Show color detail modal
function showColorDetail(color) {
    // Close favorites modal if it's open
    favoritesModal.style.display = 'none';
    
    modalColorName.textContent = color.name;
    modalPageNumber.textContent = `Page ${color.page || 'N/A'}`;
    modalColorDisplay.style.backgroundColor = hexToColor(color.value);
    modalColorNameDisplay.textContent = color.name;
    modalColorDetails.textContent = `${color.number} - ${color.value}`;
    
    // Set up favorite button
    modalFavoriteButton.dataset.colorNumber = color.number;
    updateFavoriteButton(modalFavoriteButton, color.number);
    
    colorDetailModal.style.display = 'block';
}

// Update favorite button icon based on favorite status
function updateFavoriteButton(button, colorNumber) {
    const iconElement = button.querySelector('.material-icons');
    if (favoriteColorNumbers.has(colorNumber)) {
        iconElement.textContent = 'star';
        iconElement.style.color = '#ffd700';
    } else {
        iconElement.textContent = 'star_border';
        iconElement.style.color = '';
    }
}

// Update card favorite status
function updateCardFavoriteStatus(card, colorNumber) {
    // This could be used to add a favorite indicator to cards if needed
}

// Render favorites
function renderFavorites() {
    favoritesGrid.innerHTML = '';
    
    if (favoriteColorNumbers.size === 0) {
        noFavorites.style.display = 'block';
        return;
    }
    
    noFavorites.style.display = 'none';
    
    // Find all favorite colors from all categories
    const favoriteColors = [];
    for (const category in colors) {
        for (const color of colors[category]) {
            if (favoriteColorNumbers.has(color.number)) {
                favoriteColors.push(color);
            }
        }
    }
    
    // Group by page
    const colorsByPage = {};
    for (const color of favoriteColors) {
        const page = color.page || 1;
        if (!colorsByPage[page]) {
            colorsByPage[page] = [];
        }
        colorsByPage[page].push(color);
    }
    
    // Sort pages
    const sortedPages = Object.keys(colorsByPage).map(Number).sort((a, b) => a - b);
    
    // Render pages
    for (const page of sortedPages) {
        // Add page header
        const pageHeader = document.createElement('h3');
        pageHeader.className = 'page-header';
        pageHeader.textContent = `Page ${page}`;
        pageHeader.style.gridColumn = '1 / -1';
        favoritesGrid.appendChild(pageHeader);
        
        // Add colors for this page
        for (const color of colorsByPage[page]) {
            const card = createColorCard(color);
            favoritesGrid.appendChild(card);
        }
    }
}

// Convert hex color to CSS color
function hexToColor(hexString) {
    if (!hexString) return '#000000';
    
    if (hexString.startsWith('#')) {
        return hexString;
    }
    return `#${hexString}`;
}

// Show loading indicator
function showLoading() {
    isLoading = true;
    loadingIndicator.style.display = 'flex';
    colorsGrid.style.display = 'none';
}

// Hide loading indicator
function hideLoading() {
    isLoading = false;
    loadingIndicator.style.display = 'none';
    colorsGrid.style.display = 'grid';
}

// Add this function to ensure only one modal is open at a time
function closeAllModals() {
    colorDetailModal.style.display = 'none';
    favoritesModal.style.display = 'none';
} 
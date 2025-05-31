document.addEventListener('DOMContentLoaded', () => {
    const craftingContainer = document.getElementById('craftingContainer');
    const closeCraftingButton = document.getElementById('closeCrafting');
    const recipeGrid = document.getElementById('recipeGrid');
    const recipeDetails = document.getElementById('recipeDetails');
    const noRecipeSelected = document.getElementById('noRecipeSelected');
    const detailRecipeImage = document.getElementById('detailRecipeImage');
    const detailRecipeName = document.getElementById('detailRecipeName');
    const detailRecipeDescription = document.getElementById('detailRecipeDescription');
    const detailRecipeIngredients = document.getElementById('detailRecipeIngredients');
    const craftSelectedButton = document.getElementById('craftSelectedButton');

    const quantityInput = document.getElementById('craftQuantity');
    const decreaseQuantityButton = document.getElementById('decreaseQuantity');
    const increaseQuantityButton = document.getElementById('increaseQuantity');

    let allRecipes = {};
    let selectedRecipe = null;
    const DEFAULT_ITEM_IMAGE = "/shared/imgs/unknown.png";

    // Function to show the crafting UI
    const showCraftingUI = () => {
        document.body.classList.add('active');
        craftingContainer.classList.add('show');
    };

    // Function to hide the crafting UI
    const hideCraftingUI = () => {
        craftingContainer.classList.remove('show');
        setTimeout(() => {
            document.body.classList.remove('active');
            recipeDetails.classList.add('hidden');
            noRecipeSelected.classList.remove('hidden');
            selectedRecipe = null;
            recipeGrid.innerHTML = '';
            quantityInput.value = 1;
        }, 300);
        fetchNui('closeUI', {});
    };

    closeCraftingButton.addEventListener('click', hideCraftingUI);

    document.addEventListener('keydown', (event) => {
        if (event.key === 'Escape' && document.body.classList.contains('active')) {
            hideCraftingUI();
        }
    });

    decreaseQuantityButton.addEventListener('click', () => {
        let currentQuantity = parseInt(quantityInput.value);
        if (currentQuantity > 1) {
            quantityInput.value = currentQuantity - 1;
        }
    });

    increaseQuantityButton.addEventListener('click', () => {
        let currentQuantity = parseInt(quantityInput.value);
        if (currentQuantity < 999) {
            quantityInput.value = currentQuantity + 1;
        }
    });

    quantityInput.addEventListener('change', () => {
        let value = parseInt(quantityInput.value);
        if (isNaN(value) || value < 1) {
            quantityInput.value = 1;
        } else if (value > 999) {
            quantityInput.value = 999;
        }
    });

    const fetchNui = async (eventName, data) => {
        try {
            const response = await fetch(`https://vx_crafting/${eventName}`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json; charset=UTF-8' },
                body: JSON.stringify(data),
            });
            return await response.json();
        } catch (error) {
            console.error(`Error sending NUI callback ${eventName}:`, error);
            return null;
        }
    };

    const renderRecipes = (recipesToDisplay, playerKnownRecipes) => {
        recipeGrid.innerHTML = '';
        recipeDetails.classList.add('hidden');
        noRecipeSelected.classList.remove('hidden');
        selectedRecipe = null;

        let filteredRecipes = [];
        for (const recipeId in recipesToDisplay) {
            if (playerKnownRecipes.includes(recipeId)) {
                filteredRecipes.push(recipesToDisplay[recipeId]);
            }
        }

        if (filteredRecipes.length === 0) {
            recipeGrid.innerHTML = '<p class="text-gray-400 text-center col-span-full py-10">You do not have the knowledge to craft anything here.</p>';
            return;
        }

        filteredRecipes.forEach(recipe => {
            const div = document.createElement('div');
            div.className = 'recipe-card bg-gray-600 p-3 rounded-lg shadow-md flex flex-col items-center justify-center text-center cursor-pointer hover:bg-gray-500 transition-colors duration-200 aspect-square';
            div.dataset.recipeId = recipe.id;

            let imageSrc = recipe.image ? `/shared/imgs/${recipe.image}` : DEFAULT_ITEM_IMAGE;

            div.innerHTML = `
                <img src="${imageSrc}" alt="${recipe.output.label}" class="w-24 h-24 object-contain mb-2 rounded-md" onerror="this.onerror=null;this.src='${DEFAULT_ITEM_IMAGE}';">
                <h3 class="text-md font-semibold text-white truncate w-full">${recipe.name}</h3>
                <p class="text-xs text-gray-300">Crafts: ${recipe.output.amount}x ${recipe.output.label}</p>
            `;
            recipeGrid.appendChild(div);

            div.addEventListener('click', () => {
                document.querySelectorAll('.recipe-card').forEach(card => card.classList.remove('border-2', 'border-blue-400'));
                div.classList.add('border-2', 'border-blue-400');
                displayRecipeDetails(recipe.id);
            });
        });
    };

    const displayRecipeDetails = (recipeId) => {
        selectedRecipe = allRecipes[recipeId];
        if (selectedRecipe) {
            let detailImageSrc = selectedRecipe.image ? `/shared/imgs/${selectedRecipe.image}` : DEFAULT_ITEM_IMAGE;

            detailRecipeImage.src = detailImageSrc;
            detailRecipeImage.onerror = function() { this.onerror=null; this.src=DEFAULT_ITEM_IMAGE; };
            detailRecipeName.textContent = selectedRecipe.name;
            detailRecipeDescription.textContent = selectedRecipe.description || 'No description.';
            detailRecipeIngredients.innerHTML = '';
            for (const item of selectedRecipe.ingredients) {
                const li = document.createElement('li');
                li.textContent = `${item.amount}x ${item.label || item.name}`;
                detailRecipeIngredients.appendChild(li);
            }
            recipeDetails.classList.remove('hidden');
            noRecipeSelected.classList.add('hidden');
            quantityInput.value = 1;
        }
    };

    craftSelectedButton.addEventListener('click', () => {
        if (selectedRecipe) {
            const quantity = parseInt(quantityInput.value);
            if (isNaN(quantity) || quantity < 1 || quantity > 999) {
                console.error("Invalid quantity.");
                return;
            }
            craftRecipe(selectedRecipe.id, quantity);
        }
    });

    const craftRecipe = (recipeId, quantity) => {
        console.log(`Attempting to craft recipe: ${recipeId} x${quantity}`);
        hideCraftingUI();
        fetchNui('craftItem', { recipeId: recipeId, quantity: quantity })
            .then(response => {
                if (!response || !response.success) {
                    console.error('Crafting request failed:', response ? response.message : 'Unknown error');
                }
            })
            .catch(error => {
                console.error('Error during NUI craftItem call:', error);
            });
    };

    window.addEventListener('message', (event) => {
        const data = event.data;
        if (data.type === 'openCraftingUI') {
            allRecipes = data.recipes || {};
            renderRecipes(allRecipes, data.knownRecipes || []);
            showCraftingUI();
        } else if (data.type === 'closeCraftingUI') {
            hideCraftingUI();
        }
    });
});

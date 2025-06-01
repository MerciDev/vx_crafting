document.addEventListener('DOMContentLoaded', () => {
    const craftingContainer = document.getElementById('craftingContainer');
    const closeCraftingButton = document.getElementById('closeCrafting');
    const recipeGrid = document.getElementById('recipeGrid');
    const recipeDetails = document.getElementById('recipeDetails');
    const noRecipeSelected = document.getElementById('noRecipeSelected');
    const detailRecipeImage = document.getElementById('detailRecipeImage');
    const detailRecipeName = document.getElementById('detailRecipeName');
    const detailRecipeDescription = document.getElementById('detailRecipeDescription');
    const detailRecipeCraftTime = document.getElementById('detailRecipeCraftTime');
    const detailRecipeIngredients = document.getElementById('detailRecipeIngredients');
    const detailRecipeOutput = document.getElementById('detailRecipeOutput');
    const craftSelectedButton = document.getElementById('craftSelectedButton');
    const quantityInput = document.getElementById('craftQuantity');
    const decreaseQuantityButton = document.getElementById('decreaseQuantity');
    const increaseQuantityButton = document.getElementById('increaseQuantity');
    const craftingStationName = document.getElementById('craftingStationName'); // Nuevo elemento para el nombre de la estación

    // Elementos del tooltip de imagen
    const imageTooltip = document.getElementById('imageTooltip');
    const tooltipImage = document.getElementById('tooltipImage');

    let allRecipes = {};
    let selectedRecipe = null;
    const DEFAULT_ITEM_IMAGE = "/shared/imgs/unknown.png";

    const showCraftingUI = () => {
        document.body.classList.add('active');
        craftingContainer.classList.add('show');
    };

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
        const maxQuantity = selectedRecipe && selectedRecipe.maxAmount ? selectedRecipe.maxAmount : 999;
        if (currentQuantity < maxQuantity) {
            quantityInput.value = currentQuantity + 1;
        }
    });

    quantityInput.addEventListener('change', () => {
        let value = parseInt(quantityInput.value);
        const maxQuantity = selectedRecipe && selectedRecipe.maxAmount ? selectedRecipe.maxAmount : 999;
        if (isNaN(value) || value < 1) {
            quantityInput.value = 1;
        } else if (value > maxQuantity) {
            quantityInput.value = maxQuantity;
        }
    });

    const fetchNui = async (eventName, data = {}) => {
        try {
            const resourceName = window.GetParentResourceName ? window.GetParentResourceName() : 'vx_crafting';
            const response = await fetch(`https://${resourceName}/${eventName}`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json; charset=UTF-8' },
                body: JSON.stringify(data),
            });
            if (!response.ok) {
                let errorData = null;
                try {
                    errorData = await response.json();
                } catch (e) {
                    // No hacer nada
                }
                console.error(`Error en NUI callback ${eventName}: Estado ${response.status}`, errorData);
                return null;
            }
            return await response.json();
        } catch (error) {
            console.error(`Excepción al enviar NUI callback ${eventName}:`, error);
            return null;
        }
    };

    const formatCraftTime = (totalSeconds) => {
        totalSeconds = totalSeconds/1000;
        if (totalSeconds === undefined || totalSeconds === null || totalSeconds <= 0) {
            return "Instantáneo";
        }
        const minutes = Math.floor(totalSeconds / 60);
        const seconds = totalSeconds % 60;
        let timeString = "";
        if (minutes > 0) {
            timeString += `${minutes}m `;
        }
        if (seconds > 0 || minutes === 0) {
            timeString += `${seconds}s`;
        }
        return timeString.trim();
    };

    const renderRecipes = (recipesToDisplay, playerKnownRecipes) => {
        recipeGrid.innerHTML = '';
        recipeDetails.classList.add('hidden');
        noRecipeSelected.classList.remove('hidden');
        selectedRecipe = null;

        let filteredRecipes = [];
        if (recipesToDisplay && typeof recipesToDisplay === 'object') {
             for (const recipeId in recipesToDisplay) {
                if (playerKnownRecipes.includes(recipeId)) {
                    filteredRecipes.push(recipesToDisplay[recipeId]);
                }
            }
        }

        if (filteredRecipes.length === 0) {
            recipeGrid.innerHTML = '<p class="text-magic-secondary text-center col-span-full py-10">No conoces ninguna receta para esta mesa.</p>';
            return;
        }

        filteredRecipes.forEach(recipe => {
            const div = document.createElement('div');
            div.className = 'recipe-card bg-magic-tertiary p-3 rounded-lg shadow-md flex flex-col items-center justify-center text-center cursor-pointer transition-all duration-200 ease-in-out aspect-square';
            div.dataset.recipeId = recipe.id;

            let outputItem = recipe.output && recipe.output.length > 0 ? recipe.output[0] : null;
            let imageSrc = recipe.image ? `nui://ox_inventory/web/images/${recipe.image}.png` : DEFAULT_ITEM_IMAGE;

            div.innerHTML = `
                <img src="${imageSrc}" alt="${outputItem ? (outputItem.label || outputItem.name) : 'Unknown Item'}" class="w-16 h-16 sm:w-20 sm:h-20 object-contain mb-2 rounded-md border border-magic-accent-gold p-0.5" onerror="this.onerror=null;this.src='${DEFAULT_ITEM_IMAGE}';">
                <h3 class="text-sm sm:text-md font-semibold text-magic-primary truncate w-full">${recipe.name}</h3>
                <p class="text-xs text-magic-secondary">Crea: ${outputItem ? `${outputItem.amount || 0}x ${outputItem.label || outputItem.name || 'Unknown Item'}` : 'N/A'}</p>
            `;
            recipeGrid.appendChild(div);

            div.addEventListener('click', () => {
                document.querySelectorAll('.recipe-card').forEach(card => card.classList.remove('selected-recipe-card'));
                div.classList.add('selected-recipe-card');
                displayRecipeDetails(recipe.id);
            });
        });
    };

    const displayRecipeDetails = (recipeId) => {
        selectedRecipe = allRecipes[recipeId];
        if (selectedRecipe) {
            let detailImageSrc = selectedRecipe.image ? `nui://ox_inventory/web/images/${selectedRecipe.image}.png` : DEFAULT_ITEM_IMAGE;
             if (selectedRecipe.image && selectedRecipe.image.startsWith('http')) {
                detailImageSrc = selectedRecipe.image;
            }
            detailRecipeImage.src = detailImageSrc;
            detailRecipeImage.onerror = function() { this.onerror=null; this.src=DEFAULT_ITEM_IMAGE; };

            detailRecipeName.textContent = selectedRecipe.name;
            detailRecipeDescription.textContent = selectedRecipe.description || 'Esta receta no tiene descripción.';
            detailRecipeCraftTime.textContent = formatCraftTime(selectedRecipe.craftingTime);

            // Renderizar ingredientes
            detailRecipeIngredients.innerHTML = '';
            if (selectedRecipe.ingredients && selectedRecipe.ingredients.length > 0) {
                selectedRecipe.ingredients.forEach(item => {
                    const li = document.createElement('li');
                    li.className = 'ingredient-item flex items-center text-magic-secondary';

                    let ingredientImageSrc = item.image ? `nui://ox_inventory/web/images/${item.image}.png` : `nui://ox_inventory/web/images/${item.name}.png`;
                    if (item.image && item.image.startsWith('http')) {
                        ingredientImageSrc = item.image;
                    } else if (item.image && !item.image.includes('://')) {
                         ingredientImageSrc = `/shared/imgs/${item.image}.png`;
                    } else if (!item.image && item.name) {
                        ingredientImageSrc = `nui://ox_inventory/web/images/${item.name}.png`;
                    } else {
                        ingredientImageSrc = DEFAULT_ITEM_IMAGE;
                    }

                    const img = document.createElement('img');
                    img.src = ingredientImageSrc;
                    img.alt = item.label || item.name;
                    img.className = 'ingredient-image w-6 h-6 object-contain mr-2 rounded bg-white/10 border border-white/20';
                    img.onerror = function() { this.onerror=null; this.src=DEFAULT_ITEM_IMAGE; };

                    // Event listeners para el tooltip
                    img.addEventListener('mouseenter', (e) => {
                        tooltipImage.src = img.src;
                        imageTooltip.classList.remove('hidden');
                        imageTooltip.classList.add('show');
                        // Posicionar el tooltip cerca del cursor
                        imageTooltip.style.left = `${e.clientX + 15}px`;
                        imageTooltip.style.top = `${e.clientY + 15}px`;
                    });

                    img.addEventListener('mousemove', (e) => {
                        // Actualizar posición del tooltip mientras se mueve el ratón
                        imageTooltip.style.left = `${e.clientX + 15}px`;
                        imageTooltip.style.top = `${e.clientY + 15}px`;
                    });

                    img.addEventListener('mouseleave', () => {
                        imageTooltip.classList.remove('show');
                        imageTooltip.classList.add('hidden');
                    });


                    const textNode = document.createTextNode(`${item.amount || 0}x ${item.label || item.name || 'Unknown Item'}`);

                    li.appendChild(img);
                    li.appendChild(textNode);
                    detailRecipeIngredients.appendChild(li);
                });
            } else {
                detailRecipeIngredients.innerHTML = '<li class="text-magic-secondary/70">Esta receta no requiere ingredientes.</li>';
            }

            detailRecipeOutput.innerHTML = '';
            if (selectedRecipe.output && selectedRecipe.output.length > 0) {
                selectedRecipe.output.forEach(outputItem => {
                    const li = document.createElement('li');
                    li.className = 'ingredient-item flex items-center text-magic-secondary';

                    let outputImageSrc = outputItem.image ? `nui://ox_inventory/web/images/${outputItem.name}.png` : `nui://ox_inventory/web/images/${outputItem.name}.png`;
                    if (outputItem.image && outputItem.image.startsWith('http')) {
                        outputImageSrc = outputItem.image;
                    } else if (outputItem.image && !outputItem.image.includes('://')) {
                        outputImageSrc = `/shared/imgs/${outputItem.image}.png`;
                    } else if (!outputItem.image && outputItem.name) {
                        outputImageSrc = `nui://ox_inventory/web/images/${outputItem.name}.png`;
                    } else {
                        outputImageSrc = DEFAULT_ITEM_IMAGE;
                    }

                    const img = document.createElement('img');
                    img.src = outputImageSrc;
                    img.alt = outputItem.label || outputItem.name;
                    img.className = 'ingredient-image w-6 h-6 object-contain mr-2 rounded bg-white/10 border border-white/20';
                    img.onerror = function() { this.onerror=null; this.src=DEFAULT_ITEM_IMAGE; };

                    // Event listeners para el tooltip del resultado
                    img.addEventListener('mouseenter', (e) => {
                        tooltipImage.src = img.src;
                        imageTooltip.classList.remove('hidden');
                        imageTooltip.classList.add('show');
                        imageTooltip.style.left = `${e.clientX + 15}px`;
                        imageTooltip.style.top = `${e.clientY + 15}px`;
                    });

                    img.addEventListener('mousemove', (e) => {
                        imageTooltip.style.left = `${e.clientX + 15}px`;
                        imageTooltip.style.top = `${e.clientY + 15}px`;
                    });

                    img.addEventListener('mouseleave', () => {
                        imageTooltip.classList.remove('show');
                        imageTooltip.classList.add('hidden');
                    });

                    const textNode = document.createTextNode(`${outputItem.amount || 0}x ${outputItem.label || outputItem.name || 'Unknown Item'}`);

                    li.appendChild(img);
                    li.appendChild(textNode);
                    detailRecipeOutput.appendChild(li);
                });
            } else {
                detailRecipeOutput.innerHTML = '<li class="text-magic-secondary/70">Esta receta no produce ningún resultado.</li>';
            }


            recipeDetails.classList.remove('hidden');
            noRecipeSelected.classList.add('hidden');
            quantityInput.value = 1;
            quantityInput.max = selectedRecipe.maxAmount || 999;
        }
    };

    craftSelectedButton.addEventListener('click', () => {
        if (selectedRecipe) {
            const quantity = parseInt(quantityInput.value);
            if (isNaN(quantity) || quantity < 1 || quantity > (selectedRecipe.maxAmount || 999) ) {
                console.error("Cantidad inválida.");
                fetchNui('showNotification', { type: 'error', message: 'Cantidad de crafteo inválida.' });
                return;
            }
            craftRecipe(selectedRecipe.id, quantity);
        }
    });

    const craftRecipe = (recipeId, quantity) => {
        fetchNui('craftItem', { recipeId: recipeId, quantity: quantity })
            .then(response => {
                if (response && response.success) {
                    // Éxito: Ocultar la UI después de un crafteo exitoso
                    hideCraftingUI();
                } else {
                    console.error('La solicitud de crafteo falló:', response ? response.message : 'Error desconocido');
                }
            })
            .catch(error => {
                console.error('Error durante la llamada NUI craftItem:', error);
            });
    };

    window.addEventListener('message', (event) => {
        const data = event.data;
        if (!data || !data.type) return;

        switch (data.type) {
            case 'openCraftingUI':
                allRecipes = data.recipes || {};
                // Establecer el nombre de la estación de crafteo
                if (data.craftingStationName) {
                    craftingStationName.textContent = data.craftingStationName;
                } else {
                    craftingStationName.textContent = 'Mesa de Crafteo Arcana'; // Fallback
                }
                renderRecipes(allRecipes, data.knownRecipes || []);
                showCraftingUI();
                break;
            case 'closeCraftingUI':
                hideCraftingUI();
                break;
            case 'updateKnownRecipes':
                if (allRecipes) {
                    renderRecipes(allRecipes, data.knownRecipes || []);
                }
                break;
        }
    });
});

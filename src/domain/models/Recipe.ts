export class Recipe {
    private ingredients: { [ingredientName: string]: number };

    constructor(ingredients: { [ingredientName: string]: number }) {
        this.ingredients = ingredients;
    }

    getIngredients(): { [ingredientName: string]: number } {
        return this.ingredients;
    }    
}
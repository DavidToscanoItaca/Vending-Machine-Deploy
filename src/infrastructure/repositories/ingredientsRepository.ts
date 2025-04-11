import { Ingredient } from "../../domain/models/Ingredient";
import { singleton } from "tsyringe";

@singleton()
export class IngredientsRepository {
    private ingredients: { [ingredientName: string]: Ingredient };

    constructor() {
        this.ingredients = {};
        this.initializeIngredients();
    }

    private initializeIngredients(): void {
        this.addIngredient('water', 100);
        this.addIngredient('sugar', 50);
        this.addIngredient('coffee', 30);
        this.addIngredient('tea', 30);
        this.addIngredient('milk', 20);
        this.addIngredient('iceCream', 10);
    }

    getIngredient(ingredientName: string): Ingredient | undefined {
        return this.ingredients[ingredientName];
    }

    getAllIngredients(): { [ingredientName: string]: Ingredient } {
        return this.ingredients;
    }

    addIngredient(ingredientName: string, quantity: number): void {
        this.ingredients[ingredientName] = new Ingredient(ingredientName, quantity);
    }

    restockIngredient(ingredientName: string, quantity: number): void {
        const ingredient = this.ingredients[ingredientName];
        if (ingredient) {
            ingredient.refill(quantity);
        }
    }
}

